/**
 * @file        dgpio.h
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @brief       GPIO pin Set and Clear
 * @copyright   (c) 2026 Lad Dhawal Umesh. All rights reserved.
 */

#ifndef DGPIO_H
#define DGPIO_H

// Headers
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdint.h>

// MACROS
#define SUCCESS 0
#define FAILURE -1

#define INIT_0 0
#define INIT_1 1
#define INIT_M_1 -1

#define GPIO_PATH "/sys/class/gpio/"
#define GPIO_EXPORT_PATH "export"
#define GPIO_UNEXPORT_PATH "unexport"

#define BUFFER_SIZE 256

#define GPIO_VALUE_1 "1"
#define GPIO_CHECK_1 '1'
#define GPIO_VALUE_0 "0"
#define GPIO_RVALUE_1 1
#define GPIO_RVALUE_0 0

#define GPIO_DIR_OUT "out"
#define GPIO_DIR_IN "in"

#define SET_GPIO 1
#define CLR_GPIO 0

#define GPIO_NUM 1 // Replace the GPIO Number to set/clear or read

// Global Variables

// Function Declarations
int iGpioExport(uint32_t u32Pin);
int iGpioUnexport(uint32_t u32Pin);
int iGpioSetDirection(uint32_t u32Pin, const char *cpDirection);
int iGpioWriteValue(uint32_t u32Pin, uint8_t u8Value);
int iGpioReadValue(uint32_t u32Pin);
int iSetGPIO(uint32_t u32Pin);
int iClearGPIO(uint32_t u32Pin);
int iGetGPIO(uint32_t u32Pin);

#endif // DGPIO_H
