/**
 * @file        di2c.h
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @brief       Debug I2C test code
 * @copyright   (c) 2026 Lad Dhawal Umesh. All rights reserved.
 */

#ifndef DI2C_H
#define DI2C_H

// Headers
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
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

#define SPI_DEVICE "/dev/spidev0.0"     // Default Raspberry Pi SPI bus
#define SPI_SPEED 1000000 // 1MHz
#define SPI_BITS 8


// Global Variables
uint8_t mode = SPI_MODE_0; // SPI_MODE_X X=1, 2, 3, 4 modes check datasheet
uint8_t bits = SPI_BITS;
uint32_t speed = SPI_SPEED; // 1 MHz
struct spi_ioc_transfer tr;


// Function Declarations


#endif // DI2C_H
