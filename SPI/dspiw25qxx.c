/**
 * @file        di2cAHT20.c
 * @brief       I2C applicaiton code
 * @details     Read and Write data over I2C device
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @date        2026-06-24
 * @version     1.0.0
 * @copyright   (c) 2026 Lad Dhawal Umesh. All rights reserved.
 * Note: This code is an original implementation by Lad Dhawal Umesh. 
 * Certain algorithms or logic patterns were adapted from publicly 
 * available online resources.
 */
// Include Header
#include "dspiw25qxx.h"

// 1. Read JEDEC ID (Verifies connection)
uint32_t w25q_read_id(int fd) {
    uint8_t tx[4] = {CMD_JEDEC_ID, 0, 0, 0};
    uint8_t rx[4] = {0};

    if (spi_transfer(fd, tx, rx, 4) < 0) return 0;
    return (rx[1] << 16) | (rx[2] << 8) | rx[3];
}

// 2. Send Write Enable Command
int w25q_write_enable(int fd) {
    uint8_t tx = CMD_WRITE_ENABLE;
    return spi_transfer(fd, &tx, NULL, 1);
}

// 3. Wait for Busy Bit (BUSY = Bit 0 of Status Register 1) to clear
void w25q_wait_busy(int fd) {
    uint8_t tx[2] = {CMD_READ_STATUS_1, 0xFF};
    uint8_t rx[2] = {0};
    
    do {
        spi_transfer(fd, tx, rx, 2);
        usleep(1000); // 1ms sleep
    } while (rx[1] & 0x01); 
}

// 4. Erase a 4KB Sector (Required before writing new data)
int w25q_erase_sector(int fd, uint32_t address) {
    uint8_t tx[4] = {
        CMD_SECTOR_ERASE,
        (uint8_t)((address >> 16) & 0xFF),
        (uint8_t)((address >> 8) & 0xFF),
        (uint8_t)(address & 0xFF)
    };

    w25q_write_enable(fd);
    if (spi_transfer(fd, tx, NULL, 4) < 0) return -1;
    
    w25q_wait_busy(fd);
    return 0;
}

// 5. Program a Page (Up to 256 bytes inside a singular page)
int w25q_write_page(int fd, uint32_t address, uint8_t *data, size_t len) {
    if (len > 256) len = 256; 

    size_t tx_len = 4 + len;
    uint8_t *tx = malloc(tx_len);
    if (!tx) return -1;

    tx[0] = CMD_PAGE_PROGRAM;
    tx[1] = (uint8_t)((address >> 16) & 0xFF);
    tx[2] = (uint8_t)((address >> 8) & 0xFF);
    tx[3] = (uint8_t)(address & 0xFF);
    memcpy(&tx[4], data, len);

    w25q_write_enable(fd);
    int ret = spi_transfer(fd, tx, NULL, tx_len);
    free(tx);

    w25q_wait_busy(fd);
    return ret;
}

// 6. Read Data (Sequential read of any length)
int w25q_read_data(int fd, uint32_t address, uint8_t *rx_buf, size_t len) {
    size_t tx_len = 4 + len;
    uint8_t *tx = calloc(tx_len, 1);
    uint8_t *rx = malloc(tx_len);
    if (!tx || !rx) {
        free(tx); free(rx);
        return -1;
    }

    tx[0] = CMD_READ_DATA;
    tx[1] = (uint8_t)((address >> 16) & 0xFF);
    tx[2] = (uint8_t)((address >> 8) & 0xFF);
    tx[3] = (uint8_t)(address & 0xFF);

    int ret = spi_transfer(fd, tx, rx, tx_len);
    if (ret == 0) {
        memcpy(rx_buf, &rx[4], len); // Skip command/address overhead
    }

    free(tx);
    free(rx);
    return ret;
}



int main() {
    int fd = open(SPI_DEVICE, O_RDWR);
    if (fd < 0) {
        perror("Error: Cannot open SPI device node");
        return EXIT_FAILURE;
    }

    // Set SPI Mode 0 (CPOL=0, CPHA=0) as expected by W25Qxx
    uint8_t mode = SPI_MODE_0;
    ioctl(fd, SPI_IOC_WR_MODE, &mode);

    // Verify chip connectivity
    uint32_t id = w25q_read_id(fd);
    printf("JEDEC Chip ID: 0x%06X\n", id);
    if (id == 0 || id == 0xFFFFFF) {
        printf("Error: Communication failure. Check wiring.\n");
        close(fd);
        return EXIT_FAILURE;
    }

    // Target Address (Sector 0, Page 0)
    uint32_t target_addr = 0x000000;
    uint8_t write_data[] = "Hello Embedded Linux SPI Flash!";
    uint8_t read_buffer[sizeof(write_data)] = {0};

    // Perform operations
    printf("Erasing sector at 0x%06X...\n", target_addr);
    w25q_erase_sector(fd, target_addr);

    printf("Writing data: \"%s\"\n", write_data);
    w25q_write_page(fd, target_addr, write_data, sizeof(write_data));

    printf("Reading data back...\n");
    w25q_read_data(fd, target_addr, read_buffer, sizeof(read_buffer));
    printf("Data Read: \"%s\"\n", read_buffer);

    vCloseSPIDevice();
    return SUCCESS;
}


