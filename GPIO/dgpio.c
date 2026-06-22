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
 * @brief .
 * @param cArrServerIP Buffer to store the server IP address.
 * @param size Size of the buffer.
 * @return 0 on success, -1 on failure.
 * @note This function will get the server IP address.
 */
// Helper function to write data to a system file path
int8_t i8WriteData(const char *cpPath, const char *cpValue) {

    int fd = open(path, O_WRONLY);
    if (fd == -1) {
        perror("Failed to open path");
        return -1;
    }
    
    if (write(fd, value, strlen(value)) == -1) {
        perror("Failed to write to path");
        close(fd);
        return -1;
    }
    
    close(fd);
    return 0;
}



void udpatepin() {

// Change this to match your physical hardware pin configuration
    const char *pin = "24"; 
    char path_buffer[128];

    // 1. Export the GPIO pin to make it available in user space
    printf("Exporting GPIO %s...\n", pin);
    write_to_path(GPIO_PATH "/export", pin);
    usleep(100000); // Small delay to let the OS create sysfs entries

    // 2. Set the pin direction to output ("out")
    snprintf(path_buffer, sizeof(path_buffer), GPIO_PATH "/gpio%s/direction", pin);
    printf("Setting direction to out...\n");
    if (write_to_path(path_buffer, "out") == -1) {
        goto cleanup;
    }

    // Prepare the path to change the digital logic value
    snprintf(path_buffer, sizeof(path_buffer), GPIO_PATH "/gpio%s/value", pin);

    // 3. Set the GPIO pin (Logic High / 1)
    printf("Setting GPIO %s (HIGH)...\n", pin);
    write_to_path(path_buffer, "1");
    sleep(2); // Keep high for 2 seconds

    // 4. Clear the GPIO pin (Logic Low / 0)
    printf("Clearing GPIO %s (LOW)...\n", pin);
    write_to_path(path_buffer, "0");
    sleep(2); // Keep low for 2 seconds

cleanup:
    // 5. Unexport the GPIO pin to clean up resources
    printf("Unexporting GPIO %s...\n", pin);
    write_to_path(GPIO_PATH "/unexport", pin);

    return 0;

}




int main()
{
	if(i8UARTInit() != SUCCESS) {
		printf("Unable to setup UART\n");
		return INIT_1;
	}

	if(i8UARTReadWrite() == FAILURE) {
		printf("Unable to read/write data over UART\n");
		close(iSerialPort);
		return INIT_1;
	}

	return SUCCESS;
}
