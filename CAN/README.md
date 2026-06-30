# Controller Area Network (CAN) Protocol

<p align="center">
    <img src="CAN_Communication.png" alt="CAN Communication" width="900"/>
</p>

---

# Table of Contents

- [Overview](#overview)
- [CAN Features](#can-features)
- [CAN Characteristics](#can-characteristics)
- [CAN Bit Rates](#can-bit-rates)
- [CAN Frame Types](#can-frame-types)
  - [Standard CAN](#standard-can)
  - [Extended CAN](#extended-can)
- [CAN Frame Structure](#can-frame-structure)
  - [Standard CAN Frame Format (11-bit Identifier)](#standard-can-frame-format-11-bit-identifier)
  - [Extended CAN Frame Format (29-bit Identifier)](#extended-can-frame-format-29-bit-identifier)
  - [Standard CAN FD Frame Format (11-bit Identifier)](#standard-can-fd-frame-format-11-bit-identifier)
  - [Extended CAN FD Frame Format (29-bit Identifier)](#extended-can-fd-frame-format-29-bit-identifier)
- [CAN Frame Fields](#can-frame-fields)
- [CAN Identifier](#can-identifier)
- [Building CAN Support in Yocto](#building-can-support-in-yocto)
- [Yocto Layer Structure](#yocto-layer-structure)
- [Image Configuration](#image-configuration)
- [Kernel Configuration](#kernel-configuration)
  - [Native CAN Controllers](#native-can-controllers)
  - [SPI CAN Controllers](#spi-can-controllers)
- [Machine Specific Kernel Append Files](#machine-specific-kernel-append-files)
  - [NXP i.MX / Vybrid VF61](#nxp-imx--vybrid-vf61)
  - [Marvell BSP](#marvell-bsp)
  - [Raspberry Pi BSP](#raspberry-pi-bsp)
- [Hardware Specific Configuration](#hardware-specific-configuration)
- [Device Tree Requirements](#device-tree-requirements)
  - [NXP i.MX](#nxp-imx)
  - [Marvell](#marvell)
  - [Raspberry Pi](#raspberry-pi)
- [Building the Image](#building-the-image)
- [Adding CAN Userspace Application](#adding-can-userspace-application)
- [Application Directory Structure](#application-directory-structure)
- [BitBake Recipe](#bitbake-recipe)
- [Application Makefile](#application-makefile)
- [Adding Application to Image](#adding-application-to-image)
- [Building the Application](#building-the-application)
- [Building using Yocto SDK](#building-using-yocto-sdk)
- [Deploying to Target](#deploying-to-target)
- [Verifying CAN Driver](#verifying-can-driver)
- [Configure Classical CAN](#configure-classical-can)
- [Configure CAN FD](#configure-can-fd)
- [Testing using can-utils](#testing-using-can-utils)
- [CAN FD Programming Checklist](#can-fd-programming-checklist)
- [Troubleshooting](#troubleshooting)
- [CAN Hardware Architecture](#can-hardware-architecture)
- [SocketCAN Software Architecture](#socketcan-software-architecture)
- [CAN Communication Flow](#can-communication-flow)
- [Classical CAN vs CAN FD](#classical-can-vs-can-fd)
- [CAN Error Detection](#can-error-detection)
- [CAN Error States](#can-error-states)
- [CAN Arbitration](#can-arbitration)
- [Acceptance Filters](#acceptance-filters)
- [CAN Identifier Priority](#can-identifier-priority)
- [CAN Bus Termination](#can-bus-termination)
- [Common SocketCAN Structures](#common-socketcan-structures)
  - [Classical CAN](#classical-can)
  - [CAN FD](#can-fd)
- [Common SocketCAN Flags](#common-socketcan-flags)
- [Repository Structure](#repository-structure)
- [References](#references)
- [License](#license)

---

# Overview

Controller Area Network (CAN) is a robust, message-oriented serial communication protocol developed by Bosch for reliable communication between Electronic Control Units (ECUs). CAN is designed for real-time embedded systems and provides high-speed, fault-tolerant communication over a two-wire differential bus.

Unlike UART, SPI, or I2C, CAN is a multi-master protocol where every node can transmit messages. Message arbitration is performed using the CAN Identifier, ensuring deterministic communication without data collisions.

Today, CAN is widely used in:

- Automotive Electronics
- Industrial Automation
- Medical Equipment
- Robotics
- Embedded Linux Systems
- Aerospace
- Marine Electronics

---

# CAN Features

- Multi-master communication
- Message-based protocol
- Differential signaling
- Half-duplex communication
- High noise immunity
- Built-in CRC error detection
- Automatic retransmission
- Error confinement
- Priority-based arbitration
- Supports up to 64-byte payload using CAN FD

---

# CAN Characteristics

| Property | Value |
|-----------|-------|
| Communication Type | Serial |
| Duplex | Half Duplex |
| Synchronization | Asynchronous |
| Bus Type | Multi-master |
| Arbitration | CSMA/CR |
| Maximum Classical Data | 8 Bytes |
| Maximum CAN FD Data | 64 Bytes |
| Error Detection | CRC, ACK, Bit Monitoring |
| Operating Voltage | Hardware Dependent |

---

# CAN Bit Rates

Common CAN bus speeds include:

| Bit Rate |
|-----------|
| 50 kbps |
| 125 kbps |
| 250 kbps |
| 500 kbps |
| 800 kbps |
| 1 Mbps |
| CAN FD Data Phase up to 5 Mbps (Controller Dependent) |

---

# CAN Frame Types

CAN supports two identifier formats.

## Standard CAN

- 11-bit Identifier
- Base Frame Format
- Most commonly used

Example

```c
0x123
```

---

## Extended CAN

- 29-bit Identifier
- Extended Frame Format

Example

```c
frame.can_id = 0x1ABCDEFF | CAN_EFF_FLAG;
```

When using SocketCAN, the `CAN_EFF_FLAG` must be OR'ed with the identifier to indicate an extended (29-bit) frame.

---

# CAN Frame Structure

## Standard CAN Frame Format (11-bit Identifier)

```text
┌─────┬───────────────────┬─────┬─────┬────┬─────┬────────────────┬─────┬─────┬─────┬─────┐
│ SOF │ 11-bit Identifier │ RTR │ IDE │ r0 │ DLC │ 0-8 Bytes Data │ CRC │ ACK │ EOF │ IFS │
└─────┴───────────────────┴─────┴─────┴────┴─────┴────────────────┴─────┴─────┴─────┴─────┘
```

---

## Extended CAN Frame Format (29-bit Identifier)

```text
┌─────┬───────────────────┬─────┬─────┬───────────────────┬─────┬────┬────┬─────┬────────────────┬─────┬─────┬─────┬─────┐
│ SOF │ 11-bit Identifier │ SRR │ IDE │ 18-bit Identifier │ RTR │ r0 │ r1 │ DLC │ 0-8 Bytes Data │ CRC │ ACK │ EOF │ IFS │
└─────┴───────────────────┴─────┴─────┴───────────────────┴─────┴────┴────┴─────┴────────────────┴─────┴─────┴─────┴─────┘
```

---

## Standard CAN FD Frame Format (11-bit Identifier)

```text
┌─────┬───────────────────┬─────┬─────┬─────┬─────┬─────┬─────┬─────────────────┬─────┬─────┬─────┬─────┐
│ SOF │ 11-bit Identifier │ RRS │ FDF │ res │ BRS │ ESI │ DLC │ 0-64 Bytes Data │ CRC │ ACK │ EOF │ IFS │
└─────┴───────────────────┴─────┴─────┴─────┴─────┴─────┴─────┴─────────────────┴─────┴─────┴─────┴─────┘
```

---

## Extended CAN FD Frame Format (29-bit Identifier)

```text
┌─────┬───────────────────┬─────┬─────┬───────────────────┬─────┬─────┬─────┬─────┬─────┬─────────────────┬─────┬─────┬─────┬─────┐
│ SOF │ 11-bit Identifier │ SRR │ IDE │ 18-bit Identifier │ RRS │ FDF │ res │ BRS │ DLC │ 0-64 Bytes Data │ CRC │ ACK │ EOF │ IFS │
└─────┴───────────────────┴─────┴─────┴───────────────────┴─────┴─────┴─────┴─────┴─────┴─────────────────┴─────┴─────┴─────┴─────┘
```
---

# CAN Frame Fields

| Field | Bits | Description |
|------|------|-------------|
| SOF | 1 | Start of Frame |
| Identifier | 11 / 29 | Message Identifier (Priority) |
| RTR | 1 | Remote Transmission Request |
| IDE | 1 | Identifier Extension Bit |
| SRR | 1 | Substitute Remote Request (Extended Only) |
| r0/r1 | 1 | Reserved | Reserved Bits |
| DLC | 4 | Data Length Code |
| Data | 0–64 Bytes | Payload |
| CRC | 16 | Cyclic Redundancy Check |
| ACK | 2 | Acknowledgement |
| EOF | 7 | End Of Frame |
| IFS | 3+ | Inter Frame Space |

---

# CAN Identifier

CAN communication is entirely based on message identifiers.

Lower identifier values have higher priority on the bus.

Examples

Standard CAN

```c
0x321
```

Extended CAN

```c
0x18FF50E5
```

SocketCAN Extended Frame

```c
frame.can_id = 0x18FF50E5 | CAN_EFF_FLAG;
```
---

# Building CAN Support in Yocto

Linux provides native CAN support through the **SocketCAN** networking subsystem. To enable CAN support in a Yocto image, the following components are required:

- Kernel CAN subsystem
- CAN controller drivers
- Device Tree configuration
- User-space utilities (`can-utils`)
- Application package

The recommended approach is to create a dedicated custom layer (`meta-custom`) containing all CAN-related configuration. This keeps the BSP modular and independent of the vendor BSP.

---

# Yocto Layer Structure

Create the following directory structure inside your Yocto project.

```text
meta-custom/
├── conf
│   └── layer.conf
├── recipes-core
│   └── images
│       └── custom-image.bbappend
├── recipes-kernel
│   └── linux
│       ├── files
│       │   ├── can-native.cfg
│       │   ├── can-spi.cfg
│       │   ├── 0001-enable-flexcan.patch
│       │   ├── 0001-enable-mcan.patch
│       │   └── 0001-enable-mcp2515.patch
│       ├── linux-imx_%.bbappend
│       ├── linux-marvell_%.bbappend
│       └── linux-raspberrypi_%.bbappend
└── recipes-can
    └── can-app
        ├── can-app.bb
        └── files
            ├── dcan.c
            ├── dcan.h
            └── Makefile
```

---

# Image Configuration

To include SocketCAN utilities in every image, create the following file.

**File**

```text
meta-custom/recipes-core/images/custom-image.bbappend
```

Add the following:

```bitbake
IMAGE_INSTALL:append = " \
    can-utils \
    iproute2 \
"
```

This automatically installs:

- cansend
- candump
- cangen
- canplayer
- canbusload
- ip utility

---

# Kernel Configuration

Different hardware platforms require different CAN controller drivers.

Instead of maintaining one large kernel configuration file, use configuration fragments.

---

## Native CAN Controllers

Create:

```text
meta-custom/recipes-kernel/linux/files/can-native.cfg
```

```cfg
CONFIG_CAN=y
CONFIG_CAN_RAW=y
CONFIG_CAN_BCM=y
CONFIG_CAN_GW=y
CONFIG_CAN_NETLINK=y
CONFIG_CAN_CALC_BITTIMING=y

CONFIG_CAN_DEV=y

CONFIG_CAN_FLEXCAN=m
CONFIG_CAN_M_CAN=m
CONFIG_CAN_M_CAN_PLATFORM=m
```

Supported hardware

- NXP i.MX
- NXP Vybrid VF61
- Marvell Armada
- Other SoCs with integrated CAN controllers

---

## SPI CAN Controllers

Create

```text
meta-custom/recipes-kernel/linux/files/can-spi.cfg
```

```cfg
CONFIG_CAN=y
CONFIG_CAN_RAW=y
CONFIG_CAN_BCM=y
CONFIG_CAN_GW=y
CONFIG_CAN_NETLINK=y
CONFIG_CAN_CALC_BITTIMING=y

CONFIG_CAN_DEV=y

CONFIG_SPI=y

CONFIG_CAN_MCP251X=m
CONFIG_CAN_MCP251XFD=m
```

Supported hardware

- Raspberry Pi
- MCP2515
- MCP2518FD
- External SPI CAN shields

---

# Machine Specific Kernel Append Files

Each BSP uses a different kernel recipe. Therefore, create a matching `.bbappend` file for each vendor BSP.

---

## NXP i.MX / Vybrid VF61

**File**

```text
meta-custom/recipes-kernel/linux/linux-imx_%.bbappend
```

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://can-native.cfg \
    file://0001-enable-flexcan.patch \
"
```

The Device Tree patch should enable the required FlexCAN controller.

Example

```dts
&flexcan1 {
    status = "okay";
};
```

---

## Marvell BSP

**File**

```text
meta-custom/recipes-kernel/linux/linux-marvell_%.bbappend
```

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://can-native.cfg \
    file://0001-enable-mcan.patch \
"
```

Example Device Tree

```dts
&m_can0 {
    status = "okay";
};
```

---

## Raspberry Pi BSP

**File**

```text
meta-custom/recipes-kernel/linux/linux-raspberrypi_%.bbappend
```

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://can-spi.cfg"
```

---

# Hardware Specific Configuration

The following configuration automatically applies hardware-specific settings based on the selected MACHINE.

Add these settings to:

```text
conf/local.conf
```

```bitbake
##########################################################
# Raspberry Pi Configuration
##########################################################

ENABLE_SPI_BUS = "1"

RPI_EXTRA_CONFIG:append = " \
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25 \
"

##########################################################
# NXP i.MX
##########################################################

SRC_URI:append:imx = " \
 file://0001-enable-flexcan.patch \
"

##########################################################
# Marvell
##########################################################

SRC_URI:append:marvell = " \
 file://0001-enable-mcan.patch \
"
```

> **Note:** The Raspberry Pi overlay assumes an MCP2515 controller with a 16 MHz crystal connected to GPIO 25 for the interrupt. Adjust the overlay parameters if your hardware uses different wiring.

---

# Device Tree Requirements

CAN hardware must be enabled in the Device Tree.

## NXP i.MX

```dts
&flexcan1 {
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_flexcan1>;
    status = "okay";
};
```

---

## Marvell

```dts
&m_can0 {
    status = "okay";
};
```

---

## Raspberry Pi

```text
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25
```

---

# Building the Image

Select the required target machine before building.

## Raspberry Pi

```bash
MACHINE=raspberrypi4-64 bitbake core-image-minimal
```

---

## NXP i.MX8M Mini EVK

```bash
MACHINE=imx8mmevk bitbake core-image-minimal
```

---

## NXP Vybrid VF61

```bash
MACHINE=vf60evk bitbake core-image-minimal
```

---

## Marvell Armada

```bash
MACHINE=<your-marvell-machine> bitbake core-image-minimal
```

After the build completes, the generated image will contain:

- SocketCAN kernel support
- Required CAN drivers
- Device Tree configuration
- `can-utils`
- `iproute2`
- Your custom CAN application (once added in the next section)

---

# Adding CAN Userspace Application

This section explains how to integrate the CAN userspace application into the Yocto build system.

The application consists of the following source files:

```text
dcan.c
dcan.h
Makefile
README.md
```

The application will be built automatically during the Yocto build and installed into the target root filesystem.

---

# Application Directory Structure

Create a new recipe under the custom layer.

```text
meta-custom/
└── recipes-can
    └── can-app
        ├── can-app.bb
        └── files
            ├── dcan.c
            ├── dcan.h
            ├── Makefile
            └── README.md
```

---

# BitBake Recipe

Create

```text
meta-custom/recipes-can/can-app/can-app.bb
```

```bitbake
SUMMARY = "SocketCAN Userspace Application"
DESCRIPTION = "Linux SocketCAN application supporting Classical CAN and CAN FD communication."
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://dcan.c \
    file://dcan.h \
    file://Makefile \
    file://README.md \
"

S = "${WORKDIR}"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}

    install -m 0755 dcan ${D}${bindir}
}

FILES:${PN} += "${bindir}/dcan"
```

---

# Application Makefile

Create

```text
meta-custom/recipes-can/can-app/files/Makefile
```

```make
CC ?= $(CROSS_COMPILE)gcc

TARGET = dcan

SRC = dcan.c

OBJ = $(SRC:.c=.o)

CFLAGS += -Wall
LDFLAGS +=

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $(TARGET) $(LDFLAGS)

clean:
	rm -f *.o $(TARGET)
```

This Makefile automatically works with both:

- Native Linux GCC
- Yocto SDK Cross Compiler

---

# Adding Application to Image

Append the application package to your image.

Example

```bitbake
IMAGE_INSTALL:append = " \
    can-utils \
    iproute2 \
    can-app \
"
```

or inside your custom image recipe

```bitbake
IMAGE_INSTALL += "can-app"
```

After rebuilding, the executable will be available as

```bash
/usr/bin/dcan
```

---

# Building the Application

Rebuild only the application

```bash
bitbake can-app
```

Clean build

```bash
bitbake -c clean can-app

bitbake can-app
```

Rebuild complete image

```bash
bitbake core-image-minimal
```

---

# Building using Yocto SDK

If the SDK has already been generated, the application can also be compiled outside Yocto.

Install SDK

```bash
./poky-glibc-x86_64-core-image-minimal-*.sh
```

Source the environment

```bash
source /opt/poky/*/environment-setup-*
```

Go to the application

```bash
cd CAN
```

Build

```bash
make
```

The SDK automatically exports

- CC
- CXX
- AR
- LD
- STRIP
- SYSROOT

No Makefile modifications are required.

---

# Deploying to Target

Copy the executable

```bash
scp dcan root@<board-ip>:/usr/bin/
```

or

```bash
scp dcan root@<board-ip>:/home/root/
```

Give execute permission

```bash
chmod +x dcan
```

Run

```bash
./dcan
```

---

# Verifying CAN Driver

Check available CAN interfaces

```bash
ip link
```

Expected output

```text
can0
```

---

Verify CAN driver

```bash
ip -details link show can0
```

---

Check CAN statistics

```bash
ip -details -statistics link show can0
```

---

# Configure Classical CAN

Example

500 kbps

```bash
ip link set can0 down

ip link set can0 type can bitrate 500000

ip link set can0 up
```

Verify

```bash
ip -details link show can0
```

---

# Configure CAN FD

Example

500 kbps Arbitration

2 Mbps Data Phase

```bash
ip link set can0 down

ip link set can0 type can bitrate 500000 dbitrate 2000000 fd on

ip link set can0 up
```

Verify

```bash
ip -details link show can0
```

Expected output

```text
fd on
```

---

# Testing using can-utils

Monitor bus traffic

```bash
candump can0
```

Generate random traffic

```bash
cangen can0
```

Transmit Classical CAN frame

```bash
cansend can0 123#1122334455667788
```

Transmit Extended CAN frame

```bash
cansend can0 18FF50E5#0102030405060708
```

Transmit Remote Frame

```bash
cansend can0 123#R
```

Transmit CAN FD frame

```bash
cansend can0 123##112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF
```

Replay captured traffic

```bash
canplayer -I logfile.asc
```

Measure CAN Bus Load

```bash
canbusload can0@500000
```

---

# CAN FD Programming Checklist

Before transmitting CAN FD frames using SocketCAN, ensure the following:

- CAN controller supports CAN FD
- Linux kernel has CAN FD enabled
- `struct canfd_frame` is used
- `CAN_RAW_FD_FRAMES` socket option is enabled
- Interface configured with `fd on`
- Arbitration and data bitrates are configured correctly
- `CANFD_BRS` flag is used when Bit Rate Switching is required

---

# Troubleshooting

## Interface not found

Check

```bash
ip link
```

Verify the Device Tree enables the CAN controller.

---

## CAN interface stays DOWN

Verify

```bash
dmesg | grep can
```

---

## No packets received

Check

- CAN bitrate
- CAN termination (120 Ω)
- Wiring polarity (CANH/CANL)
- CAN ID filter configuration

---

## CAN FD transmission fails

Verify

```bash
ip -details link show can0
```

Ensure

```text
fd on
```

is displayed.

---

## Permission denied

Run

```bash
sudo ip link set can0 up
```

or execute the application as root.

---

# CAN Hardware Architecture

A CAN network consists of one or more CAN nodes connected to a shared differential bus. Each node typically contains:

- Host Processor (MCU/MPU)
- CAN Controller
- CAN Transceiver
- CAN Bus Interface

```text
                    CAN NODE 1
        ┌───────────────────────────────┐
        │        Application            │
        ├───────────────────────────────┤
        │         CAN Driver            │
        ├───────────────────────────────┤
        │       CAN Controller          │
        ├───────────────────────────────┤
        │      CAN Transceiver          │
        └──────────────┬────────────────┘
                       │
                  CANH │==============================│ CANH
                  CANL │==============================│ CANL
                       │
        ┌──────────────┴────────────────┐
        │      CAN Transceiver          │
        ├───────────────────────────────┤
        │       CAN Controller          │
        ├───────────────────────────────┤
        │         CAN Driver            │
        ├───────────────────────────────┤
        │        Application            │
        └───────────────────────────────┘
                    CAN NODE 2
```

---

# SocketCAN Software Architecture

Linux provides native CAN support through the SocketCAN networking subsystem.

Applications communicate with CAN hardware using standard socket APIs.

```text
+------------------------------------+
|      User Application              |
| (SocketCAN Application / dcan)     |
+-----------------+------------------+
                  |
                  | socket()
                  |
+-----------------v------------------+
|      Linux SocketCAN API           |
+-----------------+------------------+
                  |
+-----------------v------------------+
|     CAN Protocol Layer             |
|  RAW | BCM | ISOTP | J1939         |
+-----------------+------------------+
                  |
+-----------------v------------------+
|      CAN Device Driver             |
+-----------------+------------------+
                  |
+-----------------v------------------+
|      CAN Controller Driver         |
|  FlexCAN | M_CAN | MCP2515         |
+-----------------+------------------+
                  |
+-----------------v------------------+
|      CAN Transceiver               |
+-----------------+------------------+
                  |
               CAN Bus
```

---

# CAN Communication Flow

```text
Application

      │

Socket()

      │

SocketCAN

      │

CAN Driver

      │

CAN Controller

      │

CAN Transceiver

      │

============= CAN BUS =============

      │

CAN Transceiver

      │

CAN Controller

      │

CAN Driver

      │

SocketCAN

      │

Receiving Application
```

---

# Classical CAN vs CAN FD

| Feature | Classical CAN | CAN FD |
|----------|---------------|---------|
| Maximum Payload | 8 Bytes | 64 Bytes |
| Arbitration Bitrate | Up to 1 Mbps | Up to 1 Mbps |
| Data Bitrate | Same as Arbitration | Up to 5 Mbps (hardware dependent) |
| Bit Rate Switching | No | Yes |
| CRC | 15-bit | 17/21-bit |
| RTR Support | Yes | No |
| Linux Structure | `struct can_frame` | `struct canfd_frame` |
| Socket Option | Not Required | `CAN_RAW_FD_FRAMES` |
| Linux Kernel Support | Yes | Yes |

---

# CAN Error Detection

CAN provides automatic error detection during communication.

The protocol detects:

- Bit Error
- Stuff Error
- CRC Error
- Form Error
- ACK Error

If an error is detected:

- Error Frame is transmitted.
- Message is discarded.
- Transmission is automatically retried.

---

# CAN Error States

Each CAN controller maintains two internal error counters:

- Transmit Error Counter (TEC)
- Receive Error Counter (REC)

Depending on these counters, the controller operates in one of three states.

| State | Description |
|---------|------------|
| Error Active | Normal communication |
| Error Passive | Limited communication after repeated errors |
| Bus Off | Controller disconnects from the CAN bus |

---

# CAN Arbitration

CAN uses **Carrier Sense Multiple Access with Collision Resolution (CSMA/CR)**.

When two nodes transmit simultaneously:

- Every node monitors the bus while transmitting.
- The message with the **lowest CAN Identifier** wins arbitration.
- The losing node automatically retries transmission after the bus becomes idle.

Example:

```text
Node A : ID = 0x100

Node B : ID = 0x200

Winner : Node A
```

Since `0x100 < 0x200`, Node A has the higher priority.

---

# Acceptance Filters

CAN controllers can filter incoming messages based on their identifiers, reducing CPU load by discarding unwanted frames in hardware.

Example:

```text
Receive only

0x100

Ignore

0x101

0x200

0x321
```

In Linux SocketCAN, filters are configured using `struct can_filter`.

Example:

```c
struct can_filter filter;

filter.can_id = 0x123;
filter.can_mask = CAN_SFF_MASK;

setsockopt(socket_fd,
           SOL_CAN_RAW,
           CAN_RAW_FILTER,
           &filter,
           sizeof(filter));
```

---

# CAN Identifier Priority

The CAN Identifier serves two purposes:

- Identifies the message.
- Determines bus arbitration priority.

Lower numerical identifiers have higher priority.

| CAN Identifier | Priority |
|----------------|----------|
| 0x001 | Highest |
| 0x010 | High |
| 0x100 | Medium |
| 0x700 | Low |
| 0x7FF | Lowest (Standard CAN) |

---

# CAN Bus Termination

Proper bus termination is essential for reliable communication.

A CAN bus must be terminated with **120 Ω resistors** at both physical ends.

```text
120Ω                               120Ω

┌─────┐                         ┌─────┐
│Node │=========================│Node │
└─────┘                         └─────┘
```

Without proper termination, communication errors and signal reflections may occur.

---

# Common SocketCAN Structures

## Classical CAN

```c
struct can_frame
{
    canid_t can_id;
    __u8    can_dlc;
    __u8    data[8];
};
```

---

## CAN FD

```c
struct canfd_frame
{
    canid_t can_id;
    __u8    len;
    __u8    flags;
    __u8    data[64];
};
```

---

# Common SocketCAN Flags

| Flag | Description |
|------|-------------|
| CAN_EFF_FLAG | Extended Frame Format (29-bit Identifier) |
| CAN_RTR_FLAG | Remote Transmission Request |
| CAN_ERR_FLAG | Error Frame |
| CANFD_BRS | Bit Rate Switch |
| CANFD_ESI | Error State Indicator |
| CAN_RAW_FD_FRAMES | Enable CAN FD socket support |

---

# Repository Structure

```text
CAN/
├── dcan.c
├── dcan.h
├── Makefile
└── README.md

```

---

# CAN Physical Layer

The CAN physical layer defines how data is transmitted electrically between nodes over the CAN bus. Unlike UART or SPI, CAN uses **differential signaling** over two wires, making it highly resistant to electromagnetic interference (EMI).

The physical layer is standardized by **ISO 11898** and consists of:

- CAN Controller
- CAN Transceiver
- CANH (CAN High)
- CANL (CAN Low)
- 120 Ω Termination Resistors

---

# CAN Bus Topology

CAN uses a linear bus topology where all nodes are connected in parallel to a common communication bus.

```text
                 120Ω                                    120Ω
             ┌────────┐                            ┌────────┐
             │        │                            │        │
CANH =========+====================================+======== CANH
CANL =========+====================================+======== CANL
              │                                    │
      ┌───────┴───────┐                  ┌─────────┴────────┐
      │    CAN Node   │                  │    CAN Node      │
      └───────────────┘                  └──────────────────┘
              │                                    │
      ┌───────┴───────┐                  ┌─────────┴────────┐
      │    CAN Node   │                  │    CAN Node      │
      └───────────────┘                  └──────────────────┘
```

---

# CAN Bus Components

A typical CAN network consists of the following components.

| Component | Description |
|-----------|-------------|
| Host Processor | Executes the application software |
| CAN Controller | Generates and receives CAN frames |
| CAN Transceiver | Converts logic-level CAN signals to differential bus signals |
| CAN Bus | Two-wire differential communication medium |
| Termination Resistors | Prevent signal reflections on the bus |

---

# CAN Controller

The CAN controller is responsible for implementing the CAN protocol.

Functions include:

- Frame generation
- Frame reception
- Message arbitration
- Bit timing
- CRC generation
- Error detection
- Automatic retransmission
- Acceptance filtering

Examples

- FlexCAN
- Bosch M_CAN
- MCP2515
- MCP2518FD

---

# CAN Transceiver

The CAN transceiver converts logic-level signals from the CAN controller into differential voltages on the CAN bus.

Common CAN transceivers include:

| Device | Description |
|---------|-------------|
| TJA1040 | High-Speed CAN Transceiver |
| TJA1051 | High-Speed CAN FD Transceiver |
| MCP2551 | High-Speed CAN Transceiver |
| SN65HVD230 | 3.3V CAN Transceiver |
| TCAN1042 | Automotive CAN FD Transceiver |

---

# Differential Signaling

CAN transmits data using two wires:

- CANH (CAN High)
- CANL (CAN Low)

Instead of measuring voltage on a single wire, the receiver measures the voltage difference between CANH and CANL.

This significantly improves immunity to electrical noise.

---

# Bus States

CAN has two bus states.

## Dominant Bit (Logic 0)

During transmission of a dominant bit:

| Signal | Typical Voltage |
|---------|-----------------|
| CANH | ≈ 3.5 V |
| CANL | ≈ 1.5 V |
| Differential Voltage | ≈ 2 V |

---

## Recessive Bit (Logic 1)

During transmission of a recessive bit:

| Signal | Typical Voltage |
|---------|-----------------|
| CANH | ≈ 2.5 V |
| CANL | ≈ 2.5 V |
| Differential Voltage | ≈ 0 V |

---

# Dominant vs Recessive State

```text
Dominant Bit (0)

CANH  ──────────────── 3.5V

CANL  ──────────────── 1.5V

Differential Voltage ≈ 2V


Recessive Bit (1)

CANH  ──────────────── 2.5V

CANL  ──────────────── 2.5V

Differential Voltage ≈ 0V
```

---

# CAN Wiring Guidelines

For reliable communication:

- Use twisted pair cable.
- Place 120 Ω termination resistors at both ends of the bus.
- Avoid star topology.
- Keep stub lengths as short as possible.
- Ensure all nodes share a common ground reference.

---

# Maximum Bus Length

The maximum cable length depends on the communication speed.

| Bit Rate | Approximate Maximum Bus Length |
|-----------|-------------------------------:|
| 1 Mbps | 40 m |
| 500 kbps | 100 m |
| 250 kbps | 250 m |
| 125 kbps | 500 m |
| 50 kbps | 1000 m |

> **Note:** Actual bus length depends on cable quality, transceiver characteristics, network topology, and environmental conditions.

---

# CAN vs UART vs SPI vs I2C

| Feature | UART | I2C | SPI | CAN |
|----------|------|-----|-----|-----|
| Communication | Point-to-Point | Multi-Master | Master-Slave | Multi-Master |
| Synchronization | Asynchronous | Synchronous | Synchronous | Asynchronous |
| Differential Signaling | No | No | No | Yes |
| Noise Immunity | Low | Medium | Medium | High |
| Error Detection | Optional | ACK | None | CRC + ACK + Error Frames |
| Arbitration | No | Address-Based | Master Controlled | Identifier-Based |
| Maximum Nodes | 2 | 127 | Hardware Dependent | Hardware Dependent |
| Typical Applications | Debug Console | Sensors | Flash, Displays | Automotive, Industrial |

---

# CAN Bit Timing

CAN communication is synchronized at the bit level. Each transmitted bit is divided into multiple time segments, allowing all nodes on the network to remain synchronized even with slight clock differences.

The duration of one bit is called the **Nominal Bit Time**.

It consists of four segments:

- Synchronization Segment (Sync_Seg)
- Propagation Segment (Prop_Seg)
- Phase Buffer Segment 1 (Phase_Seg1)
- Phase Buffer Segment 2 (Phase_Seg2)

---

# CAN Bit Timing Structure

```text
                  One Nominal Bit Time

┌──────────┬──────────┬─────────────┬─────────────┐
│ Sync_Seg │ Prop_Seg │ Phase_Seg1  │ Phase_Seg2  │
└──────────┴──────────┴─────────────┴─────────────┘
      ↑                         ↑
      │                         │
      │                    Sample Point
      │
Synchronization
```

---

# Bit Timing Parameters

| Parameter | Description |
|-----------|-------------|
| Sync_Seg | Synchronizes all CAN nodes at the beginning of each bit |
| Prop_Seg | Compensates for signal propagation delay across the bus |
| Phase_Seg1 | Used for clock synchronization before the sample point |
| Phase_Seg2 | Used for clock synchronization after the sample point |
| SJW | Synchronization Jump Width used to resynchronize clocks |
| Sample Point | The point where the receiver reads the bus level |

---

# Time Quantum (TQ)

The smallest unit of CAN bit timing is called a **Time Quantum (TQ)**.

One bit is divided into several Time Quanta.

Example

```text
1 Bit

┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│TQ│TQ│TQ│TQ│TQ│TQ│TQ│TQ│TQ│TQ│TQ│TQ│TQ│TQ│TQ│TQ│
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
```

Typical CAN controllers use between **8 and 25 Time Quanta** per bit.

---

# Sample Point

The **Sample Point** is where the CAN controller reads the current bus state.

```text
┌──────────┬──────────┬─────────────┬─────────────┐
│ Sync_Seg │ Prop_Seg │ Phase_Seg1  │ Phase_Seg2  │
└──────────┴──────────┴─────────────┴─────────────┘
                              ▲
                              │
                        Sample Point
```

A sample point between **75% and 87.5%** of the bit time is commonly used in CAN networks.

---

# Synchronization Jump Width (SJW)

Clock oscillators in different CAN nodes are never perfectly identical.

The **Synchronization Jump Width (SJW)** allows the controller to slightly adjust its internal clock to maintain synchronization with the CAN bus.

Benefits include:

- Compensates for oscillator tolerance
- Prevents synchronization loss
- Improves communication reliability

---

# Bit Stuffing

To maintain synchronization, CAN automatically inserts an additional bit after **five consecutive bits of the same polarity**.

The inserted bit has the opposite logic level.

---

## Example Without Bit Stuffing

```text
111111000000
```

This could cause receivers to lose synchronization.

---

## Example With Bit Stuffing

```text
11111 0 100000 1
```

Inserted bits are highlighted below:

```text
Original

111111000000

After Bit Stuffing

11111|0|10000|1|0
```

---

# Bit Stuffing Rule

```text
Five Consecutive Bits

11111

↓

Insert Opposite Bit

11111 0

------------------------

00000

↓

Insert Opposite Bit

00000 1
```

The receiver automatically removes stuffed bits during reception.

---

# Bit Destuffing

The CAN controller automatically removes stuffed bits before delivering data to the application.

```text
Transmitter

11111 0

↓

CAN Bus

111110

↓

Receiver

11111
```

Applications never see stuffed bits.

---

# Bit Timing Example

Example configuration for a **500 kbps** CAN network.

| Parameter | Value |
|-----------|------:|
| Bit Rate | 500 kbps |
| Bit Time | 2 µs |
| Time Quanta | 16 |
| Sample Point | 87.5% |
| SJW | 1 TQ |

---

# CAN Synchronization

CAN uses two synchronization methods.

## Hard Synchronization

Occurs at the **Start of Frame (SOF)**.

All nodes synchronize their internal clocks to the dominant SOF bit.

---

## Resynchronization

Occurs during communication whenever an edge appears earlier or later than expected.

The controller adjusts its clock using the configured SJW.

---

# Why Bit Timing Matters

Proper bit timing ensures:

- Reliable communication
- Low error rate
- Better interoperability
- Maximum bus length
- Stable operation at higher bit rates

Incorrect bit timing may result in:

- CRC Errors
- ACK Errors
- Bit Errors
- Frequent retransmissions
- Bus-Off condition

---

# CAN Bit Timing Summary

| Parameter | Purpose |
|-----------|---------|
| Time Quantum (TQ) | Smallest timing unit |
| Sync_Seg | Synchronization |
| Prop_Seg | Cable delay compensation |
| Phase_Seg1 | Clock adjustment before sampling |
| Phase_Seg2 | Clock adjustment after sampling |
| Sample Point | Reads bus value |
| SJW | Clock correction |
| Bit Stuffing | Maintains synchronization |
| Bit Destuffing | Removes inserted bits at receiver |

---

# References

Linux CAN Documentation

https://www.kernel.org/doc/Documentation/networking/can.txt

Linux Kernel SocketCAN Documentation

https://docs.kernel.org/networking/can.html

eLinux CAN Wiki

https://elinux.org/CAN_Bus

can-utils

https://github.com/linux-can/can-utils

---

# License

This project is intended for educational and embedded Linux development purposes. The examples demonstrate Classical CAN and CAN FD communication using the Linux SocketCAN framework.

