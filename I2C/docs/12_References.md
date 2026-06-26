# References

This document provides references to standards, specifications, datasheets, Linux documentation, and debugging resources that are useful for understanding, developing, and validating I2C-based embedded systems.

---

# I2C Specifications

The official I2C specification is maintained by **NXP Semiconductors**.

---

## UM10204

Title

```text id="7kwtfr"
I2C-bus Specification and User Manual
```

Document

```text id="dtx4mx"
UM10204
```

Published by

```text id="xv8yy7"
NXP Semiconductors
```

This document is considered the authoritative reference for:

* I2C Protocol
* Timing Requirements
* Arbitration
* Clock Stretching
* Electrical Characteristics
* Bus Capacitance
* High-Speed Modes

---

# Sensor Datasheets

---

## AHT20

Manufacturer

```text id="t7ed61"
ASAIR
```

Features

* Temperature Measurement
* Relative Humidity Measurement
* I2C Interface
* Factory Calibration
* Low Power Consumption

Default Address

```text id="sd9rlx"
0x38
```

Useful Sections

* Command Set
* Measurement Timing
* Status Register
* CRC Calculation
* Electrical Specifications

---

# Linux Documentation

Linux kernel documentation provides extensive information regarding I2C subsystem implementation.

---

## Linux I2C Subsystem

Location

```text id="zqvhnf"
Documentation/i2c/
```

Topics covered

* Adapter Drivers
* Client Drivers
* Userspace API
* SMBus Support
* Debugging

---

## Character Device Interface

Kernel Configuration

```text id="9lywsk"
CONFIG_I2C_CHARDEV
```

Device Nodes

```text id="0fzdu5"
/dev/i2c-0

/dev/i2c-1
```

---

# Linux Utilities

The following utilities are provided by **i2c-tools**.

---

## i2cdetect

Purpose

Detect slave devices.

Example

```bash id="2v64fi"
i2cdetect -y 1
```

---

## i2cget

Purpose

Read register values.

Example

```bash id="jlwm7r"
i2cget -y 1 0x38 0x00
```

---

## i2cset

Purpose

Write register values.

Example

```bash id="w2a7g0"
i2cset -y 1 0x38 0x00 0x01
```

---

## i2ctransfer

Purpose

Raw I2C transactions.

Example

```bash id="tqv8xm"
i2ctransfer -y 1 \
w3@0x38 0xAC 0x33 0x00 && \
sleep 0.1 && \
i2ctransfer -y 1 r7@0x38
```

Recommended for

* Sensor Validation
* EEPROM Access
* Debugging
* Driver Verification

---

# Yocto Documentation

Official Yocto documentation should be referenced when integrating userspace applications.

Topics

* Recipes
* Layers
* Images
* SDK
* Kernel Configuration

Useful commands

```bash id="9r9x4n"
bitbake-layers show-layers
```

```bash id="0uqfcm"
bitbake-layers show-recipes
```

```bash id="2p1wta"
bitbake -e
```

---

# Oscilloscope Usage

Oscilloscopes are useful for analyzing signal quality.

Verify

* SDA Rise Time
* SDA Fall Time
* SCL Duty Cycle
* Clock Stretching
* ACK/NACK
* Bus Idle State

Expected Idle

```text id="g9itxe"
SDA = HIGH

SCL = HIGH
```

---

# Logic Analyzer Usage

Logic analyzers provide protocol-level visibility.

Recommended Observations

* START Condition
* STOP Condition
* Repeated START
* Address Phase
* ACK/NACK
* Data Bytes
* Arbitration

Common Tools

* Saleae Logic
* DSLogic
* Sigrok
* PulseView

---

# Recommended Reading

Suggested topics for further study.

---

## SMBus

Differences from I2C.

Topics

* PEC
* Timeouts
* Alert Signals

---

## PMBus

Power Management Bus.

Applications

* PMIC
* Server Boards
* Industrial Systems

---

## MIPI I3C

Successor to I2C.

Features

* Dynamic Address Assignment
* Higher Throughput
* Reduced Power Consumption

---

# Useful Linux Commands

List adapters.

```bash id="2pm8ts"
i2cdetect -l
```

List devices.

```bash id="36s5y1"
ls /dev/i2c*
```

Check kernel messages.

```bash id="7nbm2s"
dmesg | grep i2c
```

Check loaded modules.

```bash id="0vbv6l"
lsmod | grep i2c
```

---

# Suggested Validation Sequence

```text id="4xjv6v"

Power Verification
        │
        ▼

Kernel Verification
        │
        ▼

Device Tree Verification
        │
        ▼

Bus Detection
        │
        ▼

Slave Detection
        │
        ▼

Raw I2C Transfer
        │
        ▼

Userspace Application
        │
        ▼

Oscilloscope Validation
        │
        ▼

Production Testing

```

---

# Author

```text id="e5dwz7"
Dhawal Umesh Lad
```

---

# License

```text id="0pr3zu"
MIT License
```

---

# Summary

The references listed in this document provide a solid foundation for learning, implementing, debugging, and validating I2C communication in embedded Linux and Yocto-based environments.

For protocol details, always consult the official I2C specification. For sensor-specific behavior, refer to the corresponding device datasheets. Combining software tools, oscilloscopes, and logic analyzers significantly improves debugging efficiency and overall system reliability.
