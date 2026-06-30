/**
 * @file        dcan.c
 * @brief       Read and Write data over CAN port
 * @details     SocketCan code is used to read and
 *		write data over CAN port
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @date        2026-06-22
 * @version     1.0.0
 * @copyright   (c) 2026 Lad Dhawal Umesh. All rights reserved.
 * Note: This code is an original implementation by Lad Dhawal Umesh. 
 * Certain algorithms or logic patterns were adapted from publicly 
 * available online resources.
 */

// Include Header
#include "dcan.h"

/**
 * @brief Initilize CAN port
 * @param NA
 * @return 0 on success, -1 on failure.
 * @note This function will Initilize CAN port
 */
int iInitCANPort(void) {
	struct sockaddr_can sSocketCANAddr;
	struct ifreq ifr;

	if((iCANSocket = socket(PF_CAN, SOCK_RAW, CAN_RAW)) < INIT_0) {
		perror("Socket");
		return FAILURE;
	}

	strcpy(ifr.ifr_name, CAN_PORT_NAME);
	ioctl(iCANSocket, SIOCGIFINDEX, &ifr);

	memset(&sSocketCANAddr, INIT_0, sizeof(sSocketCANAddr));
	sSocketCANAddr.can_family = AF_CAN;
	sSocketCANAddr.can_ifindex = ifr.ifr_ifindex;

	if(bind(iCANSocket, (struct sockaddr *)&sSocketCANAddr, sizeof(sSocketCANAddr)) < INIT_0) {
		perror("Bind");
		if(close(iCANSocket) < INIT_0) {
			perror("Close");
			return FAILURE;
		}
		return FAILURE;
	}
    return SUCCESS;
}

void* vpWriteDataThread(void *vpArg) {
	(void)vpArg; // Add this line to silence the warning

	while(INIT_1) {
		sCANFrameVar.can_id = CAN_ID;
		sCANFrameVar.can_dlc = SAMPLE_CAN_DATA_LEN;
		//sprintf(sCANFrameVar.data, "%s", SAMPLE_CAN_DATA);
		sprintf((char *)sCANFrameVar.data, SAMPLE_CAN_DATA);

		if(write(iCANSocket, &sCANFrameVar, sizeof(struct can_frame)) != sizeof(struct can_frame)) {
			perror("Write");
			if(close(iCANSocket) < INIT_0) {
				perror("Close");
			}
			break;
		}
		sleep(SLEEP_TIME);
	}
	return NULL;
}

void* vpReadDataThread(void *vpArg) {
	(void)vpArg; // Add this line to silence the warning

	uint8_t u8i = INIT_0;
	int iBytesNum = INIT_0; 
	while(INIT_1) {
		iBytesNum = read(iCANSocket, &sCANFrameVar, sizeof(struct can_frame));

	 	if(iBytesNum < INIT_0) {
			perror("Read");
			if(close(iCANSocket) < INIT_0) {
				perror("Close");
			}
			break;
		}

		printf("0x%03X [%d] ",sCANFrameVar.can_id, sCANFrameVar.can_dlc);

		for(u8i = 0; u8i < sCANFrameVar.can_dlc; u8i++)
			printf("%02X ",sCANFrameVar.data[u8i]);

		printf("\r\n");
	}
	return NULL;
}


int main() {
	
	pthread_t tCANWrite = INIT_0, tCANRead = INIT_0; // Variable to hold the unique thread ID
	int iWriteThreadStatus = INIT_0, iReadThreadStatus = INIT_0;

	if(iInitCANPort() == FAILURE) {
		printf("Unable to Initilize CAN port\n");
		return FAILURE;
	}

	iWriteThreadStatus = pthread_create(&tCANWrite, NULL, vpWriteDataThread, NULL);
	if(iWriteThreadStatus != INIT_0) {
		perror("Failed to create CAN Write Thread");
		return FAILURE;
	}

	iReadThreadStatus = pthread_create(&tCANRead, NULL, vpReadDataThread, NULL);
	if(iReadThreadStatus != INIT_0) {
		perror("Failed to create CAN Read Thread");
		return FAILURE;
	}

	pthread_join(tCANWrite, NULL);
	pthread_join(tCANRead, NULL);

	return SUCCESS;
}
