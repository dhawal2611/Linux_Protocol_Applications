/**
 * @file        dgpio.c
 * @brief       Set and Clear custom GPIO pin
 * @details     Set or Clear the GPIO pin provided as
 * 		an argument
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
#include "dgpio.h"

/**
 * @brief Export Provided GPIO
 * @param u32Pin pin number
 * @return 0 on success, -1 on failure.
 * @note This function will export the GPIO
 */
int iGpioExport(uint32_t u32Pin) {
    char cBuffer[BUFFER_SIZE] = {INIT_0};
    int iRetLen = INIT_0, iFd = INIT_0;

    iRetLen = snprintf(cBuffer, sizeof(cBuffer), "%s%s", GPIO_PATH, GPIO_EXPORT_PATH);
    if (iRetLen <= INIT_0) {
        return FAILURE;
    }

    iFd = open(cBuffer, O_WRONLY);
    if (iFd < INIT_0) {
        return FAILURE;
    }

    iRetLen = snprintf(cBuffer, sizeof(cBuffer), "%d", u32Pin);
    if (iRetLen <= INIT_0) {
        close(iFd);
        return FAILURE;
    }

    if (write(iFd, cBuffer, iRetLen) < INIT_0) {
        close(iFd);
        return FAILURE;
    }

    close(iFd);
    return SUCCESS;
}

/**
 * @brief Unexport Provided GPIO
 * @param u32Pin pin number
 * @return 0 on success, -1 on failure.
 * @note This function will unexport the GPIO
 */
int iGpioUnexport(uint32_t u32Pin) {
    char cBuffer[BUFFER_SIZE] = {INIT_0};
    int iRetLen = INIT_0, iFd = INIT_0;

    iRetLen = snprintf(cBuffer, sizeof(cBuffer), "%s%s", GPIO_PATH, GPIO_UNEXPORT_PATH);
    if (iRetLen <= INIT_0) {
        return FAILURE;
    }

    iFd = open(cBuffer, O_WRONLY);
    if (iFd < INIT_0) {
        return FAILURE;
    }

    iRetLen = snprintf(cBuffer, sizeof(cBuffer), "%d", u32Pin);
    if (iRetLen <= INIT_0) {
        close(iFd);
        return FAILURE;
    }

    if (write(iFd, cBuffer, iRetLen) < INIT_0) {
        close(iFd);
        return FAILURE;
    }

    close(iFd);
    return SUCCESS;
}

/**
 * @brief Set GPIO Direction
 * @param u32Pin pin number
 * @param cpDirection to set as input (read) or output (write)
 * @return 0 on success, -1 on failure.
 * @note Set GPIO direction to read or write
 */
int iGpioSetDirection(uint32_t u32Pin, const char *cpDirection) {
    char cBuffer[BUFFER_SIZE] = {INIT_0};
    int iRetLen = INIT_0, iFd = INIT_0;

    if (cpDirection == NULL) {
        return FAILURE;
    }

    iRetLen = snprintf(cBuffer, sizeof(cBuffer), "%s/gpio%d/direction", GPIO_PATH, u32Pin);
    if (iRetLen <= INIT_0) {
        return FAILURE;
    }

    iFd = open(cBuffer, O_WRONLY);
    if (iFd < INIT_0) {
        return FAILURE;
    }

    iRetLen = strlen(cpDirection);
    if (write(iFd, cpDirection, iRetLen) < INIT_0) {
        close(iFd);
        return FAILURE;
    }

    close(iFd);
    return SUCCESS;
}

/**
 * @brief Write GPIO value
 * @param u32Pin pin number
 * @return 0 on success, -1 on failure.
 * @note Write the GPIO value to 1 or 0
 */
int iGpioWriteValue(uint32_t u32Pin, uint8_t u8Value) {
    char cBuffer[BUFFER_SIZE] = {INIT_0};
    int iRetLen = INIT_0, iFd = INIT_0;
    const char *cpValStr = (u8Value == INIT_1) ? GPIO_VALUE_1 : GPIO_VALUE_0;

    iRetLen = snprintf(cBuffer, sizeof(cBuffer), "%s/gpio%d/value", GPIO_PATH, u32Pin);
    if (iRetLen <= INIT_0) {
        return FAILURE;
    }

    iFd = open(cBuffer, O_WRONLY);
    if (iFd < INIT_0) {
        return FAILURE;
    }

    // Writing exactly 1 byte: "1" or "0"
    if (write(iFd, cpValStr, INIT_1) < INIT_0) {
        close(iFd);
        return FAILURE;
    }

    close(iFd);
    return SUCCESS;
}

/**
 * @brief Read GPIO Value
 * @param u32Pin pin number
 * @return 0 or 1 on GPIO state, -1 on failure.
 * @note Open and read GPIO val from path
 */
int iGpioReadValue(uint32_t u32Pin) {
    char cBuffer[BUFFER_SIZE] = {INIT_0};
    char cValueChar = '\0';
    int iRetLen = INIT_0, iFd = INIT_0;

    iRetLen = snprintf(cBuffer, sizeof(cBuffer), "%s/gpio%d/value", GPIO_PATH, u32Pin);
    if (iRetLen <= INIT_0) {
        return FAILURE;
    }

    iFd = open(cBuffer, O_RDONLY);
    if (iFd < INIT_0) {
        return FAILURE;
    }

    if (read(iFd, &cValueChar, INIT_1) < INIT_0) {
        close(iFd);
        return FAILURE;
    }

    close(iFd);
    return (cValueChar == GPIO_CHECK_1) ? GPIO_RVALUE_1 : GPIO_RVALUE_0;
}

/**
 * @brief Set the GPIO
 * @param u32Pin pin number
 * @return 0 on success, -1 on failure.
 * @note Set GPIO HIGH
 */
int iSetGPIO(uint32_t u32Pin) {
	if(iGpioExport(u32Pin) == FAILURE) {
		printf("Unable to export GPIO %d", u32Pin);
		return FAILURE;
	}
	if(iGpioSetDirection(u32Pin, GPIO_DIR_OUT) == FAILURE) {
		printf("Unable to set %d GPIO direction", u32Pin);
		return FAILURE;
	}
	if(iGpioWriteValue(u32Pin, SET_GPIO) == FAILURE) {
		printf("Unable to set %d GPIO", u32Pin);
		return FAILURE;
	}
	if(iGpioUnexport(u32Pin) == FAILURE) {
		printf("Unable to unexport GPIO %d", u32Pin);
		return FAILURE;
	}
	return SUCCESS;
}

/**
 * @brief Clear GPIO
 * @param u32Pin pin number
 * @return 0 on success, -1 on failure.
 * @note Set GPIO LOW
 */
int iClearGPIO(uint32_t u32Pin) {
	if(iGpioExport(u32Pin) == FAILURE) {
		printf("Unable to export GPIO %d", u32Pin);
		return FAILURE;
	}
	if(iGpioSetDirection(u32Pin, GPIO_DIR_OUT) == FAILURE) {
		printf("Unable to set %d GPIO direction", u32Pin);
		return FAILURE;
	}
	if(iGpioWriteValue(u32Pin, CLR_GPIO) == FAILURE) {
		printf("Unable to clear %d GPIO", u32Pin);
		return FAILURE;
	}
	if(iGpioUnexport(u32Pin) == FAILURE) {
		printf("Unable to unexport GPIO %d", u32Pin);
		return FAILURE;
	}
	return SUCCESS;
}

/**
 * @brief Get GPIO value status
 * @param u32Pin pin number
 * @return Actual GPIO state 0 or 1, -1 on failure.
 * @note Read GPIO Value
 */
int iGetGPIO(uint32_t u32Pin) {
	int iRetReadVal = INIT_0;

	if(iGpioExport(u32Pin) == FAILURE) {
		printf("Unable to export GPIO %d", u32Pin);
		return FAILURE;
	}
	if(iGpioSetDirection(u32Pin, GPIO_DIR_IN) == FAILURE) {
		printf("Unable to set %d GPIO direction", u32Pin);
		return FAILURE;
	}
	if((iRetReadVal = iGpioReadValue(u32Pin)) == FAILURE) {
		printf("Unable to read %d GPIO", u32Pin);
		return FAILURE;
	}
	if(iGpioUnexport(u32Pin) == FAILURE) {
		printf("Unable to unexport GPIO %d", u32Pin);
		return FAILURE;
	}
	return iRetReadVal;
}

int main() {
	int iReadState = INIT_M_1;
	if(iSetGPIO(GPIO_NUM) == FAILURE) {
		printf("Unable to set GPIO %d", GPIO_NUM);
	}

	if(iClearGPIO(GPIO_NUM) == FAILURE) {
		printf("Unable to set GPIO %d", GPIO_NUM);
	}

	if((iReadState = iGetGPIO(GPIO_NUM)) == FAILURE) {
		printf("Unable to read GPIO %d", GPIO_NUM);
	} else {
		printf("GPIO Val is: %d", iReadState);
	}

	return SUCCESS;
}
