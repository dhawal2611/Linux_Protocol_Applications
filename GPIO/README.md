# GPIO Application for Linux

Simple Linux GPIO application written in C to **export**, **configure**, **read**, **write**, and **unexport** GPIOs using the Linux **sysfs GPIO interface**.

---

# Table of Contents

* [Overview](#overview)
* [Project Structure](#project-structure)
* [GPIO Configuration](#gpio-configuration)
* [Compiling the Application](#compiling-the-application)
* [Running the Application](#running-the-application)
* [Linux GPIO Operations](#linux-gpio-operations)
* [Changing GPIO Number](#changing-gpio-number)
* [Example Execution](#example-execution)

---

# Overview

This project demonstrates basic GPIO control in Linux userspace through the **sysfs interface**.

The application can perform:

* Export GPIO
* Configure GPIO direction
* Set GPIO High
* Set GPIO Low
* Read GPIO state
* Unexport GPIO

---

# Project Structure

```text
GPIO/
├── Makefile
├── dgpio.c
├── dgpio.h
└── README.md
```

---

# GPIO Configuration

GPIO number can be configured in **dgpio.h**

Open the file:

```bash
vi dgpio.h
```

Update:

```c
#define GPIO_NUM 1
```

Replace **1** with the required GPIO number.

Example:

```c
#define GPIO_NUM 24
```

This configures the application to operate on GPIO24.

---

# Compiling the Application

The project uses a simple Makefile.

Compile using:

```bash
make
```

Expected output:

```bash
dhawal@7H1J9X2-Desk:~/Linux_Protocol_Applications/GPIO$ make

gcc -Wall -Wextra -O2 -c dgpio.c -o dgpio.o

gcc -Wall -Wextra -O2 -o dgpio dgpio.o

dhawal@7H1J9X2-Desk:~/Linux_Protocol_Applications/GPIO$
```

Generated files:

```text
dgpio
dgpio.o
```

---

# Running the Application

Execute:

```bash
./dgpio
```

Example:

```bash
./dgpio
```

The application performs GPIO operations according to the implemented logic.

---

# Linux GPIO Operations

Linux provides GPIO access through:

```bash
/sys/class/gpio/
```

---

## 1. Export GPIO

Export GPIO24.

```bash
echo 24 > /sys/class/gpio/export
```

Purpose:

Creates GPIO control directory.

Result:

```bash
/sys/class/gpio/gpio24/
```

---

## 2. Configure Direction

Set GPIO as Output.

```bash
echo out > /sys/class/gpio/gpio24/direction
```

Set GPIO as Input.

```bash
echo in > /sys/class/gpio/gpio24/direction
```

Possible values:

| Value | Description |
| ----- | ----------- |
| in    | Input GPIO  |
| out   | Output GPIO |

---

## 3. Set GPIO High

```bash
echo 1 > /sys/class/gpio/gpio24/value
```

Output voltage becomes High.

---

## 4. Set GPIO Low

```bash
echo 0 > /sys/class/gpio/gpio24/value
```

Output voltage becomes Low.

---

## 5. Read GPIO State

```bash
cat /sys/class/gpio/gpio24/value
```

Example:

```bash
1
```

or

```bash
0
```

---

## 6. Unexport GPIO

Release GPIO resources.

```bash
echo 24 > /sys/class/gpio/unexport
```

GPIO directory is removed.

```bash
gpio24/
```

no longer exists.

---

# Changing GPIO Number

Modify the macro in **dgpio.h**

```c
#define GPIO_NUM 1
```

Example:

```c
#define GPIO_NUM 17
```

or

```c
#define GPIO_NUM 24
```

No code modification is required elsewhere.

Rebuild:

```bash
make clean
make
```

---

# Example Execution

Export GPIO24

```bash
echo 24 > /sys/class/gpio/export
```

Configure as output

```bash
echo out > /sys/class/gpio/gpio24/direction
```

Set HIGH

```bash
echo 1 > /sys/class/gpio/gpio24/value
```

Read GPIO

```bash
cat /sys/class/gpio/gpio24/value
```

Set LOW

```bash
echo 0 > /sys/class/gpio/gpio24/value
```

Unexport GPIO

```bash
echo 24 > /sys/class/gpio/unexport
```

---

# Notes

The **sysfs GPIO interface** has been deprecated in newer Linux kernels.

For modern Linux systems, it is recommended to use the **GPIO Character Device Interface (libgpiod)**.

However, the sysfs interface remains widely used in embedded Linux systems and older BSPs.
