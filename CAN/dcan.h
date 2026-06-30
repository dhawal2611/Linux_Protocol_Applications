/**
 * @file        dcan.h
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @brief       CAN Communication
 * @copyright   (c) 2026 Lad Dhawal Umesh. All rights reserved.
 */

#ifndef DCAN_H
#define DCAN_H

// Headers
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/raw.h>
//#include <pthread.h> // Required header for POSIX threads

// MACROS
#define SUCCESS 0
#define FAILURE -1

#define INIT_0 0
#define INIT_1 1
#define INIT_M_1 -1

#define BUFFER_SIZE 256

#define CAN_PORT_NAME	"can0"	// Check your device ifconfig for CAN port name
				// It can vary. eg. vcan0, can0, etc
#define CAN_ID	0x12
#define SAMPLE_CAN_DATA_LEN 5
#define SAMPLE_CAN_DATA "Hello"

#define CAN_FD_ID 0x123
#define CAN_FD_DATA_LEN 64

#define SLEEP_TIME 5

#define CAN_FD_FLAG 0 // 1 - Enable CANFD data communication
		      // 0 - Disable CANFD data communication

// Global Variables
#ifdef CAN_FD_FLAG
	struct canfd_frame sCANFrameVar;
#elif
	struct can_frame sCANFrameVar;
#endif

int iCANSocket; // Socket CAN variable to get connect to CAN port.

// Function Declarations
int iInitCANPort(void);
int iWriteCANData(void);
int iReadCANData(void);

#endif // DCAN_H
