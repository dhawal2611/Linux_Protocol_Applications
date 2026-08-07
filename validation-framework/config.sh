#!/bin/bash

###############################################################################
# Framework Information
###############################################################################

FRAMEWORK_NAME="Embedded Linux Validation Framework"
FRAMEWORK_VERSION="1.0.0"

MODULE_LIST=()

SUITE_SELECTED=0

LOOP_MODE=0

CSV_REPORT_ENABLE=0

CSV_FILE=""

LOG_TARGET=""

LOGGER_OUTPUT_MODE="console"

TEST_LOG_OUTPUT_MODE="console"

RUN_ALL_MODULES=0

FRAMEWORK_VERSION="1.0.0"

LOG_DIR="./logs"

# Framework Directory Structure Configuration
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$ROOT_DIR/lib"
MODULE_DIR="$ROOT_DIR/modules"
SUITE_DIR="$ROOT_DIR/suites"
LOG_DIR="$ROOT_DIR/logs"
CSV_DIR="$ROOT_DIR/csv"

#mkdir -p "$LOG_DIR"

#LOG_FILE="$LOG_DIR/validation_$(date +%Y%m%d_%H%M%S).log"

###############################################################################
# CSV Report Configuration
#
# Enable/Disable CSV report generation.
#
# Default:
#   0 : Disabled
#   1 : Enabled
#
# NOTE:
# Can be overridden using:
#
#   ./validate.sh cpu --csv
#
###############################################################################
CSV_REPORT_ENABLE=0

###############################################################################
# CSV Report File
###############################################################################
CSV_FILE=""

###############################################################################
# Log File
#
# NOTE:
# LOG_FILE is generated dynamically in validate.sh after parsing the
# command-line arguments so that the module or suite name can be included
# in the log file name.
###############################################################################
LOG_FILE=""

###############################################################################
# Log File Generation
###############################################################################
LOG_FILE_ENABLE=0

###############################################################################
# Logging Configuration
#
# LOGGER_OUTPUT_MODE
# Controls where framework messages are displayed.
# These include:
#   - [INFO]
#   - [PASS]
#   - [FAIL]
#   - [WARN]
#
# Valid Values:
#   console    Display messages only on the console.
#   file       Save messages only to the log file.
#   both       Display messages on the console and save to the log file.
#
# Default:
#   console
###############################################################################
LOGGER_OUTPUT_MODE="console"

###############################################################################
# Test Log Configuration
#
# TEST_LOG_OUTPUT_MODE
# Controls where detailed test execution logs are written.
#
# These logs include:
#   - Test Start/End headers
#   - Executed command
#   - Command output
#   - Test summary
#   - Execution time
#   - Exit status
#
# Valid Values:
#   console    Print detailed test logs only on the console.
#   file       Save detailed test logs only to the log file.
#   both       Print detailed test logs on the console and save to the log file.
#   none       Disable detailed test logs.
#
# Default:
#   console
###############################################################################
TEST_LOG_OUTPUT_MODE="console"

###############################################################################
# Thermal Configuration
###############################################################################

THERMAL_STRESS_DURATION=5
THERMAL_STRESS_CPU=1

###############################################################################
# DDR Test Configuration
###############################################################################

DDR_TEST_SIZE="64M"
DDR_TEST_ITERATION=1

###############################################################################
# DDR Stress-ng Configuration
###############################################################################

DDR_STRESS_VM=4
DDR_STRESS_VM_BYTES="512M"
DDR_STRESS_TIMEOUT=300

###############################################################################
# DDR Performance Test Configuration
###############################################################################

DDR_MBW_SIZE=256

###############################################################################
# eMMC Test Configuration
###############################################################################

EMMC_TEST_SIZE="100M"

###############################################################################
# eMMC Performance Configuration
###############################################################################

EMMC_DD_COUNT=100

EMMC_FIO_SIZE="256M"

EMMC_FIO_RUNTIME=60

###############################################################################
# eMMC Mount Configuration
###############################################################################

EMMC_MOUNTPOINT="/mnt/emmc_validation"

EMMC_MOUNTED_BY_TEST=0

###############################################################################
# Storage Devices
###############################################################################

EMMC_DEVICE="/dev/mmcblk0"

SDCARD_DEVICE="/dev/sdb"

NVME_DEVICE="/dev/nvme0n1"

SATA_DEVICE="/dev/sda"

USB_DEVICE="/dev/sdb"

#LOCAL_DEVICE="/home/dhawal/learning/Linux_Protocol_Applications/validation-framework/test"

###############################################################################
# SD Card Configuration
###############################################################################

# Optional mount point
SDCARD_MOUNTPOINT_PATH="/mnt/sdcard_validation"

# Sequential DD test size
SDCARD_DD_COUNT=100

# FIO test size
SDCARD_FIO_SIZE="256M"

# FIO runtime in seconds
SDCARD_FIO_RUNTIME=60

###############################################################################
# SATA Configuration
###############################################################################

SATA_MOUNTPOINT_PATH="/mnt/sata_validation"

SATA_DD_COUNT=100

SATA_FIO_SIZE="256M"
SATA_FIO_RUNTIME=60

###############################################################################
# USB Validation Configuration
###############################################################################

# USB validation configuration

USB_TEST_FILE="usb_validation_test.bin"
USB_TEST_SIZE=100
USB_PERF_SIZE=100
USB_FIO_SIZE="256M"
USB_FIO_RUNTIME=30

###############################################################################
# I2C VALIDATION CONFIGURATION
###############################################################################

###############################################################################
# I2C BUS CONFIGURATION
###############################################################################
#
# Leave I2C_BUSES empty to automatically detect all available I2C buses
# using:
#
#     i2cdetect -l
#
# Example detected buses on Raspberry Pi:
#
#     i2c-1
#     i2c-20
#     i2c-21
#
# If required, specific buses can be restricted:
#
#     I2C_BUSES="0 1"
#
###############################################################################

I2C_BUSES=""


###############################################################################
# I2C0 - TEMPERATURE SENSOR
###############################################################################
#
# Device     : TMP1075NDRLR
# Quantity   : 2
# Bus        : I2C0
# Speed      : 400 kHz
#
###############################################################################

I2C_TMP1075_BUS=0

I2C_TMP1075_ADDR_1=0x48
I2C_TMP1075_ADDR_2=0x49

I2C_TMP1075_SPEED=400000


###############################################################################
# I2C0 - EEPROM
###############################################################################
#
# Device     : 24LC64T-E/MNY
# Bus        : I2C0
# Address    : 0x50
# Speed      : 400 kHz
#
###############################################################################

I2C_EEPROM_BUS=0
I2C_EEPROM_ADDR=0x50
I2C_EEPROM_SPEED=400000


###############################################################################
# I2C0 - CURRENT SENSOR
###############################################################################
#
# Device     : PAC1931T-I/J6CX
# Bus        : I2C0
# Address    : 0x1F
# Address is hardware configurable using resistor combination.
# Schematic address : 0x1F
# Speed      : 400 kHz
#
###############################################################################

I2C_CURRENT_SENSOR_BUS=0
I2C_CURRENT_SENSOR_ADDR=0x1F
I2C_CURRENT_SENSOR_SPEED=400000


###############################################################################
# I2C1 - AUTHENTICATION IC
###############################################################################
#
# Device     : ATECC608B
# Manufacturer: Microchip Technology
# Bus        : I2C1
# Address    : 0x60
# Speed      : 1 MHz
#
###############################################################################

I2C_AUTH_BUS=1
I2C_AUTH_ADDR=0x60
I2C_AUTH_SPEED=1000000


###############################################################################
# GENERIC I2C DEVICE
###############################################################################
#
# Used for:
#
#     I2C-009 : Verify Generic Slave Address
#     I2C-010 : Generic Read
#     I2C-011 : Generic Write
#     I2C-012 : Generic Write + Readback
#
# Default generic device:
#
#     Bus     : I2C1
#     Address : 0x38
#
###############################################################################

I2C_GENERIC_BUS=1
I2C_GENERIC_ADDRESS=0x38


###############################################################################
# GENERIC I2C READ
###############################################################################
#
# Example transaction:
#
#     i2ctransfer -y 1 w1@0x38 0x00 r1
#
###############################################################################

I2C_GENERIC_READ_REGISTER=0x00
I2C_GENERIC_READ_LENGTH=1


###############################################################################
# GENERIC I2C WRITE
###############################################################################
#
# Example transaction:
#
#     i2ctransfer -y 1 w2@0x38 0x00 0x12
#
###############################################################################

I2C_GENERIC_WRITE_REGISTER=0x00
I2C_GENERIC_WRITE_VALUE=0x12


###############################################################################
# GENERIC I2C WRITE + READBACK
###############################################################################
#
# Write:
#
#     i2ctransfer -y 1 w2@0x38 0x00 0x12
#
# Readback:
#
#     i2ctransfer -y 1 w1@0x38 0x00 r1
#
###############################################################################

I2C_GENERIC_READBACK_REGISTER=0x00
I2C_GENERIC_READBACK_LENGTH=1


###############################################################################
# GENERIC I2C DEVICE LIST
###############################################################################
#
# Format:
#
#     BUS:ADDRESS
#
# Example:
#
#     I2C_GENERIC_DEVICES="1:0x38"
#
# Multiple generic devices can be configured:
#
#     I2C_GENERIC_DEVICES="1:0x38 1:0x50 20:0x20"
#
# The I2C validation module can use this list to validate all configured
# generic devices.
#
###############################################################################

I2C_GENERIC_DEVICES="1:0x38"


###############################################################################
# I2C VALIDATION OPTIONS
###############################################################################
#
# Automatically scan all available I2C buses.
#
# 1 = Enable automatic bus discovery
# 0 = Use I2C_BUSES variable
#
###############################################################################

I2C_AUTO_DISCOVER_BUSES=1


###############################################################################
# I2C SCAN OPTIONS
###############################################################################
#
# Run i2cdetect on every detected I2C bus.
#
###############################################################################

I2C_SCAN_ALL_BUSES=1


###############################################################################
# END OF I2C VALIDATION CONFIGURATION
###############################################################################





























