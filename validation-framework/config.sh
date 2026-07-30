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
# Storage Test and Performance Configuration
###############################################################################

STORAGE_TEST_DIR="storage_validation"

STORAGE_TEST_FILE="storage_test.bin"

STORAGE_TEST_SIZE="100M"

STORAGE_FIO_SIZE="256M"

STORAGE_FIO_RUNTIME=60

STORAGE_DD_COUNT=100

###############################################################################
# Storage Devices
###############################################################################

EMMC_DEVICE="/dev/mmcblk1"
SDCARD_DEVICE="/dev/mmcblk0"
NVME_DEVICE="/dev/nvme0n1"
SATA_DEVICE="/dev/sda"
USB_DEVICE="/dev/sdb"

LOCAL_DEVICE="/home/dhawal/Linux_Protocol_Applications/validation-framework/test"

###############################################################################
# Storage Device Selection
###############################################################################

STORAGE_DEVICE=""
STORAGE_DEVICES=()
STORAGE_MOUNTPOINT=""



















###############################################################################
# GPIO Configuration
###############################################################################

# Default GPIO Number
GPIO_NUM=24

# GPIO Sysfs Path
GPIO_SYSFS=/sys/class/gpio

# GPIO Node
GPIO_PATH=$GPIO_SYSFS/gpio$GPIO_NUM

GPIO_LIST=(
24
25
26
27
)

###############################################################################
# Ethernet Configuration
###############################################################################

# Network Interface
ETH_INTERFACE="eth0"

# Gateway IP Address
GATEWAY_IP="192.168.1.1"

# iPerf3 Server IP Address
IPERF_SERVER="192.168.1.100"

# Peer IP Address (for Jumbo Frame Test)
PEER_IP="192.168.1.101"

# Jumbo Frame MTU
JUMBO_MTU=9000

###############################################################################
# GbE PHY Configuration
###############################################################################

# Ethernet Interface
ETH_INTERFACE="eth0"

# PHY Address
PHY_ADDR="0"

# PHY Register (BMCR = Register 0)
PHY_BMCR_REG="0"

###############################################################################
# DHCP Configuration
###############################################################################

# Ethernet Interface
ETH_INTERFACE="eth0"

###############################################################################
# SSH Configuration
###############################################################################

# DUT IP Address
DUT_IP="192.168.1.100"

# SSH User
SSH_USER="root"

# Test File for SCP
SCP_TEST_FILE="test.bin"

# Destination Directory
SCP_DEST="/tmp"

###############################################################################
# SerDes Configuration
###############################################################################
SERDES_PRBS_CMD="vendor_prbs_tool start"

###############################################################################
# SGMII Configuration
###############################################################################

# SGMII Interface
SGMII_INTERFACE="eth0"

# Peer IP Address
SGMII_PEER_IP="192.168.1.101"

# iPerf3 Server IP Address
SGMII_IPERF_SERVER="192.168.1.100"

###############################################################################
# USB Configuration
###############################################################################

# USB Storage Device
USB_DEVICE="/dev/sda1"

# USB Mount Point
USB_MOUNT_POINT="/mnt"

# USB Test File
USB_TEST_FILE="test.bin"

# Test File Size (MB)
USB_TEST_SIZE=100

###############################################################################
# RTC Configuration
###############################################################################

# RTC Device
RTC_DEVICE="rtc0"

# RTC Sysfs Path
RTC_SYSFS="/sys/class/rtc/${RTC_DEVICE}"

# RTC Alarm Time (Seconds)
RTC_ALARM_SEC=60

###############################################################################
# Watchdog Configuration
###############################################################################

# Watchdog Device
WATCHDOG_DEVICE="/dev/watchdog"

# Watchdog Timeout (Seconds)
WATCHDOG_TIMEOUT=30

###############################################################################
# systemd Configuration
###############################################################################

# Service used for systemd validation
SYSTEMD_SERVICE="sshd"

###############################################################################
# Journald Configuration
###############################################################################

# Exported Journal Log
JOURNAL_EXPORT="/tmp/journal.log"

# Vacuum Time
JOURNAL_VACUUM_TIME="1d"

# Persistent Journal Directory
JOURNAL_DIR="/var/log/journal"

###############################################################################
# Suspend / Resume Configuration
###############################################################################

# RTC Device
RTC_DEVICE="rtc0"

# RTC Wake Alarm (Seconds)
SUSPEND_WAKEUP_TIME=60

# Gateway IP Address
SUSPEND_GATEWAY_IP="192.168.1.1"

###############################################################################
# Power Cycle Configuration
###############################################################################

# Root filesystem partition
ROOTFS_PARTITION="/dev/mmcblk0p2"

###############################################################################
# Long Duration Stress Configuration
###############################################################################

# Stress Duration (Seconds)
STRESS_DURATION=86400

# CPU Workers
STRESS_CPU_WORKERS=4

# Memory Workers
STRESS_VM_WORKERS=4

# Memory Usage
STRESS_VM_BYTES="80%"

# iperf3 Server
IPERF3_SERVER="192.168.1.100"

# Thermal Zone
THERMAL_ZONE="/sys/class/thermal/thermal_zone0/temp"

# Temperature Sampling Interval
TEMP_MONITOR_INTERVAL=60

###############################################################################
# Crypto Configuration
###############################################################################

# Crypto Module Pattern
CRYPTO_MODULE_PATTERN="crypto"

# Crypto Driver Log Pattern
CRYPTO_DMESG_PATTERN="crypto"

# Proc Crypto File
PROC_CRYPTO="/proc/crypto"

###############################################################################
# OpenSSL Validation Configuration
###############################################################################

# Test File Name
CRYPTO_TEST_FILE="test.bin"

# Encrypted File
CRYPTO_ENC_FILE="test.enc"

# Decrypted File
CRYPTO_DEC_FILE="test_dec.bin"

# Test File Size (MB)
CRYPTO_TEST_SIZE_MB=100

# Encryption Password
CRYPTO_PASSWORD="password"

# Encryption Algorithm
CRYPTO_AES_ALGO="aes-256-cbc"

###############################################################################
# Crypto Benchmark Configuration
###############################################################################

# OpenSSL Benchmark Duration (seconds)
OPENSSL_BENCH_TIME=10

# Enable Vendor HW Crypto Benchmark
ENABLE_HW_CRYPTO_TEST=0

# Vendor Specific HW Benchmark Command
HW_CRYPTO_CMD="vendor_crypto_test"

# SHA Log Pattern
SHA_LOG_PATTERN="sha"

###############################################################################
# Crypto RNG Configuration
###############################################################################

# Hardware RNG Device
HWRNG_DEVICE="/dev/hwrng"

# Random Output File
RNG_OUTPUT_FILE="random.bin"

# Random Data Size (KB)
RNG_DATA_SIZE_KB=100

# Minimum Expected Entropy
MIN_ENTROPY=128

###############################################################################
# Crypto LUKS Configuration
###############################################################################

# Test Image
CRYPT_IMAGE="crypt.img"

# Image Size (MB)
CRYPT_IMAGE_SIZE=100

# Mapper Name
CRYPT_MAPPER="cryptdev"

# Mount Point
CRYPT_MOUNT="/mnt/crypt_test"

# Password
CRYPT_PASSWORD="password"

# Test File
CRYPT_TEST_FILE="test.txt"

# Test String
CRYPT_TEST_STRING="Embedded Linux Crypto Validation"

# Filesystem
CRYPT_FS="ext4"

###############################################################################
# Crypto Stress Configuration
###############################################################################

# Stress Duration (Seconds)
CRYPTO_STRESS_DURATION=86400

# AES Algorithm
CRYPTO_STRESS_ALGORITHM="aes-256-cbc"

# Thermal Zone
CRYPTO_THERMAL_ZONE="/sys/class/thermal/thermal_zone0/temp"

# Temperature Log Interval (Seconds)
CRYPTO_TEMP_INTERVAL=60

# Enable SHA Benchmark Along With AES
ENABLE_SHA_STRESS=1

# SHA Algorithm
CRYPTO_SHA_ALGORITHM="sha256"

# Log Directory
CRYPTO_LOG_DIR="logs"
