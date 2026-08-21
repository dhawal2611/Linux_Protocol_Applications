#!/bin/bash

###############################################################################
# Framework Information
###############################################################################

FRAMEWORK_NAME="Embedded Linux Validation Framework"
FRAMEWORK_VERSION="1.0.0"

MODULE_LIST=()

SUITE_SELECTED=0

LOOP_MODE=0

###############################################################################
# Loop Duration
#
# Used by the direct CLI --loop path.
#
# 0           : Run indefinitely until Ctrl+C  (default)
# N (seconds) : Run for N seconds then stop
#
# Set via:
#   ./validate.sh cpu --loop                    # infinite
#   ./validate.sh cpu --loop --duration 5       # 5 minutes
###############################################################################
LOOP_DURATION_SECS=0

CSV_FILE=""

LOG_TARGET=""

LOGGER_OUTPUT_MODE="console"

TEST_LOG_OUTPUT_MODE="console"

RUN_ALL_MODULES=0

FRAMEWORK_VERSION="1.0.0"

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
# CSV File Override
#
# Set by parse_csv() when the user passes --csv <file>.
# When non-empty, run_single_module() skips per-module auto-naming and
# writes all modules to this single custom file instead.
###############################################################################
CSV_FILE_OVERRIDE=""

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

USB_TEST_FILE="usb_validation_test.bin"
USB_TEST_SIZE=100
USB_PERF_SIZE=100
USB_FIO_SIZE="256M"
USB_FIO_RUNTIME=30

###############################################################################
# Runtime folder path
###############################################################################

RUNTIME_DIR="${VALIDATION_FRAMEWORK_ROOT}/runtime"

###############################################################################
# GPIO Configuration
###############################################################################

# GPIO sysfs base/offset.
#
# Board-specific value.
#
# Example:
# Board A : 0
# Board B : 512
# Board C : 1000
#
GPIO_OFFSET=512

# Logical GPIO pins to validate.
GPIO_PINS=(17 18 22 23)

###############################################################################
# Runtime Variables
###############################################################################

GPIO_DISCOVERY_DONE=0
GPIO_SYSFS_BASE="/sys/class/gpio"

###############################################################################
# SPI NOR Runtime Configuration
###############################################################################

SPINOR_DEVICE="${SPINOR_DEVICE:-/dev/mtd0}"
SPINOR_MTD_NAME=""

###############################################################################
# Configuration Defaults
#
# These values can be overridden from config.sh.
###############################################################################

UART_DEVICE="${UART_DEVICE:-/dev/ttyUSB1}"

UART_BAUDRATE="${UART_BAUDRATE:-115200}"
UART_HIGH_SPEED="${UART_HIGH_SPEED:-921600}"

UART_DATABITS="${UART_DATABITS:-8}"
UART_PARITY="${UART_PARITY:-none}"
UART_STOPBITS="${UART_STOPBITS:-1}"

UART_TEST_DATA="${UART_TEST_DATA:-UART_TEST_12345}"

UART_STABILITY_ITERATIONS="${UART_STABILITY_ITERATIONS:-100}"
UART_RX_TIMEOUT="${UART_RX_TIMEOUT:-2}"

###############################################################################
# Configuration Defaults
#
# These values can be overridden from config.sh.
###############################################################################

SPI_DEVICE="${SPI_DEVICE:-/dev/spidev0.0}"

SPI_DEFAULT_SPEED="${SPI_DEFAULT_SPEED:-500000}"
SPI_TEST_SPEED="${SPI_TEST_SPEED:-1000000}"
SPI_HIGH_SPEED="${SPI_HIGH_SPEED:-10000000}"

SPI_TRANSFER_DATA="${SPI_TRANSFER_DATA:-12345678}"

SPI_STABILITY_LOOPS="${SPI_STABILITY_LOOPS:-100}"

###############################################################################
# Configuration Defaults
###############################################################################

#
# Generic I2C device
#
I2C_GENERIC_BUS="${I2C_GENERIC_BUS:-1}"
I2C_GENERIC_ADDRESS="${I2C_GENERIC_ADDRESS:-0x38}"

#
# Generic read/write configuration
#
I2C_GENERIC_WRITE_REGISTER="${I2C_GENERIC_WRITE_REGISTER:-0x00}"
I2C_GENERIC_WRITE_VALUE="${I2C_GENERIC_WRITE_VALUE:-0x12}"
I2C_GENERIC_READ_REGISTER="${I2C_GENERIC_READ_REGISTER:-0x00}"

#
# Configured generic devices.
#
# Format:
#
#   BUS:ADDRESS
#
# Example:
#
#   I2C_GENERIC_DEVICES=(
#       "1:0x38"
#       "1:0x60"
#   )
#

if [ -z "${I2C_GENERIC_DEVICES+x}" ]
then
    I2C_GENERIC_DEVICES=(
        "1:0x38"
    )
fi



###############################################################################
# Ethernet Configuration
#
# These variables should preferably be defined in config.sh
###############################################################################

ETH_INTERFACES="${ETH_INTERFACES:-eth0}"

# Ping / iperf server corresponding to each interface.
#
# Format:
#   interface:server_ip
#
# Example:
#   ETH_SERVER_MAP=("eth0:192.168.1.100" "eth1:192.168.2.100")
#
if [ -z "${ETH_SERVER_MAP+x}" ]
then
    ETH_SERVER_MAP=(
        "eth0:192.168.134.174"
    )
fi

ETH_IPERF_DURATION="${ETH_IPERF_DURATION:-10}"

