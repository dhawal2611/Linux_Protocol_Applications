# I2C Communication in Linux and Yocto

<p align="center">
<img src="I2C_Communication.png" width="100%">
</p>

---

# Overview

This project demonstrates I2C communication in Linux and Yocto using a userspace application and an AHT20 temperature/humidity sensor.

Features:

- Generic Linux I2C APIs
- AHT20 Sensor Support
- Linux Userspace Application
- Yocto Integration
- AHT20 Validation
- Troubleshooting Guide
- Electrical Design Guidelines

---

# Directory Structure

```text
.

├── di2c.c
├── di2c.h
├── di2cAHT20.c
├── di2cAHT20.h
├── Makefile
├── README.md
├── I2C_Communication.png
└── docs/
```

---

# Build

```bash
make
```

Run:

```bash
sudo ./di2c
```

---

# Test AHT20

Find device:

```bash
i2cdetect -y 1
```

Read sensor:

```bash
i2ctransfer -y 1 \
w3@0x38 0xAC 0x33 0x00 && \
sleep 0.1 && \
i2ctransfer -y 1 r7@0x38
```

---

# Yocto Integration

Add package:

```bitbake
IMAGE_INSTALL:append = " i2c-tools di2c"
```

Enable userspace I2C:

```text
CONFIG_I2C=y
CONFIG_I2C_CHARDEV=y
```

Refer to:

`docs/10_Yocto_Integration.md`

---

# Documentation

| Document | Description |
|---------|-------------|
| docs/01_Overview.md | I2C Overview |
| docs/02_Frame_Format.md | Frame Format |
| docs/03_Start_Stop_Conditions.md | START/STOP Conditions |
| docs/04_Clock_Stretching.md | Clock Stretching |
| docs/05_Arbitration.md | Arbitration |
| docs/06_Electrical_Characteristics.md | Electrical Characteristics |
| docs/07_Advantages_Disadvantages.md | Advantages and Disadvantages |
| docs/08_Linux_Build.md | Linux Build |
| docs/09_AHT20_Testing.md | AHT20 Testing |
| docs/10_Yocto_Integration.md | Yocto Integration |
| docs/11_Troubleshooting.md | Troubleshooting |
| docs/12_References.md | References |

---

# Author

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

---

## Happy Learning !!

```
I2C makes embedded communication simple,
efficient and scalable.
```
