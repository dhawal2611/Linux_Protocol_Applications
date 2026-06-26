# Testing AHT20 Sensor Using Linux I2C Utilities

Before executing the userspace application, it is highly recommended to verify that the Linux kernel can successfully communicate with the sensor.

Linux provides several utilities that are part of the **i2c-tools** package.

These utilities allow users to:

* Detect I2C devices
* Read registers
* Write registers
* Transfer raw bytes
* Debug communication issues

---

# Software Requirements

Install i2c-tools.

## Ubuntu / Debian

```bash
sudo apt update
sudo apt install i2c-tools
```

---

## Verify Installation

```bash
i2cdetect -V
```

Example

```text
i2cdetect version 4.3
```

---

# Verify Available I2C Buses

Linux exposes I2C buses as character devices.

Check available buses.

```bash
ls /dev/i2c*
```

Example

```text
/dev/i2c-0
/dev/i2c-1
```

---

# Identify Bus Number

List all available adapters.

```bash
i2cdetect -l
```

Example

```text
i2c-0   i2c      mv64xxx_i2c adapter
i2c-1   i2c      DesignWare I2C adapter
```

---

# Detect Connected Devices

Scan the bus for slave devices.

---

## Get Slave Address

```bash
i2cdetect -y 1
```

Example Output

```text
     0 1 2 3 4 5 6 7 8 9 A B C D E F

00:          -- -- -- -- -- -- -- --

10: -- -- -- -- -- -- -- -- -- -- --

20: -- -- -- -- -- -- -- -- -- -- --

30: -- -- -- -- -- -- -- -- 38 -- --

40: -- -- -- -- -- -- -- -- -- -- --

50: -- -- -- -- -- -- -- -- -- -- --

60: -- -- -- -- -- -- -- -- -- -- --

70: -- -- -- -- -- -- -- --
```

---

Expected Device

```text
0x38
```

AHT20 typically responds at address:

```text
0x38
```

---

# Read AHT20 Sensor Data

The AHT20 requires a measurement to be triggered before data can be read.

The entire sequence **must be executed as a single command**.

The sequence consists of:

1. Trigger Measurement
2. Wait for Conversion
3. Read Measurement Data

---

## Trigger Conversion and Read Data

```bash
i2ctransfer -y 1 \
w3@0x38 0xAC 0x33 0x00 && \
sleep 0.1 && \
i2ctransfer -y 1 r7@0x38
```

---

## Command Description

### Trigger Measurement

```bash
w3@0x38 0xAC 0x33 0x00
```

Meaning:

Write 3 bytes to slave address.

```text
0x38
```

Bytes sent:

| Byte | Description         |
| ---- | ------------------- |
| 0xAC | Measurement Command |
| 0x33 | Configuration Byte  |
| 0x00 | Reserved Byte       |

---

### Wait

```bash
sleep 0.1
```

Waits

```text
100 ms
```

This delay allows the sensor to complete:

* Temperature Conversion
* Humidity Conversion

---

### Read Data

```bash
i2ctransfer -y 1 r7@0x38
```

Read

```text
7 bytes
```

from the sensor.

---

# Example Output

```text
0x18
0x80
0x3A
0x1D
0x7B
0x2A
0x00
```

---

# Data Packet Format

AHT20 returns seven bytes.

Example

```text
Byte0

Status


Byte1

Humidity[19:12]


Byte2

Humidity[11:4]


Byte3

Humidity[3:0]

Temperature[19:16]


Byte4

Temperature[15:8]


Byte5

Temperature[7:0]


Byte6

CRC
```

---

# Checking Sensor Status

Status byte.

```text
Byte0
```

Busy bit.

```text
Bit 7
```

---

## Busy

```text
1
```

Sensor still measuring.

---

## Ready

```text
0
```

Measurement completed.

---

# Linux Validation Steps

Recommended sequence.

---

## Step 1

Verify bus.

```bash
ls /dev/i2c*
```

---

## Step 2

List adapters.

```bash
i2cdetect -l
```

---

## Step 3

Scan bus.

```bash
i2cdetect -y 1
```

---

## Step 4

Read sensor.

```bash
i2ctransfer -y 1 \
w3@0x38 0xAC 0x33 0x00 && \
sleep 0.1 && \
i2ctransfer -y 1 r7@0x38
```

---

## Step 5

Execute application.

```bash
sudo ./di2c
```

---

# Common Errors

---

## Device Not Found

Output

```text
No 0x38 detected
```

Check:

* Wiring
* Pull-ups
* Bus number

---

## Permission Denied

Error

```text
Permission denied
```

Solution

```bash
sudo i2cdetect -y 1
```

---

## Sensor Busy

Bit7 remains set.

Increase delay.

Example

```bash
sleep 0.2
```

---

# Recommended Test Flow

```text
Power On

   │

   ▼


Detect Device

i2cdetect


   │

   ▼


Trigger Conversion

0xAC 0x33 0x00


   │

   ▼


Wait 100 ms


   │

   ▼


Read 7 Bytes


   │

   ▼


Validate Data


   │

   ▼


Run Userspace Application
```

---

# Summary

Testing the AHT20 using Linux built-in I2C utilities is an effective way to validate hardware connectivity and verify sensor communication before running custom userspace applications.

The recommended approach is to execute the complete trigger–delay–read sequence as a single command, ensuring that the sensor has sufficient time to complete measurements and provide valid data.
