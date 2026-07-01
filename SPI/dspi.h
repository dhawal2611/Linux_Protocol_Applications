/**
 * @file        di2c.h
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @brief       Debug I2C test code
 * @copyright   (c) 2026 Lad Dhawal Umesh. All rights reserved.
 */

#ifndef DSPI_H
#define DSPI_H

// Headers
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/spi/spidev.h>

// MACROS
#define SUCCESS 0
#define FAILURE -1

#define INIT_0 0
#define INIT_1 1
#define INIT_M_1 -1

#define SPI_DEVICE        "/dev/spidev0.0" // Change to your actual SPI bus/CS
#define SPI_SPEED_HZ      10000000         // 10 MHz
#define SPI_BITS_PER_WORD 8


// Global Variables
struct spi_ioc_transfer tr;
int iSPIFd;

uint8_t u8Mode = SPI_MODE_0; // SPI_MODE_X X=0, 1, 2, 3 modes check datasheet
			     // SPI Mode 0 (CPOL=0, CPHA=0)



// Function Declarations


#endif // DSPI_H
