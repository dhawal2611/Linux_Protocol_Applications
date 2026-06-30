/**
 * @file        dcan.c
 * @brief       Read and Write data over CAN or CAN_FD port
 * @details     SocketCan code is used to read and write
 *		data over CAN or CAN_FD (extended CAN) port
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @date        2026-06-30
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
    struct ifreq sIFR;
    int iEnableCANFD = INIT_1;

    if((iCANSocket = socket(PF_CAN, SOCK_RAW, CAN_RAW)) < INIT_0) {
        perror("Socket");
        return FAILURE;
    }

    strcpy(sIFR.ifr_name, CAN_PORT_NAME);

    if (ioctl(iCANSocket, SIOCGIFINDEX, &sIFR) < INIT_0) {
        perror("ioctl");
        return FAILURE;
    }
#ifdef CAN_FD_FLAG
    if (setsockopt(iCANSocket,
                   SOL_CAN_RAW,
                   CAN_RAW_FD_FRAMES,
                   &iEnableCANFD,
                   sizeof(iEnableCANFD)) < INIT_0) {
        perror("setsockopt");
        return FAILURE;
    }
#endif
    memset(&sSocketCANAddr, INIT_0, sizeof(sSocketCANAddr));
    sSocketCANAddr.can_family = AF_CAN;
    sSocketCANAddr.can_ifindex = sIFR.ifr_ifindex;

    if(bind(iCANSocket,
             (struct sockaddr *)&sSocketCANAddr,
             sizeof(sSocketCANAddr)) < INIT_0) {
        perror("Bind");
        return FAILURE;
    }

    return SUCCESS;
}

/**
 * @brief Write Data to CAN port
 * @param NA
 * @return 0 on success, -1 on failure.
 * @note Writes data to CAN port
 */
int iWriteCANData(void) {
    uint8_t u8Index = INIT_0;

    memset(&sCANFrameVar, INIT_0, sizeof(struct canfd_frame));

#ifdef CAN_FD_FLAG

    // Sending a 29-bit Extended ID in CAN FD
    sCANFrameVar.can_id = CAN_ID  | CAN_EFF_FLAG; // Packs the extended format flag
    sCANFrameVar.len = CAN_FD_DATA_LEN;
    sCANFrameVar.flags = CANFD_BRS;

    for (u8Index = INIT_0; u8Index < CAN_FD_DATA_LEN; u8Index++) {
        sCANFrameVar.data[u8Index] = u8Index;
    }

#else

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

#endif

    if(write(iCANSocket, &sCANFrameVar,
#ifdef CAN_FD_FLAG
	sizeof(struct canfd_frame)) != sizeof(struct canfd_frame)) {
#else
	sizeof(struct can_frame)) != sizeof(struct can_frame)) {
#endif
        perror("Write");
        return FAILURE;
    }

    return SUCCESS;
}

/**
 * @brief Read Data from CAN port
 * @param NA
 * @return 0 on success, -1 on failure.
 * @note Reads data from CAN port and displays
 *	 it on console
 */
int iReadCANData(void) {
    uint8_t u8Index = INIT_0;
    int iBytesRead = INIT_0;

#ifdef CAN_FD_FLAG
    memset(&sCANFrameVar, INIT_0, sizeof(struct canfd_frame));
#else
    memset(&sCANFrameVar, INIT_0, sizeof(struct can_frame));
#endif

    iBytesRead = read(iCANSocket,
                     &sCANFrameVar,
#ifdef CAN_FD_FLAG
                     sizeof(struct canfd_frame));
#else
                     sizeof(struct can_frame));
#endif

    if(iBytesRead < INIT_0) {
        perror("Read");
        return FAILURE;
    }

    printf("ID : 0x%03X\n", sCANFrameVar.can_id);
#ifdef CAN_FD_FLAG
    printf("DLC: %d\n", sCANFrameVar.len);
#else
    printf("DLC: %d\n", sCANFrameVar.can_dlc);
#endif

    printf("Data   : ");
#ifdef CAN_FD_FLAG
    for(u8Index = INIT_0; u8Index < sCANFrameVar.len; u8Index++) {
#else
    for(u8Index = INIT_0; u8Index < sCANFrameVar.can_dlc; u8Index++) {
#endif
        printf("%02X ", sCANFrameVar.data[u8Index]);
    }

    printf("\n");

    return SUCCESS;
}

int main(void) {
    if(iInitCANPort() == FAILURE) {
        printf("Unable to initialize CAN Port\n");
        goto FAILED;
    }

    if(iWriteCANData() == FAILURE) {
        printf("Unable to write the data to CAN port\n");
	goto FAILED;
    }

    if(iReadCANData() == FAILURE) {
	printf("Unable to read the data from CAN port\n");
        goto FAILED;
    }

FAILED:
    if(close(iCANSocket) < INIT_0) {
        perror("Close");
    }

    return SUCCESS;
}
