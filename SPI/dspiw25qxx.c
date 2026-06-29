/**
 * @file        di2cAHT20.c
 * @brief       I2C applicaiton code
 * @details     Read and Write data over I2C device
 * @author      Lad Dhawal Umesh
 * @developedBy Lad Dhawal Umesh
 * @date        2026-06-24
 * @version     1.0.0
 * @copyright   (c) 2026 Lad Dhawal Umesh. All rights reserved.
 * Note: This code is an original implementation by Lad Dhawal Umesh. 
 * Certain algorithms or logic patterns were adapted from publicly 
 * available online resources.
 */
// Include Header
#include "di2cAHT20.h"

int main() {
  
  uint8_t u8WriteBuff[WRITE_BYTES_CNT], u8ReadBuff[READ_BYTES_CNT];

  if(iInitI2CDevice() == FAILURE) {
    return FAILURE;
  }
  
  u8WriteBuff[0] = 0xAC;
  u8WriteBuff[1] = 0x33;
  u8WriteBuff[2] = 0x00;
  if(iWriteI2CData(u8WriteBuff, WRITE_BYTES_CNT) == FAILURE) {
    return FAILURE;
  }
  
  // 4. Delay Phase: Wait 100,000 microseconds (100ms / 0.1 seconds)
  // This allows the sensor's internal engine to process the readings
  usleep(DELAY_FOR_AHT20);
  
  if(iReadI2CData(u8ReadBuff, READ_BYTES_CNT) == FAILURE) {
    return FAILURE;
  }

  // Check if the Busy Bit (Bit 7 of the first byte) is 0
    if ((u8ReadBuff[BUFF_INDEX0] & 0x80) == INIT_0) {
        // Extract 20-bit raw Temperature value from bytes 3, 4, and 5
        uint32_t u32RawTemp = ((((uint32_t)u8ReadBuff[BUFF_INDEX3]) & 0x0F) << 16) | 
                            (((uint32_t)u8ReadBuff[BUFF_INDEX4]) << 8) | 
                            ((uint32_t)u8ReadBuff[BUFF_INDEX5]);
        
        // Convert raw bits into real Celsius using datasheet formula
        double dTemperature = (((double)u32RawTemp / 1048576.0) * 200.0) - 50.0;

        // Extract 20-bit raw Humidity value from bytes 1, 2, and 3
        uint32_t u32RawHumidity = (((uint32_t)u8ReadBuff[BUFF_INDEX1]) << 12) | 
                                (((uint32_t)u8ReadBuff[BUFF_INDEX2]) << 4) | 
                                (((uint32_t)u8ReadBuff[BUFF_INDEX3]) >> 4);
        double dHumidity = ((double)u32RawHumidity / 1048576.0) * 100.0;

        // Print final readings
        printf("Temperature: %.2f °C\n", dTemperature);
        printf("Humidity: %.2f %%\n", dHumidity);
    } else {
        printf("Sensor Error: Device was still busy calculating.\n");
        return 1;
    }

    vCloseI2CDevice();
    return SUCCESS;
}

