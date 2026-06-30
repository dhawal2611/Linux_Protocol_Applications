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

    if(bind(iCANSocket,
             (struct sockaddr *)&sSocketCANAddr,
             sizeof(sSocketCANAddr)) < INIT_0) {
        perror("Bind");
	if(close(iCANSocket) < INIT_0) {
	     perror("Close");
	}
        return FAILURE;
    }

    return SUCCESS;
}

/**
 * @brief Write CAN data
 * @return SUCCESS on success, FAILURE on failure
 */
int iWriteCANData(void) {
    sCANFrameVar.can_id = CAN_ID;
    sCANFrameVar.can_dlc = SAMPLE_CAN_DATA_LEN; // Max data len 8 bytes of u8 datatype

    //sprintf((char *)sCANFrameVar.data, SAMPLE_CAN_DATA); // Max u8 data bytes can be transferred
    // Another way to fill data. Based on data len fill the data accordingly and send it.
    sCANFrameVar.data[0] = 'H';
    sCANFrameVar.data[1] = 'e';
    sCANFrameVar.data[2] = 'l';
    sCANFrameVar.data[3] = 'l';
    sCANFrameVar.data[4] = 'o';
    //sCANFrameVar.data[5] = '\0';
    //sCANFrameVar.data[6] = '\0';
    //sCANFrameVar.data[7] = '\0';

    if (write(iCANSocket, &sCANFrameVar, 
	sizeof(struct can_frame)) != sizeof(struct can_frame)) {
        perror("Write");
        return FAILURE;
    }

    return SUCCESS;
}

/**
 * @brief Read CAN data
 * @return SUCCESS on success, FAILURE on failure
 */
int iReadCANData(void) {
    uint8_t u8i = INIT_0;
    int iBytesNum = INIT_0;

    iBytesNum = read(iCANSocket,
                     &sCANFrameVar,
                     sizeof(struct can_frame));

    if(iBytesNum < INIT_0) {
        perror("Read");
        return FAILURE;
    }

    printf("0x%03X [%d] ", sCANFrameVar.can_id, sCANFrameVar.can_dlc);

    for(u8i = INIT_0; u8i < sCANFrameVar.can_dlc; u8i++) {
        printf("%02X ", sCANFrameVar.data[u8i]);
    }

    printf("\n");

    return SUCCESS;
}


int main(void) {
    if(iInitCANPort() == FAILURE) {
        printf("Unable to Initialize CAN port\n");
        return FAILURE;
    }


    if(iWriteCANData() == FAILURE) {
        printf("Unable to write the data to CAN port\n");
    }

    if(iReadCANData() == FAILURE) {
        printf("Unable to read the data over CAN port\n");
    }

    if(close(iCANSocket) < INIT_0) {
        perror("Close");
    }


    return SUCCESS;
}
