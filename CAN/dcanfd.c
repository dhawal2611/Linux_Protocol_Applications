/**
 * @file        dcanfd.c
 * @brief       Read and Write CAN FD data over SocketCAN
 * @details     This application demonstrates CAN FD communication
 *              using Linux SocketCAN APIs.
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
    int iEnableCANFD = 1;

    if ((iCANSocket = socket(PF_CAN, SOCK_RAW, CAN_RAW)) < INIT_0) {
        perror("Socket");
        return FAILURE;
    }

    strcpy(sIFR.ifr_name, CAN_PORT_NAME);

    if (ioctl(iCANSocket, SIOCGIFINDEX, &sIFR) < INIT_0) {
        perror("ioctl");
        return FAILURE;
    }

    if (setsockopt(iCANSocket,
                   SOL_CAN_RAW,
                   CAN_RAW_FD_FRAMES,
                   &iEnableCANFD,
                   sizeof(iEnableCANFD)) < INIT_0) {
        perror("setsockopt");
        return FAILURE;
    }

    memset(&sSocketCANAddr, INIT_0, sizeof(sSocketCANAddr));
    sSocketCANAddr.can_family = AF_CAN;
    sSocketCANAddr.can_ifindex = sIFR.ifr_ifindex;

    if (bind(iCANSocket,
             (struct sockaddr *)&sSocketCANAddr,
             sizeof(sSocketCANAddr)) < INIT_0) {
        perror("Bind");
        return FAILURE;
    }

    return SUCCESS;
}

/**
 * @brief Write CAN FD frame
 * @param NA
 * @return SUCCESS on success, FAILURE on failure
 */
int iWriteCANFDData(void) {
    uint8_t u8Index = INIT_0;

    memset(&sCANFDFrameVar, INIT_0, sizeof(struct canfd_frame));

    // Sending a 29-bit Extended ID in CAN FD
    sCANFDFrameVar.can_id = CAN_ID  | CAN_EFF_FLAG; // Packs the extended format flag
    sCANFDFrameVar.len = CAN_FD_DATA_LEN;
    sCANFDFrameVar.flags = CANFD_BRS;

    for (u8Index = INIT_0; u8Index < CAN_FD_DATA_LEN; u8Index++) {
        sCANFDFrameVar.data[u8Index] = u8Index;
    }

    if (write(iCANSocket,
              &sCANFDFrameVar,
              sizeof(struct canfd_frame)) != sizeof(struct canfd_frame))
    {
        perror("Write");
        return FAILURE;
    }

    printf("Successfully sent CAN FD Frame (ID: 0x%03X)\n",
           sCANFDFrameVar.can_id);

    return SUCCESS;
}

/**
 * @brief Read CAN FD frame
 * @param NA
 * @return SUCCESS on success, FAILURE on failure
 */
int iReadCANFDData(void) {
    uint8_t u8Index = INIT_0;
    int iBytesRead = INIT_0;

    struct canfd_frame sRxCANFDFrame;

    memset(&sRxCANFDFrame, INIT_0, sizeof(struct canfd_frame));

    printf("Waiting to receive CAN FD frame...\n");

    iBytesRead = read(iCANSocket,
                      &sRxCANFDFrame,
                      sizeof(struct canfd_frame));

    if (iBytesRead < INIT_0) {
        perror("Read");
        return FAILURE;
    }

    if(iBytesRead == sizeof(struct can_frame)) {

        printf("Received Classical CAN Frame\n");
        printf("ID : 0x%03X\n", sRxCANFDFrame.can_id);
        printf("DLC: %d\n", sRxCANFDFrame.len);

    } else if(iBytesRead == sizeof(struct canfd_frame)) {

        printf("Received CAN FD Frame\n");
        printf("ID     : 0x%03X\n", sRxCANFDFrame.can_id);
        printf("Length : %d\n", sRxCANFDFrame.len);
        printf("Data   : ");

        for(u8Index = INIT_0; u8Index < sRxCANFDFrame.len; u8Index++) {
            printf("%02X ", sRxCANFDFrame.data[u8Index]);
        }

        printf("\n");
    }

    return SUCCESS;
}

/**
 * @brief Main Function
 * @param NA
 * @return SUCCESS on success, FAILURE on failure
 */
int main(void) {
    if (iInitCANFDPort() == FAILURE)
    {
        printf("Unable to initialize CAN FD Port\n");
        goto FAILED;
    }

    if(iWriteCANFDData() == FAILURE) {
        printf("Unable to write the data to CAN port\n");
	goto FAILED;
    }

    if(iReadCANFDData() == FAILURE) {
	printf("Unable to read the data from CAN port\n");
        goto FAILED;
    }

FAILED:
    if(close(iCANSocket) < INIT_0) {
        perror("Close");
    }

    return SUCCESS;
}
