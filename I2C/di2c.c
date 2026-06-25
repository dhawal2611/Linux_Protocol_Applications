/**
 * @file        di2c.c
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
#include "di2c.h"

/**
 * @brief Export Provided GPIO
 * @param u32Pin pin number
 * @return 0 on success, -1 on failure.
 * @note This function will export the GPIO
 */
int iInitI2CDevice(void) {

  if ((iI2CFd = open(I2C_BUS, O_RDWR)) < INIT_0) {
        perror("Failed to open the I2C bus");
        return FAILURE;
   }
   
   if (ioctl(iI2CFd, I2C_SLAVE, SLAVE_ADDR) < INIT_0) {
        perror("Failed to connect to the slave device");
        close(iI2CFd);
        return FAILURE;
    }
    return SUCCESS;  
}

int iReadI2CData(uint8_t *u8ReadDataBuf, unsigned int uReadSize) {
    if (read(iI2CFd, u8ReadDataBuf, uReadSize) != uReadSize) {
        perror("Failed to read data from sensor");
        close(iI2CFd);
        return FAILURE;
    }
    return SUCCESS;
}


int iWriteI2CData(uint8_t *u8WriteDataBuf, unsigned int uReadSize) {
    if (write(iI2CFd, u8WriteDataBuf, uReadSize) != uReadSize) {
        perror("Failed to read data from sensor");
        close(iI2CFd);
        return FAILURE;
    }
    return SUCCESS;
}

void vCloseI2CDevice(void) {
    // Clean up file descriptor
    close(iI2CFd);
}
