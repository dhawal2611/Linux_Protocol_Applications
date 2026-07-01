/**
 * @file        di2cAHT20.h
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @brief       Read temperature and Humidity from AHT20 sensor
 * @copyright   (c) 2026 Lad Dhawal Umesh. All rights reserved.
 */

#ifndef DI2CAHT20_H
#define DI2CAHT20_H

// Headers
#include "dspi.h"

// MACROS


// W25Qxx Standard Instruction Opcodes
#define CMD_WRITE_ENABLE  0x06
#define CMD_READ_STATUS_1 0x05
#define CMD_SECTOR_ERASE  0x20
#define CMD_PAGE_PROGRAM  0x02
#define CMD_READ_DATA     0x03
#define CMD_JEDEC_ID      0x9F

// Global Variables
uint8_t u8TxBuffer[3] = {0x80, 0x00, 0x00}; 
uint8_t u8RxBuffer[3] = {0,};


// Function Declarations


#endif // DI2CAHT20_H
