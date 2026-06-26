# Yocto Integration

This document describes how to integrate the I2C userspace application into a Yocto Project build.

The objective is to:

* Compile the application within Yocto
* Package the executable
* Include it in the target image
* Enable Linux I2C userspace interfaces
* Install I2C utilities
* Verify communication on the target

---

# Yocto Prerequisites

The following knowledge is assumed.

* BitBake
* Recipes
* Layers
* Device Tree
* Linux Kernel Configuration

Supported Yocto Releases:

* Dunfell
* Gatesgarth
* Hardknott
* Kirkstone
* Langdale
* Mickledore
* Scarthgap

---

# Project Structure

Example custom layer.

```text
meta-myapps/

├── conf
│   └── layer.conf
│
└── recipes-i2c
    │
    └── di2c
        │
        ├── di2c.bb
        └── files
            ├── di2c.c
            ├── di2c.h
            ├── di2cAHT20.c
            ├── di2cAHT20.h
            └── Makefile

```

---

# Creating Recipe

Recipe location.

```bash
meta-myapps/recipes-i2c/di2c/di2c.bb
```

---

## Example Recipe

```bitbake

SUMMARY = "I2C Userspace Application"

DESCRIPTION = "Generic Linux I2C AHT20 Application"

LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"



SRC_URI = "\
file://di2c.c \
file://di2c.h \
file://di2cAHT20.c \
file://di2cAHT20.h \
file://Makefile \
"



S = "${WORKDIR}"



do_compile()
{
    oe_runmake
}



do_install()
{
    install -d ${D}${bindir}

    install -m 0755 \
        di2c \
        ${D}${bindir}
}



FILES:${PN} += "${bindir}/di2c"

```

---

# Adding Layer

Edit:

```bash
build/conf/bblayers.conf
```

Add:

```bitbake

BBLAYERS += "\
${TOPDIR}/../meta-myapps \
"

```

---

# Add Application to Image

There are two common approaches.

---

## Method 1

local.conf

```bitbake

IMAGE_INSTALL:append = " di2c"

```

---

## Method 2

Custom image recipe.

Example:

```bitbake

IMAGE_INSTALL += "\
di2c \
"

```

---

# I2C Userspace Support

For Linux userspace applications,

the character interface is required.

Kernel option.

```text
CONFIG_I2C_CHARDEV=y
```

This creates:

```bash
/dev/i2c-0
/dev/i2c-1
```

---

## Verify

Target

```bash
ls /dev/i2c*
```

Example

```text
/ dev/i2c-0
/ dev/i2c-1
```

---

# i2c-tools Package

Linux validation utilities should also be installed.

Add

```bitbake

IMAGE_INSTALL:append = " i2c-tools"

```

Utilities included.

```bash

i2cdetect

i2cdump

i2cset

i2cget

i2ctransfer

```

---

# Kernel Modules

Many platforms build these drivers directly into the kernel.

Some BSPs may build them as modules.

Typical modules.

```text

i2c-dev


Platform Driver

```

Examples.

---

## BCM2835

```text
i2c-bcm2835
```

---

## i.MX

```text
i2c-imx
```

---

## Marvell CN9130

```text
i2c-mv64xxx
```

---

## STM32

```text
i2c-stm32
```

---

# Module Autoload

Only required if the drivers are built as modules.

Example.

```bitbake

KERNEL_MODULE_AUTOLOAD += "\
i2c-dev \
"

```

---

## Important Note

Do not blindly add.

```bitbake
KERNEL_MODULE_AUTOLOAD += "i2c-bcm2835"
```

unless using a BCM2835 based platform.

---

Autoload entries are BSP dependent.

---

# Device Tree Requirements

The I2C controller must be enabled.

Example.

```dts

&i2c1 {

        status = "okay";

        clock-frequency = <400000>;

};

```

---

# AHT20 Device Tree Example

Optional.

```dts

&aht20 {

        compatible = "aosong,aht20";

        reg = <0x38>;

};

```

---

Userspace applications typically do not require a DT node.

Only the I2C controller must be enabled.

---

# Kernel Configuration

Verify.

```bash
bitbake -c menuconfig virtual/kernel
```

---

Required options.

```text

CONFIG_I2C=y

CONFIG_I2C_CHARDEV=y

CONFIG_I2C_HELPER_AUTO=y

```

---

Platform drivers.

Examples.

```text

CONFIG_I2C_IMX=y


CONFIG_I2C_MV64XXX=y


CONFIG_I2C_BCM2835=y


CONFIG_I2C_STM32=y

```

Only enable the controller used by your hardware.

---

# Building

Compile image.

```bash

bitbake core-image-minimal

```

or

```bash

bitbake my-image

```

---

# Deploying

Flash image.

Boot target.

Verify.

```bash

which di2c

```

Expected.

```text

/usr/bin/di2c

```

---

# Verify Application

Check.

```bash

ls -l /usr/bin/di2c

```

---

# Verify I2C Bus

List.

```bash

ls /dev/i2c*
```

---

Scan.

```bash

i2cdetect -y 1
```

---

# Read AHT20 Sensor Data

The AHT20 requires a measurement trigger before data can be read.

The complete sequence **must be executed as a single command**.

```bash

i2ctransfer -y 1 \
w3@0x38 0xAC 0x33 0x00 && \
sleep 0.1 && \
i2ctransfer -y 1 r7@0x38

```

---

# Troubleshooting

---

## No Device Node

Problem

```text
/dev/i2c-1 missing
```

Possible Causes

* CONFIG_I2C_CHARDEV disabled
* Driver not loaded
* Device Tree disabled

---

## No Slave Detected

Problem

```bash
i2cdetect -y 1
```

shows

```text
--
```

Check.

* Pullups
* Wiring
* Sensor power
* DT configuration

---

## Recipe Not Found

Problem

```text
Nothing PROVIDES di2c
```

Verify.

```bash
bitbake-layers show-recipes
```

---

# Recommended Configuration

For most embedded Linux systems.

```bitbake

IMAGE_INSTALL:append = "\
i2c-tools \
di2c \
"

```

Kernel.

```text

CONFIG_I2C=y

CONFIG_I2C_CHARDEV=y

```

Device Tree.

```dts

&i2c1 {

status = "okay";

};

```

---

# Summary

Integrating the I2C userspace application into Yocto is straightforward.

The essential requirements are:

* I2C controller enabled
* CONFIG_I2C_CHARDEV enabled
* i2c-tools installed
* di2c recipe added
* Application included in IMAGE_INSTALL
* Device Tree configured correctly

Following these steps ensures that the application is automatically built, packaged, deployed, and ready for validation on the target hardware.
