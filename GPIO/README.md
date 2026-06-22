# UART Communication

<p align="center">
  <img src="UART_Communication.png" alt="UART Communication Overview" width="1000">
</p>

---

# Table of Contents

- UART Overview
- UART Pins
- Asynchronous Communication
- Baud Rates
- Frame Format
- Communication Modes
- Hardware Connections
- UART Configuration
- Independent Testing
- Loopback Testing
- Building uart_rw
- Application Testing
- Troubleshooting
- Advantages
- Applications

---

# UART (Universal Asynchronous Transmitter Receiver)

UART (**Universal Asynchronous Transmitter Receiver**) is one of the most widely used serial communication protocols in embedded systems. It enables communication between two devices by transmitting data serially over dedicated transmit (**TX**) and receive (**RX**) lines.

UART communication is **asynchronous**, which means that communicating devices do not share a common clock signal. Instead, both devices must be configured with identical communication parameters such as baud rate, data bits, parity, and stop bits.

UART is commonly used for:

* Embedded Linux Consoles
* Debugging Interfaces
* GPS Modules
* Bluetooth Modules
* GSM Modems
* Microcontroller Communication
* Sensor Interfaces
* Bootloaders

---

# UART Overview

| Property           | Description                                 |
| ------------------ | ------------------------------------------- |
| Full Form          | Universal Asynchronous Transmitter Receiver |
| Communication Type | Asynchronous                                |
| Clock Signal       | Not Required                                |
| Typical Distance   | Short to Medium                             |
| Topology           | Point-to-Point                              |
| Cost               | Low                                         |
| Complexity         | Simple                                      |

---

# UART Pins

UART primarily uses two signal lines.

| Pin | Description   |
| --- | ------------- |
| TX  | Transmit Data |
| RX  | Receive Data  |

For reliable communication, connecting the grounds of both devices is highly recommended.

| Signal | Connection |
| ------ | ---------- |
| TX     | RX         |
| RX     | TX         |
| GND    | GND        |

---

# Asynchronous Communication

UART communication is asynchronous.

Unlike protocols such as SPI or I2C, UART does not use a dedicated clock line.

Synchronization is achieved by:

* Start Bit
* Configured Baud Rate
* Stop Bit

Both devices must be configured with identical settings.

Typical UART parameters:

* Baud Rate
* Data Bits
* Parity
* Stop Bits
* Flow Control

---

# Common Baud Rates

Common UART baud rates are shown below.

| Baud Rate (bps) |
| --------------- |
| 4800            |
| 9600            |
| 19200           |
| 38400           |
| 57600           |
| 115200          |
| 230400          |
| 460800          |
| 921600          |

---

## Baud Rate Formula

```text
Baud Rate = Bit Rate (bps) / Number of Bits per Unit Data
```

For UART,

```text
1 Symbol = 1 Bit
```

Therefore,

```text
115200 Baud = 115200 Bits per Second
```

---

# UART Frame Format

Each UART transmission is organized into a frame.

| Field      | Size     |
| ---------- | -------- |
| Start Bit  | 1 Bit    |
| Data Bits  | 5–9 Bits |
| Parity Bit | 0–1 Bit  |
| Stop Bits  | 1–2 Bits |

```text
+-------+----------+---------+------+
|Start  | Data     |Parity   |Stop  |
+-------+----------+---------+------+
```

---

# Communication Modes

UART supports several communication modes.

---

## 1. Simplex Communication

Data flows in only one direction.

```text
Device A -----------------> Device B
```

Characteristics:

* One-way communication
* Sender only transmits
* Receiver only receives

Examples:

* GPS receiver
* Data logger
* Broadcast sensors

---

## 2. Duplex Communication

UART can also operate in duplex mode.

### Half Duplex

Both devices can transmit and receive.

Only one device transmits at a time.

```text
Device A <-------------> Device B

Only one side communicates at a time
```

Characteristics:

* Bidirectional
* Shared medium
* Turn-based communication

Examples:

* RS485 Networks
* Walkie-Talkies

---

### Full Duplex

Both devices communicate simultaneously.

```text
Device A <==============> Device B
```

Characteristics:

* Simultaneous TX/RX
* Independent channels
* Higher throughput

Examples:

* USB-UART Adapter
* Linux Serial Console
* MCU to MCU Communication

---

# UART Hardware Connections

## UART1 ↔ UART2

```text
UART1                    UART2
--------------------------------
TX     ----------------> RX
RX     <---------------- TX
GND    ----------------> GND
```

---

# UART Port Configuration


```bash
stty -F /dev/ttyUSB1 115200 raw -echo -echoe -echok -onlcr -icrnl
```

Verify

```bash
stty -F /dev/ttyUSB1 -a
```

## Explanation

- raw : Raw mode
- -echo : Disable echo
- -echoe : Disable erase
- -echok : Disable kill processing
- -onlcr : Disable NL conversion
- -icrnl : Disable CR conversion

---

# Configure Both UART Ports


```bash
stty -F /dev/ttyUSB0 115200 raw -echo -echoe -echok -onlcr -icrnl
stty -F /dev/ttyUSB1 115200 raw -echo -echoe -echok -onlcr -icrnl
```

---

# Independent UART Testing


Terminal-1

```bash
cat /dev/ttyUSB0
```


Terminal-2


```bash
echo "HELLO_UART2" > /dev/ttyUSB1
```


Reverse Test


```bash
cat /dev/ttyUSB1

echo "HELLO_UART1" > /dev/ttyUSB0
```

---

# Continuous Communication Test


```bash
while true
do
 echo "DATA_TEST" > /dev/ttyUSB1
 sleep 1
done
```

---

# UART Loopback Testing


Connect TX to RX.


```bash
cat /dev/ttyUSB0

echo "LOOPBACK_TEST" > /dev/ttyUSB0
```



# uart_rw Application


## Project Structure


```text
UART/
├── README.md
├── UART_Communication.png
├── Makefile
├── uart_rw.c
├── uart_rw.h
├── uart_rw.o
└── uart_rw
```


## Build


```bash
cd Linux_Protocol_Applications/UART

make
```


Expected


```bash
gcc -Wall -Wextra -O2 -c uart_rw.c -o uart_rw.o
gcc -Wall -Wextra -O2 -o uart_rw uart_rw.o
```


## Run


```bash
./uart_rw
```


Expected


```text
Listening for data on UART...

Received 6 bytes: hello

Successfully wrote 17 bytes.
```


Transmit


```bash
echo "hello" > /dev/ttyUSB1
```


Read


```bash
cat /dev/ttyUSB1
```


Expected


```text
Read Successful
```


# Troubleshooting


```bash
ls /dev/ttyUSB*

dmesg | grep tty

ls -l /dev/ttyUSB0
ls -l /dev/ttyUSB1

sudo usermod -aG dialout $USER
```

---

# Advantages of UART

* Simple implementation
* Requires only two signal lines
* No clock synchronization needed
* Low hardware cost
* Supported by almost all MCUs
* Widely available in Linux
* Useful for debugging

---


# Applications

UART is extensively used in embedded systems.

Examples include:

* Linux Debug Console
* GPS Modules
* GSM Modems
* Bluetooth Modules
* Industrial Controllers
* Sensor Interfaces
* Bootloaders
* Embedded Linux BSP Development
* Firmware Upgrade Utilities

---

# Summary

UART (**Universal Asynchronous Transmitter Receiver**) is one of the simplest and most widely adopted serial communication protocols used in embedded systems.

It provides reliable point-to-point communication using dedicated **TX** and **RX** lines without requiring a shared clock signal. Understanding baud rates, frame formats, and communication modes is essential for designing robust embedded and Linux-based applications.

---

## Author

**Dhawal Umesh Lad**

Embedded Linux Developer

Expertise:

* UART
* SPI
* I2C
* CAN
* Yocto
* OpenWRT
* Device Drivers
* BSP Development
* Embedded Systems

