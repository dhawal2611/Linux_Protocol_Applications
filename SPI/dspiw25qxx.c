/**
 * @file        dspiw25qxx.c
 * @brief       SPI W25QXX applicaiton code
 * @details     Read and Write data over SPI device
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
uint32_t u32w25qReadId() {
    uint8_t u8TxBuffer[TX_RX_DATA_LEN] = {CMD_JEDEC_ID, INIT_0, INIT_0, INIT_0};
    uint8_t u8RxBuffer[TX_RX_DATA_LEN] = {INIT_0};

    if (iSPITransfer(u8TxBuffer, u8RxBuffer, sizeof(u8TxBuffer)) < INIT_0) return INIT_0;
    return (u8RxBuffer[DATA_INDEX_1] << SHIFT_16_BITS) | (u8RxBuffer[DATA_INDEX_2] << SHIFT_8_BITS) | u8RxBuffer[DATA_INDEX_3];
}

// 2. Send Write Enable Command
int iw25qWriteEnable() {
    uint8_t u8TxBuffer = CMD_WRITE_ENABLE;
    return iSPITransfer(&u8TxBuffer, NULL, INIT_1);
}

// 3. Wait for Busy Bit (BUSY = Bit 0 of Status Register 1) to clear
void vw25qWaitBusy() {
    uint8_t u8TxBuffer[BUZY_TX_RX_DATA_LEN] = {CMD_READ_STATUS_1, MASK_8_BITS};
    uint8_t u8RxBuffer[BUZY_TX_RX_DATA_LEN] = {INIT_0};
    
    do {
        iSPITransfer(u8TxBuffer, u8RxBuffer, BUZY_TX_RX_DATA_LEN);
        usleep(1000); // 1ms sleep
    } while (u8RxBuffer[DATA_INDEX_1] & 0x01); 
}

// 4. Erase a 4KB Sector (Required before writing new data)
int iw25qEraseSector(uint32_t u32Address) {
    uint8_t u8TxBuffer[TX_RX_DATA_LEN] = {
        CMD_SECTOR_ERASE,
        (uint8_t)((u32Address >> SHIFT_16_BITS) & MASK_8_BITS),
        (uint8_t)((u32Address >> SHIFT_8_BITS) & MASK_8_BITS),
        (uint8_t)(u32Address & MASK_8_BITS)
    };

    iw25qWriteEnable();
    if (iSPITransfer(u8TxBuffer, NULL, TX_RX_DATA_LEN) < INIT_0) {
      return FAILURE;
    }
    
    vw25qWaitBusy();
    return SUCCESS;
}

// 5. Program a Page (Up to 256 bytes inside a singular page)
int iw25qWritePage(uint32_t u32Address, uint8_t *u8Data, size_t sLen) {
    if (sLen > MAX_PAGE_SIZE) {
      sLen = MAX_PAGE_SIZE;
    }

    size_t sTxLen = TX_RX_DATA_LEN + sLen;
    uint8_t *u8TxBuffer = malloc(sTxLen);
    if (!u8TxBuffer) {
      return FAILURE;
    }

    u8TxBuffer[DATA_INDEX_0] = CMD_PAGE_PROGRAM;
    u8TxBuffer[DATA_INDEX_1] = (uint8_t)((u32Address >> SHIFT_16_BITS) & MASK_8_BITS);
    u8TxBuffer[DATA_INDEX_2] = (uint8_t)((u32Address >> SHIFT_8_BITS) & MASK_8_BITS);
    u8TxBuffer[DATA_INDEX_3] = (uint8_t)(u32Address & MASK_8_BITS);
    memcpy(&u8TxBuffer[DATA_INDEX_4], u8Data, sLen);

    iw25qWriteEnable();
    int ret = iSPITransfer(u8TxBuffer, NULL, sTxLen);
    free(u8TxBuffer);

    vw25qWaitBusy();
    return ret;
}

// 6. Read Data (Sequential read of any length)
int iw25qReadData(uint32_t u32Address, uint8_t *u8RxBuff, size_t sLen) {
    size_t sTxLen = TX_RX_DATA_LEN + sLen;
    uint8_t *u8TxBuffer = calloc(sTxLen, INIT_1);
    uint8_t *u8RxBuffer = malloc(sTxLen);
    if (!u8TxBuffer || !u8RxBuffer) {
        free(u8TxBuffer);
        free(u8RxBuffer);
        return FAILURE;
    }

    u8TxBuffer[DATA_INDEX_0] = CMD_READ_DATA;
    u8TxBuffer[DATA_INDEX_1] = (uint8_t)((u32Address >> SHIFT_16_BITS) & MASK_8_BITS);
    u8TxBuffer[DATA_INDEX_2] = (uint8_t)((u32Address >> SHIFT_8_BITS) & MASK_8_BITS);
    u8TxBuffer[DATA_INDEX_3] = (uint8_t)(u32Address & MASK_8_BITS);

    int ret = iSPITransfer(u8TxBuffer, u8RxBuffer, sTxLen);
    if (ret == INIT_0) {
        memcpy(u8RxBuff, &u8RxBuffer[DATA_INDEX_4], sLen); // Skip command/address overhead
    }

    free(u8TxBuffer);
    free(u8RxBuffer);
    return ret;
}

int main() {
    
    if(iInitSPIDevice() == FAILURE) {
      printf("Unable to initialize SPI\n");
      goto SPI_EXIT_FAIL;
    }

    // Verify chip connectivity
    uint32_t id = u32w25qReadId();
    printf("JEDEC Chip ID: 0x%06X\n", id);
    if (id == INIT_0 || id == 0xFFFFFF) {
        printf("Error: Communication failure. Check wiring.\n");
        goto SPI_EXIT_FAIL;
    }

    // Target Address (Sector 0, Page 0)
    uint32_t target_addr = 0x000000;
    uint8_t write_data[] = "Hello Embedded Linux SPI Flash!";
    uint8_t read_buffer[sizeof(write_data)] = {INIT_0};

    // Perform operations
    printf("Erasing sector at 0x%06X...\n", target_addr);
    iw25qEraseSector(target_addr);

    printf("Writing data: \"%s\"\n", write_data);
    iw25qWritePage(target_addr, write_data, sizeof(write_data));

    printf("Reading data back...\n");
    iw25qReadData(target_addr, read_buffer, sizeof(read_buffer));
    printf("Data Read: \"%s\"\n", read_buffer);

SPI_EXIT_FAIL:
    vCloseSPIDevice();
    return SUCCESS;
}


