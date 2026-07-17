# README - Building the SPI Utility in OpenWrt SDK

This document describes how to integrate, build, package, and install the **dspiw25qxx** SPI utility using the **OpenWrt SDK**.

---

# Table of Contents

- Overview
- Prerequisites
- Project Structure
- OpenWrt Package Structure
- Files Required
- Copy the Package
- Package Makefile
- Configure the SDK
- Compile the Package
- Locate the IPK Package
- Install on Target
- Verify Installation
- Running the Application
- Useful OpenWrt Commands
- Troubleshooting

---

# Overview

The **dspiw25qxx** application is a userspace SPI utility that communicates with Winbond W25Qxx SPI Flash devices through the Linux **spidev** interface.

The application can be built as an **OpenWrt package (.ipk)** and installed on any OpenWrt-based target.

---

# Prerequisites

Ensure the following are available.

- OpenWrt SDK
- GCC Toolchain
- GNU Make
- Linux Host Machine
- SPI enabled Linux Kernel
- spidev Driver

---

# Project Structure

```text
spi-utility/
├── Makefile
├── README.md
├── README_OpenWRT.md
├── README_yocto.md
├── dspi_0.1.bb
└── files
    ├── dspi.c
    ├── dspi.h
    ├── dspiw25qxx.c
    ├── dspiw25qxx.h
    ├── Makefile
    └── README.md
```

---

# OpenWrt Package Structure

Inside the OpenWrt SDK:

```text
openwrt-sdk/

package/

└── dspi
    ├── Makefile
    └── src
        ├── dspi.c
        ├── dspi.h
        ├── dspiw25qxx.c
        ├── dspiw25qxx.h
        ├── Makefile
        └── README.md
```

---

# Files Required

Copy the following files.

## Package Makefile

```
Makefile
```

## Source Files

```
dspi.c
dspi.h
dspiw25qxx.c
dspiw25qxx.h
Makefile
```

Documentation files are optional.

---

# Create the Package Directory

Navigate to the SDK.

```bash
cd openwrt-sdk
```

Create the package directory.

```bash
mkdir -p package/dspi/src
```

---

# Copy Source Files

Copy all application source files.

```bash
cp dspi.c package/dspi/src/

cp dspi.h package/dspi/src/

cp dspiw25qxx.c package/dspi/src/

cp dspiw25qxx.h package/dspi/src/

cp Makefile package/dspi/src/

cp README.md package/dspi/src/
```

Copy the OpenWrt package Makefile.

```bash
cp Makefile package/dspi/
```

Your package should look like:

```text
package/

└── dspi
    ├── Makefile
    └── src
        ├── dspi.c
        ├── dspi.h
        ├── dspiw25qxx.c
        ├── dspiw25qxx.h
        ├── Makefile
        └── README.md
```

---

# Configure OpenWrt

Launch menuconfig.

```bash
make menuconfig
```

Navigate to:

```text
Utilities
    --->

        dspi
```

Select:

```
<M> dspi
```

or

```
<*> dspi
```

Save and exit.

---

# Compile the Package

Compile only the package.

```bash
make package/dspi/compile V=s
```

or

```bash
make package/dspi/{clean,compile} V=s
```

---

# Build the Complete Firmware

```bash
make V=s
```

---

# Locate the Generated IPK

After compilation, the generated package will be available under:

```text
bin/packages/<architecture>/base/
```

Example:

```text
bin/packages/aarch64_cortex-a53/base/
```

The generated package:

```text
dspi_1.0-1_aarch64.ipk
```

---

# Copy the IPK to the Target

Using SCP.

```bash
scp dspi_1.0-1_*.ipk root@<target-ip>:/tmp
```

Example:

```bash
scp dspi_1.0-1_*.ipk root@192.168.1.10:/tmp
```

---

# Install the Package

Login to the target.

```bash
ssh root@192.168.1.10
```

Install the package.

```bash
opkg install /tmp/dspi_1.0-1_*.ipk
```

If reinstalling:

```bash
opkg install --force-reinstall /tmp/dspi_1.0-1_*.ipk
```

---

# Verify Installation

Verify the application.

```bash
which dspiw25qxx
```

or

```bash
ls -l /usr/bin/dspiw25qxx
```

Expected:

```text
/usr/bin/dspiw25qxx
```

---

# Running the Application

Execute:

```bash
dspiw25qxx
```

or

```bash
/usr/bin/dspiw25qxx
```

---

# SPI Configuration

Ensure the SPI driver is enabled.

Verify SPI devices.

```bash
ls /dev/spidev*
```

Expected output:

```text
/dev/spidev0.0
```

Verify kernel module.

```bash
lsmod | grep spidev
```

Kernel messages.

```bash
dmesg | grep spi
```

---

# Install SPI Utilities

Install useful SPI packages.

```bash
opkg update
```

```bash
opkg install kmod-spi-dev
```

```bash
opkg install python3-spidev
```

If available:

```bash
opkg install spidev-test
```

---

# Verify SPI Communication

Check the SPI node.

```bash
ls /dev/spidev*
```

Display kernel messages.

```bash
dmesg | grep spi
```

Run the application.

```bash
dspiw25qxx
```

---

# Package Management

List installed packages.

```bash
opkg list-installed | grep dspi
```

Remove package.

```bash
opkg remove dspi
```

Reinstall.

```bash
opkg install /tmp/dspi_1.0-1_*.ipk
```

---

# Useful OpenWrt Build Commands

| Command | Description |
|----------|-------------|
| `make menuconfig` | Configure packages |
| `make package/dspi/compile V=s` | Build package |
| `make package/dspi/clean` | Clean package |
| `make package/dspi/{clean,compile} V=s` | Clean and rebuild |
| `make V=s` | Build complete firmware |
| `make package/index` | Update package index |

---

# Troubleshooting

## Package Not Visible

Run:

```bash
make menuconfig
```

Verify that the package appears under the appropriate category.

---

## Build Failure

Clean and rebuild.

```bash
make package/dspi/clean
```

```bash
make package/dspi/compile V=s
```

---

## Package Not Installed

Check:

```bash
opkg list-installed | grep dspi
```

---

## SPI Device Missing

Verify:

```bash
ls /dev/spidev*
```

Check kernel messages.

```bash
dmesg | grep spi
```

---

## Permission Denied

Run:

```bash
chmod +x /usr/bin/dspiw25qxx
```

or

```bash
/usr/bin/dspiw25qxx
```

---

# References

- OpenWrt SDK Documentation
- OpenWrt Package Developer Guide
- Linux Kernel SPI Documentation
- Winbond W25Qxx Datasheet
- Embedded Linux Development Best Practices

---

# Author

**Dhawal Umesh Lad**

Embedded Linux Developer

### Expertise

- Embedded Linux
- OpenWrt
- Yocto Project
- BSP Development
- Device Driver Development
- SPI
- I²C
- UART
- CAN
- GPIO
- Ethernet
- PCIe

---

# License

This project is distributed under the **MIT License**.

Refer to the **LICENSE** file for additional information.
