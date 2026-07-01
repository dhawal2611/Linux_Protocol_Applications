/**
 * @file        dspi.c
 * @brief       SPI applicaiton code
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
#include "dspi.h"

/**
 * @brief Export Provided GPIO
 * @param u32Pin pin number
 * @return 0 on success, -1 on failure.
 * @note This function will export the GPIO
 */
int iInitSPIDevice(void) {
  if ((iSPIFd = open(SPI_DEVICE, O_RDWR)) < INIT_0) {
        perror("Failed to open the SPI bus");
        return FAILURE;
   }
  
   if (ioctl(iSPIFd, SPI_IOC_WR_MODE, &mode) < INIT_0) {
        perror("Failed to configure to the slave device");
        close(iSPIFd);
        return FAILURE;
   }
   if (ioctl(iSPIFd, SPI_IOC_WR_BITS_PER_WORD, &bits) < INIT_0) {
        perror("Failed to configure to the slave device");
        close(iSPIFd);
        return FAILURE;
   }
   if (ioctl(iSPIFd, SPI_IOC_WR_MAX_SPEED_HZ, &speed) < INIT_0) {
        perror("Failed to configure to the slave device");
        close(iSPIFd);
        return FAILURE;
   }
   
       tr.tx_buf = (unsigned long)u8TxBuffer;
       tr.rx_buf = (unsigned long)u8RxBuffer;
       tr.len = 3;
       tr.delay_usecs = 0;
       tr.speed_hz = SPI_SPEED;
       tr.bits_per_word = bits;
   if (ioctl(iSPIFd, SPI_IOC_MESSAGE(1), &tr) < 0) {
        perror("Error: SPI transfer failed");
        return -1;
    }
    return SUCCESS;  
}

// Performs a full-duplex SPI transfer (simultaneous read and write)
/*int iSPITransfer(int iFd, uint8_t *tx_buf, uint8_t *rx_buf, size_t length) {
    struct spi_ioc_transfer tr1 = {
        .tx_buf = (unsigned long)tx_buf,
        .rx_buf = (unsigned long)rx_buf,
        .len = length,
        .delay_usecs = 0,
        .speed_hz = 1000000,     // 1 MHz clock speed
        .bits_per_word = 8,      // Standard 8-bit architecture
    };

    // SPI_IOC_MESSAGE(1) tells ioctl to execute 1 transfer struct
    if (ioctl(iFd, SPI_IOC_MESSAGE(1), &tr1) < 0) {
        perror("Error: SPI transfer failed");
        return -1;
    }
    return 0;
}*/

void vCloseSPIDevice(void) {
    // Clean up file descriptor
    //close(iSPIFd);
}

int main() {
  

    // 4. Set up the transfer structure
    /*tr = {
        .tx_buf = (unsigned long)u8TxBuffer,
        .rx_buf = (unsigned long)u8RxBuffer,
        .len = 3,
        .delay_usecs = 0,
        .speed_hz = speed,
        .bits_per_word = bits,
    };*/

    // 5. Execute the Full-Duplex Read/Write
    if (ioctl(iSPIFd, SPI_IOC_MESSAGE(1), &tr) < 0) {
        perror("Error: SPI transfer failed");
        close(iSPIFd);
        return EXIT_FAILURE;
    }

    // 6. Process your read data
    printf("Data received from SPI:\n");
    for (int i = 0; i < 3; i++) {
        printf("Byte [%d]: 0x%02X\n", i, u8RxBuffer[i]);
    }

    close(iSPIFd);
    return EXIT_SUCCESS;
}

