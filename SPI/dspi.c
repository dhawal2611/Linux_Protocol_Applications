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
  uint8_t u8Bits = SPI_BITS_PER_WORD;
  uint32_t u32Speed = SPI_SPEED_HZ; // 1 MHz

  if ((iSPIFd = open(SPI_DEVICE, O_RDWR)) < INIT_0) {
        perror("Failed to open the SPI bus");
        return FAILURE;
   }
  
   if (ioctl(iSPIFd, SPI_IOC_WR_MODE, &u8Mode) < INIT_0) {
        perror("Failed to configure to the slave device");
        close(iSPIFd);
        return FAILURE;
   }

   // If need to 
   if (ioctl(iSPIFd, SPI_IOC_WR_BITS_PER_WORD, &u8Bits) < INIT_0) {
        perror("Failed to configure to the slave device");
        close(iSPIFd);
        return FAILURE;
   }

   if (ioctl(iSPIFd, SPI_IOC_WR_MAX_SPEED_HZ, &u32Speed) < INIT_0) {
        perror("Failed to configure to the slave device");
        close(iSPIFd);
        return FAILURE;
   }

    return SUCCESS;  
}

// Performs a full-duplex SPI transfer (simultaneous read and write)
// Helper function to execute an SPI transfer
int iSPITransfer(uint8_t *u8pTx, uint8_t *u8pRx, size_t sLen) {
    struct spi_ioc_transfer tr = {
        .tx_buf = (unsigned long)u8pTx,
        .rx_buf = (unsigned long)u8pRx,
        .len = sLen,
        .speed_hz = SPI_SPEED_HZ,
        .bits_per_word = SPI_BITS_PER_WORD,
        .delay_usecs = INIT_0,
        .cs_change = INIT_0, // Keep CS low throughout this exact buffer len
    };

    if (ioctl(iSPIFd, SPI_IOC_MESSAGE(INIT_1), &tr) < INIT_0) {
        perror("Error: SPI transfer failed");
        return FAILURE;
    }
    return SUCCESS;
}

void vCloseSPIDevice(void) {
    // Clean up file descriptor
    close(iSPIFd);
}


