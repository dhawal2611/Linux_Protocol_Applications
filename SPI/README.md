# SPI Communication 

<p align="center">
    <img src="SPI_Communication.png" alt="I2C Communication" width="100%">
</p>

---
Enable SPI in yocto R Pi

# 1. Hardware Enablement
ENABLE_SPI_BUS = "1"

# 2. Add extra overlay config safely using :append
RPI_EXTRA_CONFIG:append = "\ndtoverlay=spi0-1cs\n"

# 3. Kernel Modules & Autoloading
IMAGE_INSTALL:append = " kernel-module-spidev"
KERNEL_MODULE_AUTOLOAD:append = " spidev"

# 4. User Space Tools & Applications
IMAGE_INSTALL:append = " spitools python3-spidev"

IMAGE_INSTALL:append = " dspi"

