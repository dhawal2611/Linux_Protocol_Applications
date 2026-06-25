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
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>

// MACROS
#define SUCCESS 0
#define FAILURE -1

#define INIT_0 0
#define INIT_1 1
#define INIT_M_1 -1

#define I2C_BUS "/dev/i2c-1"      // Default Raspberry Pi I2C bus
#define SLAVE_ADDR  0x38


// Global Variables
static int iI2CFd = INIT_0;

// Function Declarations


#endif // DI2C_H
