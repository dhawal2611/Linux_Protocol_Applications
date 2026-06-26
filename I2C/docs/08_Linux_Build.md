# Building on Generic Linux System

This document describes how to build, compile, and execute the I2C userspace application on a generic Linux distribution.

Supported distributions include:

* Ubuntu
* Debian
* Fedora
* CentOS
* Arch Linux
* Embedded Linux Systems
* Yocto-based Targets

---

# Project Directory Structure

The project directory is organized as shown below.

```text
~/learning/Linux_Protocol_Applications/I2C

.

├── di2c.c
├── di2c.h
├── di2cAHT20.c
├── di2cAHT20.h
├── Makefile
└── I2C_Communication.png


1 directory, 6 files
```

---

# Software Requirements

Ensure the required development tools are installed.

---

## Ubuntu / Debian

Install GCC and Make.

```bash
sudo apt update

sudo apt install gcc make
```

---

## Fedora

```bash
sudo dnf install gcc make
```

---

## Arch Linux

```bash
sudo pacman -S gcc make
```

---

# Verify Installation

Check GCC version.

```bash
gcc --version
```

Example Output

```text
gcc (Ubuntu 13.2.0) 13.2.0
```

---

Check Make version.

```bash
make --version
```

Example Output

```text
GNU Make 4.3
```

---

# Source Files

The application consists of the following files.

| File                  | Description            |
| --------------------- | ---------------------- |
| di2c.c                | Generic Linux I2C APIs |
| di2c.h                | I2C Header File        |
| di2cAHT20.c           | AHT20 Sensor Driver    |
| di2cAHT20.h           | AHT20 Driver Header    |
| Makefile              | Build Script           |
| I2C_Communication.png | I2C Infographic        |

---

# Method 1 : Direct Compilation

The application can be compiled directly using GCC.

---

## Compile Application

```bash
gcc -Wall -Wextra -O2 \
di2c.c \
di2cAHT20.c \
-o di2c
```

---

## Compilation Options

| Option  | Description                |
| ------- | -------------------------- |
| -Wall   | Enable warnings            |
| -Wextra | Enable additional warnings |
| -O2     | Compiler optimization      |
| -o      | Output executable          |

---

## Verify Executable

```bash
ls -l di2c
```

Example Output

```text
-rwxrwxr-x 1 dhawal dhawal 23152 Jun 26 14:22 di2c
```

---

# Method 2 : Using Makefile

Using a Makefile simplifies application builds.

---

## Example Makefile

```make
CC=gcc

CFLAGS=-Wall -Wextra -O2


SRC=di2c.c \
    di2cAHT20.c


OBJ=$(SRC:.c=.o)


TARGET=di2c



all: $(TARGET)



$(TARGET): $(OBJ)

	$(CC) $(CFLAGS) -o $@ $^



%.o: %.c

	$(CC) $(CFLAGS) -c $<



clean:

	rm -f *.o $(TARGET)
```

---

# Build Application

```bash
make
```

Example

```text
gcc -Wall -Wextra -O2 -c di2c.c

gcc -Wall -Wextra -O2 -c di2cAHT20.c

gcc -Wall -Wextra -O2 \
-o di2c \
di2c.o \
di2cAHT20.o
```

---

# Clean Build Files

```bash
make clean
```

Expected

```text
rm -f *.o di2c
```

---

# Verify Application

Check executable.

```bash
file di2c
```

Example

```text
di2c:

ELF 64-bit executable
```

---

# Executing Application

Run application.

```bash
sudo ./di2c
```

---

## Expected Output

Example

```text
Temperature : 28.4°C

Humidity : 61.8 %
```

Output depends on sensor readings.

---

# Permissions

Linux restricts access to I2C devices.

Example

```text
/dev/i2c-0

/dev/i2c-1
```

Check permissions.

```bash
ls -l /dev/i2c*
```

---

## Using sudo

```bash
sudo ./di2c
```

---

## Adding User to Group

Some systems provide the i2c group.

Example

```bash
sudo usermod -aG i2c $USER
```

Logout.

Login again.

---

# Debugging Build Issues

---

## GCC Missing

Error

```text
gcc: command not found
```

Solution

```bash
sudo apt install gcc
```

---

## Make Missing

Error

```text
make: command not found
```

Solution

```bash
sudo apt install make
```

---

## Header File Errors

Error

```text
fatal error

di2c.h
```

Verify

```bash
ls
```

Expected

```text
di2c.c

di2c.h

di2cAHT20.c

di2cAHT20.h
```

---

## Permission Issues

Error

```text
Permission denied
```

Solution

```bash
sudo ./di2c
```

---

# Recommended Workflow

Compile

```bash
make
```

Verify

```bash
ls -l di2c
```

Run

```bash
sudo ./di2c
```

Clean

```bash
make clean
```

---

# Summary

Building the I2C application on Linux is straightforward and can be performed using either direct GCC commands or a Makefile.

The Makefile approach is generally recommended because it simplifies rebuilds, improves maintainability, and closely resembles the build mechanisms used in Yocto and other embedded Linux environments.
