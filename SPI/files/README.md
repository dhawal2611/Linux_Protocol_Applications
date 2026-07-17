# Build and Run Guide

This document explains how to compile and execute the **dspiw25qxx** application.

---

# Prerequisites

Ensure the following packages are installed on your Linux system:

- GCC Compiler
- GNU Make
- Linux SPI (spidev) driver enabled
- Standard C Library

Verify the compiler installation:

```bash
gcc --version
```

Verify Make installation:

```bash
make --version
```

---

# Project Structure

```text
.
├── dspi.c
├── dspi.h
├── dspiw25qxx.c
├── dspiw25qxx.h
├── Makefile
└── README.md
```

---

# Compiling the Application

Navigate to the project directory:

```bash
cd <project_directory>
```

Compile the project using:

```bash
make
```

If the compilation is successful, the executable binary will be generated:

```text
dspiw25qxx
```

---

# Cleaning the Build

To remove the generated executable and object files:

```bash
make clean
```

---

# Running the Application

Execute the binary from the project directory:

```bash
./dspiw25qxx
```

If the application requires root privileges to access the SPI device, run:

```bash
sudo ./dspiw25qxx
```

---

# Expected Output

A successful execution may display output similar to:

```text
SPI Device Opened Successfully

Reading JEDEC ID...

Manufacturer ID : 0xEF
Memory Type     : 0x40
Capacity        : 0x18

Device Detected Successfully
```

---

# Troubleshooting

### `make: command not found`

Install GNU Make.

---

### `gcc: command not found`

Install the GCC compiler.

---

### `Permission denied`

Run the application with root privileges:

```bash
sudo ./dspiw25qxx
```

---

### `Failed to open SPI device`

Verify that:

- SPI is enabled in the Linux kernel.
- The `spidev` driver is loaded.
- The correct SPI device (for example, `/dev/spidev0.0`) exists.
- The application has permission to access the SPI device.

List available SPI devices:

```bash
ls /dev/spidev*
```

---

# Build Commands Summary

| Action | Command |
|--------|---------|
| Build | `make` |
| Clean | `make clean` |
| Run | `./dspiw25qxx` |
| Run as Root | `sudo ./dspiw25qxx` |

---

# Author

**Dhawal Umesh Lad**

Embedded Linux Developer

---

# License

This project is distributed under the **MIT License**.

Refer to the **LICENSE** file for details.
