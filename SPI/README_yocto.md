# README - Building the SPI Utility in Yocto

This document describes how to integrate, build, and deploy the **dspiw25qxx** SPI utility in a Yocto Project environment.

---

# Table of Contents

- Overview
- Prerequisites
- Directory Structure
- Creating a Custom Layer
- Adding the Layer
- Recipe Structure
- Files Required
- Recipe Integration
- Raspberry Pi Configuration
- Platform Specific SPI Configuration
- Building the Recipe
- Building the Complete Image
- Deploying the Image
- Running the Application
- Verifying SPI
- Useful BitBake Commands
- Troubleshooting

---

# Overview

The **dspiw25qxx** application is a userspace SPI utility for communicating with Winbond W25Qxx SPI Flash devices using the Linux **spidev** driver.

The application can be integrated into any Yocto image by adding the supplied BitBake recipe.

---

# Prerequisites

Ensure your Yocto environment is already configured.

Typical environment:

- Poky
- BitBake
- meta-openembedded
- meta-custom
- GCC Toolchain
- Linux Kernel with SPI support

---

# Project Directory

```text
spi-utility/
├── dspi_0.1.bb
├── files
│   ├── dspi.c
│   ├── dspi.h
│   ├── dspiw25qxx.c
│   ├── dspiw25qxx.h
│   ├── Makefile
│   └── README.md
├── Makefile
├── README.md
├── README_OpenWRT.md
└── README_yocto.md
```

---

# Create a Custom Layer

If a custom layer does not already exist, create one.

```bash
cd poky

bitbake-layers create-layer ../meta-custom
```

---

# Add the Layer

Register the layer with Yocto.

```bash
bitbake-layers add-layer ../meta-custom
```

Verify:

```bash
bitbake-layers show-layers
```

Example:

```text
meta-custom
meta-openembedded
meta-raspberrypi
poky
```

---

# Recipe Directory Structure

Create the recipe directory.

```bash
mkdir -p \
meta-custom/recipes-apps/dspi/files
```

The final directory should look like:

```text
meta-custom
└── recipes-apps
    └── dspi
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

# Files Required

Copy the following files into the recipe.

### Recipe

```
dspi_0.1.bb
```

### Source Files

```
dspi.c
dspi.h
dspiw25qxx.c
dspiw25qxx.h
Makefile
```

`README.md` is optional and not required for compilation.

---

# Copy Files

Example:

```bash
cp dspi_0.1.bb \
meta-custom/recipes-apps/dspi/

cp files/* \
meta-custom/recipes-apps/dspi/files/
```

---

# Verify the Recipe

Check whether BitBake detects the recipe.

```bash
bitbake-layers show-recipes | grep dspi
```

Expected output:

```text
dspi:
    meta-custom
```

---

# Raspberry Pi SPI Configuration

Append the following to **build/conf/local.conf**.

## Enable SPI Hardware

```conf
ENABLE_SPI_BUS = "1"
```

---

## Enable SPI Device Tree Overlay

Single Chip Select:

```conf
RPI_EXTRA_CONFIG:append = "\ndtoverlay=spi0-1cs\n"
```

Two Chip Selects:

```conf
RPI_EXTRA_CONFIG:append = "\ndtoverlay=spi0-2cs\n"
```

---

## Install SPI Driver

```conf
IMAGE_INSTALL:append = " kernel-module-spidev"
```

Automatically load the driver:

```conf
KERNEL_MODULE_AUTOLOAD:append = " spidev"
```

---

## Install SPI Utilities

```conf
IMAGE_INSTALL:append = " spitools python3-spidev"
IMAGE_INSTALL:append = " spidev-test"
```

---

## Install the Application

```conf
IMAGE_INSTALL:append = " dspi"
```

---

## Example local.conf

```conf
MACHINE = "raspberrypi4-64"

ENABLE_SPI_BUS = "1"

RPI_EXTRA_CONFIG:append = "\ndtoverlay=spi0-1cs\n"

IMAGE_INSTALL:append = " kernel-module-spidev"

KERNEL_MODULE_AUTOLOAD:append = " spidev"

IMAGE_INSTALL:append = " spitools python3-spidev"

IMAGE_INSTALL:append = " spidev-test"

IMAGE_INSTALL:append = " dspi"
```

### Raspberry Pi SPI Pin Configuration (SPI0)

The following table shows the Raspberry Pi SPI0 pin mapping along with the corresponding Winbond **W25Qxx SPI Flash** connections.

| Raspberry Pi Physical Pin | GPIO | SPI Signal | W25Qxx Flash Pin | Description |
|---------------------------|------|------------|------------------|-------------|
| Pin 19 | GPIO10 | MOSI | DI (MOSI) | Master Out Slave In |
| Pin 21 | GPIO9 | MISO | DO (MISO) | Master In Slave Out |
| Pin 23 | GPIO11 | SCLK | CLK | SPI Clock |
| Pin 24 | GPIO8 | CE0 | CS | Chip Select (Active Low) |
| Pin 26 | GPIO7 | CE1 | — | Optional Chip Select 1 (for second SPI device) |
| Pin 1 | 3.3V | Power | VCC | 3.3V Supply |
| Pin 6 | GND | Ground | GND | Ground Reference |

> **Note:** Raspberry Pi GPIO operates at **3.3V logic levels**. Do **not** connect 5V SPI devices directly without using an appropriate level shifter.

---

# Platform-Specific SPI Configuration

## Raspberry Pi

Enable SPI using:

- `ENABLE_SPI_BUS`
- `RPI_EXTRA_CONFIG`
- `kernel-module-spidev`

---

## NXP i.MX

Enable SPI in Device Tree.

Example:

```dts
&ecspi1 {
    status = "okay";
};
```

Enable spidev.

```dts
spidev@0 {
    compatible = "spidev";
    reg = <0>;
};
```

Kernel:

```text
CONFIG_SPI=y
CONFIG_SPI_MASTER=y
CONFIG_SPI_SPIDEV=y
```

---

## TI Sitara

Enable SPI controller.

```dts
&spi0 {
    status = "okay";
};
```

---

## STM32MP1

```dts
&spi1 {
    status = "okay";
};
```

---

## Marvell CN9130

```dts
&spi0 {
    status = "okay";
};
```

Enable:

```dts
spidev@0 {
    compatible = "spidev";
};
```

---

## Generic Embedded Linux

Verify:

- SPI controller enabled
- Device Tree contains spidev
- CONFIG_SPI_SPIDEV enabled
- /dev/spidevX.Y available

---

# Build Only the Recipe

```bash
bitbake dspi
```

---

# Clean the Recipe

```bash
bitbake -c clean dspi
```

or

```bash
bitbake -c cleansstate dspi
```

---

# Build the Complete Image

Example:

```bash
bitbake core-image-base
```

or

```bash
bitbake core-image-minimal
```

---

# Locate the Binary

After compilation:

```text
tmp/work/<machine>/dspi/0.1-r0/image/usr/bin/dspiw25qxx
```

Example:

```text
tmp/work/aarch64-poky-linux/dspi/0.1-r0/image/usr/bin/dspiw25qxx
```

---

# Flash the Image

Example:

```bash
bmaptool copy core-image-base.wic.bz2 /dev/sdX
```

or

```bash
dd if=core-image-base.wic of=/dev/sdX bs=4M status=progress

sync
```

---

# Verify Installation

Login to the target.

Verify binary:

```bash
which dspiw25qxx
```

or

```bash
ls -l /usr/bin/dspiw25qxx
```

Run:

```bash
dspiw25qxx
```

---

# Verify SPI

Check SPI devices.

```bash
ls /dev/spidev*
```

Expected:

```text
/dev/spidev0.0
```

If the `spi0-2cs` overlay is enabled, both chip-select devices should be available:

```text
/dev/spidev0.0
/dev/spidev0.1
```

Verify module.

```bash
lsmod | grep spidev
```

Kernel messages.

```bash
dmesg | grep spi
```

Run the Linux SPI test utility.

```bash
spidev_test
```

If the `spidev-test` utility is installed, run:

```bash
spidev_test -D /dev/spidev0.0
```

Run Python test.

```bash
python3 -c "import spidev"
```

Finally execute the application.

```bash
dspiw25qxx
```

---

# Useful BitBake Commands

| Command | Description |
|----------|-------------|
| `bitbake dspi` | Build recipe |
| `bitbake -c clean dspi` | Clean recipe |
| `bitbake -c cleansstate dspi` | Remove cached build |
| `bitbake core-image-base` | Build image |
| `bitbake-layers show-layers` | Show configured layers |
| `bitbake-layers show-recipes` | Show recipes |
| `bitbake -e dspi` | Show recipe environment |

---

# Troubleshooting

### Recipe not found

```bash
bitbake-layers show-recipes | grep dspi
```

---

### SPI device missing

```bash
ls /dev/spidev*
```

Check:

- SPI enabled in Device Tree
- `spidev` driver loaded
- SPI overlay enabled (Raspberry Pi)

---

### Module not loaded

```bash
modprobe spidev
```

Verify:

```bash
lsmod | grep spidev
```

---

### Application not installed

Verify:

```conf
IMAGE_INSTALL:append = " dspi"
```

Rebuild the image.

---

### Permission denied

Run:

```bash
sudo dspiw25qxx
```

or

```bash
chmod +x /usr/bin/dspiw25qxx
```

---

# References

- Yocto Project Documentation
- BitBake User Manual
- Linux Kernel SPI Documentation
- Raspberry Pi Documentation
- Winbond W25Qxx Datasheet
- NXP SPI Controller Documentation

---

# Author

**Dhawal Umesh Lad**

Embedded Linux Developer

**Expertise**

- Embedded Linux
- Yocto Project
- OpenWRT
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
