/**
 * @file        uart_rw.c
 * @brief       Read and write data over UART
 * @details     Linux Devices to read and write the data
 * 		over UART
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
#include "uart_rw.h"

/**
 * @brief .
 * @param cArrServerIP Buffer to store the server IP address.
 * @param size Size of the buffer.
 * @return 0 on success, -1 on failure.
 * @note This function will get the server IP address.
 */
int8_t i8UARTInit() {
	// 1. Open the serial port device file
	// O_RDWR: Read and write access
	// O_NOCTTY: Prevents the port from becoming the controlling terminal
	iSerialPort = open(TTY_PORT_NAME, O_RDWR | O_NOCTTY);

	if (iSerialPort < INIT_0) {
		printf("Error %i from open: %s\n", errno, strerror(errno));
		return FAILURE;
	}

	// 2. Configure the serial port settings using termios
	struct termios tty;
	if (tcgetattr(iSerialPort, &tty) != INIT_0) {
		printf("Error %i from tcgetattr: %s\n", errno, strerror(errno));
		close(iSerialPort);
		return FAILURE;
	}

	// Set Baud Rate to 115200 for both input and output
	cfsetispeed(&tty, BAUD_115200);
	cfsetospeed(&tty, BAUD_115200);

	// Control Modes (c_cflag)
	tty.c_cflag &= ~PARENB;        // Clear parity bit (No parity)
	tty.c_cflag &= ~CSTOPB;        // Clear stop field (Only 1 stop bit)
	tty.c_cflag &= ~CSIZE;         // Clear bits-per-byte size
	tty.c_cflag |= CS8;            // 8 bits per byte
	tty.c_cflag &= ~CRTSCTS;       // Disable RTS/CTS hardware flow control
	tty.c_cflag |= CREAD | CLOCAL; // Turn on READ & ignore control lines

	// Local Modes (c_lflag)
	tty.c_lflag &= ~ICANON;        // Disable canonical mode (Read raw bytes)
	tty.c_lflag &= ~ECHO;          // Disable echo
	tty.c_lflag &= ~ECHOE;         // Disable erasure
	tty.c_lflag &= ~ECHONL;        // Disable new-line echo
	tty.c_lflag &= ~ISIG;          // Disable interpretation of INTR, QUIT and SUSP

	// Input Modes (c_iflag)
	tty.c_iflag &= ~(IXON | IXOFF | IXANY); // Turn off software flow control
	tty.c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL); // Disable special handling

	// Output Modes (c_oflag)
	tty.c_oflag &= ~OPOST;         // Prevent special interpretation of output bytes
	tty.c_oflag &= ~ONLCR;         // Prevent conversion of newline to carriage return

	// Read Blocking/Timeout Configuration
	// VMIN = 1: Wait until at least 1 byte is available
	// VTIME = 0: No timeout, block indefinitely until a byte arrives
	tty.c_cc[VMIN] = INIT_1;
	tty.c_cc[VTIME] = INIT_0;

	// Save tty settings, commit changes immediately
	if (tcsetattr(iSerialPort, TCSANOW, &tty) != INIT_0) {
		printf("Error %i from tcsetattr: %s\n", errno, strerror(errno));
		close(iSerialPort);
		return FAILURE;
	}

	return SUCCESS;
}

/**
 * @brief Read and Write the data over UART port.
 * @param void.
 * @return 0 on success, -1 on failure.
 * @note This function will get the server IP address.
 */
int8_t i8UARTReadWrite() {

	char read_buffer[READ_BUFFER];
	unsigned char msg[] = "Read Successful\r\n";
	printf("Listening for data on UART...\n");

	while (INIT_1) {
		memset(&read_buffer, NULL_BYTE, sizeof(read_buffer));

		// Read bytes from the serial port
		int num_bytes = read(iSerialPort, &read_buffer, sizeof(read_buffer) - INIT_1);

		if (num_bytes < INIT_0) {
			printf("Error reading: %s\n", strerror(errno));
			break;
		} else if (num_bytes == INIT_0) {
			printf("No data read (Timeout or EOF)\n");
		} else {
			// Null-terminate the string safely and print
			read_buffer[num_bytes] = '\0';
			printf("Received %i bytes: %s\n", num_bytes, read_buffer);
			ssize_t bytes_written = write(iSerialPort, msg, sizeof(msg) - INIT_1);
			if (bytes_written < INIT_0) {
				printf("Error writing: %s\n", strerror(errno));
				break;
			} else {
				printf("Successfully wrote %ld bytes.\n", bytes_written);
			}
		}
	}
	return FAILURE;
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
