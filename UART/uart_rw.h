/**
 * @file        uart_rw.h
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @brief       UART communication in linux.
 * @copyright   (c) 2026 Lad Dhawal Umesh. All rights reserved.
 */

#ifndef UART_RW_H
#define UART_RW_H

// Headers
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <unistd.h>
#include <stdint.h>

// MACROS
#define BUFFER_SIZE 1024

#define SUCCESS 0
#define FAILURE -1

#define INIT_0 0
#define INIT_1 1
#define INIT_M_1 -1

// tty port on which communication gets occured
#define TTY_PORT_NAME "/dev/ttyUSB0"// Check your device UART name and define the same
				    // eg. /dev/ttyUSB0, /dev/ttyS0, or /dev/ttyAMA0, etc

// Baud rate supported by UART
// If need any more define here
#define BAUD_4800 B4800
#define BAUD_9600 B9600
#define BAUD_19200 B19200
#define BAUD_38400 B38400
#define BAUD_57600 B57600
#define BAUD_115200 B115200

#define NULL_BYTE '\0'
#define READ_BUFFER 256

// Global Variables
int iSerialPort = INIT_0;

// Function Declarations
int8_t i8UARTInit();
int8_t i8UARTReadWrite();

#endif // UART_RW_H
