/**
 * @file        dspiw25qxx.h
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @brief       Read temperature and Humidity from AHT20 sensor
 * @copyright   (c) 2026 Lad Dhawal Umesh. All rights reserved.
 */

#ifndef DSPIW25QXX_H
#define DSPIW25QXX_H

// Headers
#include "dspi.h"

// MACROS
// W25Qxx Standard Instruction Opcodes
#define CMD_WRITE_ENABLE 0x06
#define CMD_READ_STATUS_1 0x05
#define CMD_SECTOR_ERASE 0x20
#define CMD_PAGE_PROGRAM 0x02
#define CMD_READ_DATA 0x03
#define CMD_JEDEC_ID 0x9F

#define DATA_INDEX_0 0
#define DATA_INDEX_1 1
#define DATA_INDEX_2 2
#define DATA_INDEX_3 3
#define DATA_INDEX_4 4
#define DATA_INDEX_5 5
#define DATA_INDEX_6 6
#define DATA_INDEX_7 7

#define SHIFT_8_BITS 8
#define SHIFT_16_BITS 16

#define MASK_8_BITS 0xFF

#define TX_RX_DATA_LEN 4
#define BUZY_TX_RX_DATA_LEN 2
#define MAX_PAGE_SIZE 256

// Global Variables
uint8_t u8TxBuffer[3] = {0x80, 0x00, 0x00}; 
uint8_t u8RxBuffer[3] = {0,};

// Function Declarations
uint32_t u32w25qReadId();
int iw25qWriteEnable();
void vw25qWaitBusy();
int iw25qEraseSector(uint32_t address);
int iw25qWritePage(uint32_t address, uint8_t *data, size_t len);
int iw25qReadData(uint32_t address, uint8_t *rx_buf, size_t len);

#endif // DSPIW25QXX_H
