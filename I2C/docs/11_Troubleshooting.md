# Troubleshooting

I2C communication issues can arise from hardware problems, kernel configuration issues, driver problems, device tree misconfigurations, or application-level bugs.

This guide presents a systematic approach to identify and resolve common I2C issues.

---

# Troubleshooting Methodology

When debugging I2C issues, follow the steps below.

```text
Power Verification
        │
        ▼
Bus Verification
        │
        ▼
Kernel Verification
        │
        ▼
Device Tree Verification
        │
        ▼
Slave Detection
        │
        ▼
Read/Write Validation
        │
        ▼
Application Testing
        │
        ▼
Signal Analysis
```

---

# Hardware Verification

---

## Verify Sensor Power

Measure supply voltage.

Example

```text
VDD = 3.3V
```

Acceptable range

```text
3.0V ~ 3.6V
```

---

## Verify Ground Connection

Check continuity.

```text
Master GND
       │
       └──── Sensor GND
```

---

## Verify SDA

Check continuity.

```text
Master SDA
        │
        └──── Slave SDA
```

---

## Verify SCL

```text
Master SCL
        │
        └──── Slave SCL
```

---

## Verify Pullup Resistors

Recommended.

```text
4.7kΩ
```

Typical values.

| Speed    | Pullup |
| -------- | ------ |
| 100 kbps | 4.7kΩ  |
| 400 kbps | 2.2kΩ  |
| 1 Mbps   | 1.8kΩ  |

---

# Linux Verification

---

## Verify Device Nodes

Check.

```bash
ls /dev/i2c*
```

Expected.

```text
/dev/i2c-0
/dev/i2c-1
```

---

## No Device Nodes

Problem

```text
No such file
```

Possible causes.

* Driver missing
* CONFIG_I2C_CHARDEV disabled
* DT disabled

---

## Verify Adapters

```bash
i2cdetect -l
```

Example

```text
i2c-0

i2c-1
```

---

# Kernel Verification

---

## Verify Configuration

```bash
zcat /proc/config.gz | grep I2C
```

Expected.

```text
CONFIG_I2C=y

CONFIG_I2C_CHARDEV=y
```

---

## Verify Modules

```bash
lsmod | grep i2c
```

Example

```text
i2c_dev

i2c_mv64xxx

i2c_imx
```

---

## Load Module

```bash
modprobe i2c-dev
```

---

# Device Tree Verification

Check DT.

Example.

```dts
&i2c1 {

status="okay";

clock-frequency=<400000>;

};
```

---

## Verify Runtime

```bash
dmesg | grep i2c
```

Example.

```text
i2c i2c-1: Added multiplexed i2c bus
```

---

# Slave Detection Issues

---

## Device Not Detected

Command.

```bash
i2cdetect -y 1
```

Output.

```text
--
```

instead of

```text
38
```

---

## Possible Causes

### Wrong Bus

Verify.

```bash
i2cdetect -l
```

---

### Wiring Error

Check.

* SDA
* SCL
* GND
* VCC

---

### Pullups Missing

Measure.

```text
SDA idle = HIGH

SCL idle = HIGH
```

---

### Sensor Powered Off

Measure voltage.

---

# Bus Busy

Problem.

```text
UU
```

appears.

Example.

```text
30: -- -- -- -- -- -- -- -- UU
```

Meaning.

Kernel driver already owns device.

---

## Check Driver

```bash
ls /sys/bus/i2c/devices/
```

---

## Remove Driver

Example.

```bash
rmmod aht20
```

---

# AHT20 Issues

---

## Sensor Busy

Bit7 set.

Increase delay.

Example.

```bash
sleep 0.2
```

---

## Wrong Data

Example.

```text
0xFF

0xFF

0xFF
```

Possible causes.

* Communication issue
* Timing problem
* Sensor reset required

---

## Reset Sensor

Send soft reset.

```bash
i2ctransfer -y 1 w1@0x38 0xBA
```

Wait.

```bash
sleep 0.05
```

Retry measurement.

---

# AHT20 Validation

---

## Step 1

Detect device.

```bash
i2cdetect -y 1
```

Expected.

```text
38
```

---

## Step 2

Trigger conversion.

```bash
i2ctransfer -y 1 \
w3@0x38 0xAC 0x33 0x00 && \
sleep 0.1 && \
i2ctransfer -y 1 r7@0x38
```

---

## Step 3

Run application.

```bash
sudo ./di2c
```

---

# Yocto Troubleshooting

---

## Recipe Missing

Error.

```text
Nothing PROVIDES di2c
```

Check.

```bash
bitbake-layers show-recipes
```

---

## Layer Missing

Verify.

```bash
bitbake-layers show-layers
```

---

## Application Missing

Check image.

```bash
which di2c
```

Expected.

```text
/usr/bin/di2c
```

---

# Build Failures

---

## GCC Missing

Error.

```text
gcc not found
```

Install.

```bash
sudo apt install gcc
```

---

## Make Missing

```bash
sudo apt install make
```

---

## Header Errors

Check.

```bash
ls
```

Expected.

```text
di2c.c

di2c.h

di2cAHT20.c

di2cAHT20.h
```

---

# Signal Analysis

Recommended tools.

---

## Oscilloscope

Observe.

* SDA
* SCL

---

## Logic Analyzer

Verify.

* START
* ACK
* STOP

---

## Bus Idle

Expected.

```text
SDA = HIGH

SCL = HIGH
```

---

# Recommended Debug Sequence

```text
Power
 │
 ▼
Pullups
 │
 ▼
Bus Detection
 │
 ▼
Kernel
 │
 ▼
DT
 │
 ▼
i2cdetect
 │
 ▼
i2ctransfer
 │
 ▼
Application
 │
 ▼
Logic Analyzer
```

---

# Summary

Most I2C issues are related to hardware connectivity, pull-up resistor selection, incorrect device tree configuration, missing kernel options, or application timing problems.

Following a structured debugging approach significantly reduces troubleshooting time and helps quickly isolate faults in Linux and Yocto-based embedded systems.
