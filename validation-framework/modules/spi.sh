#!/bin/bash
###############################################################################
#
# File        : spi.sh
# Description : SPI Peripheral Validation Module
#
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="SPI"
MODULE_DESCRIPTION="SPI Peripheral Validation"

###############################################################################
# Runtime / Persistent Discovery
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SPI_RUNTIME_DIR="$FRAMEWORK_DIR/runtime/spi"

SPI_DISCOVERY_STATUS_FILE="$SPI_RUNTIME_DIR/discovery.status"
SPI_DEVICES_FILE="$SPI_RUNTIME_DIR/devices.list"
SPI_PRIMARY_DEVICE_FILE="$SPI_RUNTIME_DIR/primary_device"

SPI_DEVICES=""
SPI_PRIMARY_DEVICE="/dev/spidev0.0"
SPI_DISCOVERY_DONE=0

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    spidev_test
    ls
    grep
    tr
    wc
    printf
)

###############################################################################
# Runtime Directory
###############################################################################

spi_create_runtime_directory()
{
    mkdir -p "$SPI_RUNTIME_DIR" 2>/dev/null

    if [ $? -ne 0 ]
    then
        echo "ERROR: Unable to create SPI runtime directory:"
        echo "       $SPI_RUNTIME_DIR"
        return 1
    fi

    return 0
}

###############################################################################
# SPI Discovery
#
# Detect all available /dev/spidev* devices.
#
# Discovery is performed only by SPI-001.
#
###############################################################################

spi_cmd_discover_devices()
{
    local DEVICE
    local STATUS=0

    echo "Starting SPI device discovery..."
    echo

    if ! spi_create_runtime_directory
    then
        return 1
    fi

    SPI_DEVICES=""

    #
    # Discover all spidev nodes.
    #
    for DEVICE in /dev/spidev*
    do
        if [ -e "$DEVICE" ]
        then
            SPI_DEVICES="$SPI_DEVICES $DEVICE"
        fi
    done

    SPI_DEVICES=$(echo "$SPI_DEVICES" | xargs 2>/dev/null)

    #
    # No SPI device detected.
    #
    if [ -z "$SPI_DEVICES" ]
    then
        echo "ERROR: No SPI spidev devices detected."
        echo

        echo "FAILED" > "$SPI_DISCOVERY_STATUS_FILE"
        : > "$SPI_DEVICES_FILE"

        SPI_DISCOVERY_DONE=0

        return 1
    fi

    echo "Detected SPI devices:"
    echo "$SPI_DEVICES"
    echo

    #
    # Save all devices.
    #
    echo "$SPI_DEVICES" > "$SPI_DEVICES_FILE"

    #
    # Select primary SPI device.
    #
    if echo "$SPI_DEVICES" | grep -qw "$SPI_DEVICE"
    then
        SPI_PRIMARY_DEVICE="$SPI_DEVICE"
    else
        SPI_PRIMARY_DEVICE=$(echo "$SPI_DEVICES" | awk '{print $1}')
    fi

    echo "$SPI_PRIMARY_DEVICE" > "$SPI_PRIMARY_DEVICE_FILE"

    #
    # Mark discovery successful.
    #
    echo "DONE" > "$SPI_DISCOVERY_STATUS_FILE"

    SPI_DISCOVERY_DONE=1

    echo "Primary SPI device:"
    echo "  $SPI_PRIMARY_DEVICE"
    echo

    echo "SPI discovery completed successfully."

    return "$STATUS"
}

###############################################################################
# Load SPI Discovery Information
#
# This function reads persistent runtime information.
#
# This avoids relying on shell global variables surviving between test cases.
#
###############################################################################

spi_load_discovery()
{
    local STATUS

    if [ ! -f "$SPI_DISCOVERY_STATUS_FILE" ]
    then
        SPI_DISCOVERY_DONE=0
        return 1
    fi

    STATUS=$(cat "$SPI_DISCOVERY_STATUS_FILE" 2>/dev/null)

    if [ "$STATUS" != "DONE" ]
    then
        SPI_DISCOVERY_DONE=0
        return 1
    fi

    if [ ! -f "$SPI_DEVICES_FILE" ]
    then
        SPI_DISCOVERY_DONE=0
        return 1
    fi

    SPI_DEVICES=$(cat "$SPI_DEVICES_FILE" 2>/dev/null)

    if [ -z "$SPI_DEVICES" ]
    then
        SPI_DISCOVERY_DONE=0
        return 1
    fi

    if [ -f "$SPI_PRIMARY_DEVICE_FILE" ]
    then
        SPI_PRIMARY_DEVICE=$(cat "$SPI_PRIMARY_DEVICE_FILE" 2>/dev/null)
    fi

    if [ -z "$SPI_PRIMARY_DEVICE" ]
    then
        SPI_PRIMARY_DEVICE="$SPI_DEVICE"
    fi

    SPI_DISCOVERY_DONE=1

    return 0
}

###############################################################################
# Verify SPI Device
###############################################################################

spi_verify_expected_device()
{
    local DEVICE="$1"

    if ! spi_load_discovery
    then
        echo "ERROR: SPI discovery has not been completed."
        return 1
    fi

    if ! echo "$SPI_DEVICES" | grep -qw "$DEVICE"
    then
        echo "ERROR: SPI device not detected."
        echo
        echo "Expected:"
        echo "  Device : $DEVICE"
        echo
        echo "Detected:"
        echo "$SPI_DEVICES"

        return 1
    fi

    echo "SPI device detected successfully."
    echo "  Device : $DEVICE"

    return 0
}

###############################################################################
# SPI-003 Helper
#
# Generate and transmit exactly 4 KB.
#
###############################################################################

spi_cmd_4kb_transfer()
{
    local DATA

    DATA=$(printf 'A%.0s' {1..4096})

    spidev_test \
        -D "$SPI_PRIMARY_DEVICE" \
        -s "$SPI_TEST_SPEED" \
        -p "$DATA" \
        -v

    return $?
}

###############################################################################
# SPI-011 Helper
#
# Large SPI transfer.
#
###############################################################################

spi_cmd_large_transfer()
{
    local DEVICE="$SPI_DEVICE"
    local CHUNK_SIZE=4096
    local CHUNKS=2560
    local COUNT=1
    local RET=0

    echo "Large SPIspi_cmd_large_transfer transfer test"
    echo "Device     : $DEVICE"
    echo "Chunk Size : ${CHUNK_SIZE} bytes"
    echo "Chunks     : $CHUNKS"
    echo "Total      : $((CHUNK_SIZE * CHUNKS)) bytes"
    echo

    while [ "$COUNT" -le "$CHUNKS" ]
    do
        spidev_test \
            -D "$DEVICE" \
            -s "$CHUNK_SIZE" \
            -p "12345678" >/dev/null 2>&1

        RET=$?

        if [ "$RET" -ne 0 ]
        then
            echo "ERROR: SPI transfer failed at chunk $COUNT/$CHUNKS"
            return "$RET"
        fi

        COUNT=$((COUNT + 1))
    done

    echo "Large SPI transfer completed successfully."
    echo "Total transferred: $((CHUNK_SIZE * CHUNKS)) bytes"

    return 0
}

###############################################################################
# SPI-012 Helper
#
# Repeated SPI transfer for stability.
#
###############################################################################

spi_cmd_stability_test()
{
    local COUNT="$SPI_STABILITY_LOOPS"
    local INDEX

    echo "SPI stability test"
    echo "Device : $SPI_PRIMARY_DEVICE"
    echo "Loops  : $COUNT"
    echo

    for INDEX in $(seq 1 "$COUNT")
    do
        spidev_test \
            -D "$SPI_PRIMARY_DEVICE" \
            -s "$SPI_TEST_SPEED" \
            -p "$SPI_TRANSFER_DATA" >/dev/null 2>&1

        if [ $? -ne 0 ]
        then
            echo "ERROR: SPI transfer failed at iteration $INDEX."
            return 1
        fi
    done

    echo "Completed $COUNT SPI transfers successfully."

    return 0
}

###############################################################################
# SPI-014 Helper
#
# Execute SPI flash-style command sequence:
#
# 1. Write Enable
# 2. Sector Erase
# 3. Write Enable
# 4. Page Program
# 5. Read Data
#
# Readback must contain:
#
#     Dhawal is in
#
###############################################################################

spi_cmd_command_sequence_readback()
{
    local READ_OUTPUT
    local EXPECTED_STRING="Dhawal is in"

    echo "SPI command sequence"
    echo "Device : $SPI_PRIMARY_DEVICE"
    echo "Speed  : ${SPI_HIGH_SPEED} Hz"
    echo

    echo "1. Write Enable"
    spidev_test \
        -D "$SPI_PRIMARY_DEVICE" \
        -s "$SPI_HIGH_SPEED" \
        -p "\x06"

    if [ $? -ne 0 ]
    then
        echo "ERROR: Write Enable command failed."
        return 1
    fi

    echo
    echo "2. Sector Erase"
    spidev_test \
        -D "$SPI_PRIMARY_DEVICE" \
        -s "$SPI_HIGH_SPEED" \
        -p "\x20\x00\x00\x00"

    if [ $? -ne 0 ]
    then
        echo "ERROR: Sector Erase command failed."
        return 1
    fi

    #
    # Allow erase operation to complete.
    #
    sleep 1

    echo
    echo "3. Write Enable"
    spidev_test \
        -D "$SPI_PRIMARY_DEVICE" \
        -s "$SPI_HIGH_SPEED" \
        -p "\x06"

    if [ $? -ne 0 ]
    then
        echo "ERROR: Second Write Enable command failed."
        return 1
    fi

    echo
    echo "4. Page Program"
    spidev_test \
        -D "$SPI_PRIMARY_DEVICE" \
        -s "$SPI_HIGH_SPEED" \
        -p "\x02\x00\x00\x00\x44\x68\x61\x77\x61\x6C\x20\x69\x73\x20\x69\x6E"

    if [ $? -ne 0 ]
    then
        echo "ERROR: Page Program command failed."
        return 1
    fi

    #
    # Allow programming operation to complete.
    #
    sleep 1

    echo
    echo "5. Read Data"

    READ_OUTPUT=$(spidev_test \
        -D "$SPI_PRIMARY_DEVICE" \
        -s "$SPI_HIGH_SPEED" \
        -v \
        -p "\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" 2>&1)

    echo "$READ_OUTPUT"

    echo
    echo "Verifying readback..."

    #
    # First check ASCII representation.
    #
    if echo "$READ_OUTPUT" | grep -Fq "$EXPECTED_STRING"
    then
        echo "Readback string detected:"
        echo "  $EXPECTED_STRING"
        echo
        echo "SPI command sequence and readback verification successful."

        return 0
    fi

    #
    # Some spidev_test versions may not print the ASCII string exactly.
    #
    # Verify the hexadecimal representation:
    #
    # Dhawal is in
    #
    # 44 68 61 77 61 6c 20 69 73 20 69 6e
    #
    if echo "$READ_OUTPUT" |
        tr '[:upper:]' '[:lower:]' |
        grep -Fq "44 68 61 77 61 6c 20 69 73 20 69 6e"
    then
        echo "Readback hexadecimal data matches expected string."
        echo
        echo "SPI command sequence and readback verification successful."

        return 0
    fi

    echo
    echo "ERROR: Readback verification failed."
    echo "Expected string:"
    echo "  $EXPECTED_STRING"

    return 1
}

###############################################################################
# SPI-001
#
# Detect SPI Device
#
###############################################################################

spi_001()
{
    log_info "[SPI-001] Detect SPI Device"

    run_command \
        "SPI-001" \
        "Detect SPI Device" \
        "spi_cmd_discover_devices"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="No SPI spidev device was detected."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI devices detected and discovery information stored successfully."

    test_pass
}

###############################################################################
# SPI-002
#
# Verify SPI Device Information
#
###############################################################################

spi_002()
{
    log_info "[SPI-002] Verify SPI Device Information"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-002" \
        "Verify SPI Device Information" \
        "ls -l $SPI_PRIMARY_DEVICE"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to access SPI device $SPI_PRIMARY_DEVICE."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI device $SPI_PRIMARY_DEVICE is available and accessible."

    test_pass
}

###############################################################################
# SPI-003
#
# Run 4KB SPI Transfer
#
###############################################################################

spi_003()
{
    log_info "[SPI-003] Run 4KB SPI Transfer"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-003" \
        "Run 4KB SPI Transfer" \
        "spi_cmd_4kb_transfer"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="4KB SPI transfer failed."
        test_fail
        return
    fi

    TEST_MESSAGE="4KB SPI transfer completed successfully."

    test_pass
}

###############################################################################
# SPI-004
#
# Verify SPI Mode 0
#
###############################################################################

spi_004()
{
    log_info "[SPI-004] Verify SPI Mode 0"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-004" \
        "Verify SPI Mode 0" \
        "spidev_test -D $SPI_PRIMARY_DEVICE -v -p \"$SPI_TRANSFER_DATA\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI Mode 0 test failed."
        test_fail
        return
    fi

    if ! echo "$COMMAND_OUTPUT" | grep -qi "spi mode: 0x0"
    then
        TEST_MESSAGE="SPI Mode 0 was not reported as 0x0."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI Mode 0 verified successfully."

    test_pass
}

###############################################################################
# SPI-005
#
# Verify SPI Mode 1
#
# Mode 1 = CPHA=1, CPOL=0
# spidev_test option -H enables CPHA.
#
###############################################################################

spi_005()
{
    log_info "[SPI-005] Verify SPI Mode 1"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-005" \
        "Verify SPI Mode 1" \
        "spidev_test -D $SPI_PRIMARY_DEVICE -v -H -p \"$SPI_TRANSFER_DATA\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI Mode 1 test failed."
        test_fail
        return
    fi

    if ! echo "$COMMAND_OUTPUT" | grep -qi "spi mode: 0x1"
    then
        TEST_MESSAGE="SPI Mode 1 was not reported as 0x1."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI Mode 1 verified successfully."

    test_pass
}

###############################################################################
# SPI-006
#
# Verify SPI Mode 2
#
# Mode 2 = CPOL=1, CPHA=0
# spidev_test option -O enables CPOL.
#
###############################################################################

spi_006()
{
    log_info "[SPI-006] Verify SPI Mode 2"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-006" \
        "Verify SPI Mode 2" \
        "spidev_test -D $SPI_PRIMARY_DEVICE -v -O -p \"$SPI_TRANSFER_DATA\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI Mode 2 test failed."
        test_fail
        return
    fi

    if ! echo "$COMMAND_OUTPUT" | grep -qi "spi mode: 0x2"
    then
        TEST_MESSAGE="SPI Mode 2 was not reported as 0x2."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI Mode 2 verified successfully."

    test_pass
}

###############################################################################
# SPI-007
#
# Verify SPI Mode 3
#
# Mode 3 = CPOL=1, CPHA=1
#
###############################################################################

spi_007()
{
    log_info "[SPI-007] Verify SPI Mode 3"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-007" \
        "Verify SPI Mode 3" \
        "spidev_test -D $SPI_PRIMARY_DEVICE -v -H -O -p \"$SPI_TRANSFER_DATA\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI Mode 3 test failed."
        test_fail
        return
    fi

    if ! echo "$COMMAND_OUTPUT" | grep -qi "spi mode: 0x3"
    then
        TEST_MESSAGE="SPI Mode 3 was not reported as 0x3."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI Mode 3 verified successfully."

    test_pass
}

###############################################################################
# SPI-008
#
# Verify 8-bit Word Length
#
###############################################################################

spi_008()
{
    log_info "[SPI-008] Verify 8-bit Word Length"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-008" \
        "Verify 8-bit Word Length" \
        "spidev_test -D $SPI_PRIMARY_DEVICE -v -b 8 -p \"$SPI_TRANSFER_DATA\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="8-bit SPI word length test failed."
        test_fail
        return
    fi

    if ! echo "$COMMAND_OUTPUT" | grep -qi "bits per word: 8"
    then
        TEST_MESSAGE="SPI did not report 8 bits per word."
        test_fail
        return
    fi

    TEST_MESSAGE="8-bit SPI word length verified successfully."

    test_pass
}

###############################################################################
# SPI-009
#
# Verify SPI Clock Speed
#
###############################################################################

spi_009()
{
    log_info "[SPI-009] Verify SPI Clock Speed"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-009" \
        "Verify SPI Clock Speed" \
        "spidev_test -D $SPI_PRIMARY_DEVICE -v -s $SPI_TEST_SPEED -p \"$SPI_TRANSFER_DATA\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI clock speed test failed."
        test_fail
        return
    fi

    if ! echo "$COMMAND_OUTPUT" | grep -qi "max speed:"
    then
        TEST_MESSAGE="SPI clock speed information was not reported."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI clock speed configuration verified successfully."

    test_pass
}

###############################################################################
# SPI-010
#
# Verify SPI TX/RX Data Transfer
#
###############################################################################

spi_010()
{
    log_info "[SPI-010] Verify SPI TX/RX Data Transfer"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-010" \
        "Verify SPI TX/RX Data Transfer" \
        "spidev_test -D $SPI_PRIMARY_DEVICE -v -p \"$SPI_TRANSFER_DATA\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI TX/RX data transfer failed."
        test_fail
        return
    fi

    if ! echo "$COMMAND_OUTPUT" | grep -q "TX |"
    then
        TEST_MESSAGE="SPI TX data was not reported."
        test_fail
        return
    fi

    if ! echo "$COMMAND_OUTPUT" | grep -q "RX |"
    then
        TEST_MESSAGE="SPI RX data was not reported."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI TX/RX data transfer completed successfully."

    test_pass
}

###############################################################################
# SPI-011
#
# Verify Large SPI Transfer
#
###############################################################################

spi_011()
{
    log_info "[SPI-011] Verify Large SPI Transfer"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-011" \
        "Verify Large SPI Transfer" \
        "spi_cmd_large_transfer"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Large SPI transfer failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Large SPI transfer completed successfully."

    test_pass
}

###############################################################################
# SPI-012
#
# Verify SPI Transfer Stability
#
###############################################################################

spi_012()
{
    log_info "[SPI-012] Verify SPI Transfer Stability"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-012" \
        "Verify SPI Transfer Stability" \
        "spi_cmd_stability_test"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI transfer stability test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI transfer stability verified successfully."

    test_pass
}

###############################################################################
# SPI-013
#
# Verify SPI Device Access
#
###############################################################################

spi_013()
{
    log_info "[SPI-013] Verify SPI Device Access"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-013" \
        "Verify SPI Device Access" \
        "test -r $SPI_PRIMARY_DEVICE && test -w $SPI_PRIMARY_DEVICE"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI device $SPI_PRIMARY_DEVICE is not readable/writable."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI device read/write access verified successfully."

    test_pass
}

###############################################################################
# SPI-014
#
# Verify SPI Command Sequence & Readback
#
###############################################################################

spi_014()
{
    log_info "[SPI-014] Verify SPI Command Sequence & Readback"

    if ! spi_verify_expected_device "$SPI_PRIMARY_DEVICE"
    then
        TEST_MESSAGE="Primary SPI device $SPI_PRIMARY_DEVICE was not detected."
        test_fail
        return
    fi

    run_command \
        "SPI-014" \
        "Verify SPI Command Sequence & Readback" \
        "spi_cmd_command_sequence_readback"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI command sequence or readback verification failed."
        test_fail
        return
    fi

    if ! echo "$COMMAND_OUTPUT" | grep -Fqi "Dhawal is in" &&
       ! echo "$COMMAND_OUTPUT" |
            tr '[:upper:]' '[:lower:]' |
            grep -Fq "44 68 61 77 61 6c 20 69 73 20 69 6e"
    then
        TEST_MESSAGE="SPI readback data does not contain expected string: Dhawal is in."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI command sequence completed and 'Dhawal is in' readback verified successfully."

    test_pass
}

###############################################################################
# Register SPI Tests
###############################################################################

spi_register_tests()
{
    register_test \
        -i "SPI-001" \
        -f spi_001 \
        -n "Detect SPI Device" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "spi,spidev,detect" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect all available SPI spidev devices and store discovery information."

    register_test \
        -i "SPI-002" \
        -f spi_002 \
        -n "Verify SPI Device Information" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "spi,spidev,device,information" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify the primary SPI spidev device is available and accessible."

    register_test \
        -i "SPI-003" \
        -f spi_003 \
        -n "Run 4KB SPI Transfer" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "spi,4kb,transfer" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Perform an actual 4KB SPI data transfer."

    register_test \
        -i "SPI-004" \
        -f spi_004 \
        -n "Verify SPI Mode 0" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 40 \
        -g "spi,mode0,cpol,cpha" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SPI Mode 0 operation."

    register_test \
        -i "SPI-005" \
        -f spi_005 \
        -n "Verify SPI Mode 1" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 50 \
        -g "spi,mode1,cpol,cpha" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SPI Mode 1 operation."

    register_test \
        -i "SPI-006" \
        -f spi_006 \
        -n "Verify SPI Mode 2" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 60 \
        -g "spi,mode2,cpol,cpha" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SPI Mode 2 operation."

    register_test \
        -i "SPI-007" \
        -f spi_007 \
        -n "Verify SPI Mode 3" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 70 \
        -g "spi,mode3,cpol,cpha" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SPI Mode 3 operation."

    register_test \
        -i "SPI-008" \
        -f spi_008 \
        -n "Verify 8-bit Word Length" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 80 \
        -g "spi,bits,8bit,word" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SPI operation using 8 bits per word."

    register_test \
        -i "SPI-009" \
        -f spi_009 \
        -n "Verify SPI Clock Speed" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 90 \
        -g "spi,clock,speed" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SPI clock speed configuration."

    register_test \
        -i "SPI-010" \
        -f spi_010 \
        -n "Verify SPI TX/RX Data Transfer" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 100 \
        -g "spi,tx,rx,data,transfer" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SPI transmit and receive data operations."

    register_test \
        -i "SPI-011" \
        -f spi_011 \
        -n "Verify Large SPI Transfer" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 110 \
        -g "spi,large,transfer" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify a large SPI data transfer."

    register_test \
        -i "SPI-012" \
        -f spi_012 \
        -n "Verify SPI Transfer Stability" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 120 \
        -g "spi,stability,repeated,transfer" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SPI transfer stability through repeated transfers."

    register_test \
        -i "SPI-013" \
        -f spi_013 \
        -n "Verify SPI Device Access" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 130 \
        -g "spi,access,read,write" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify read and write access to the SPI device node."

    register_test \
        -i "SPI-014" \
        -f spi_014 \
        -n "Verify SPI Command Sequence & Readback" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 140 \
        -g "spi,command,sequence,readback,Dhawal" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Execute SPI write-enable, erase, write-enable, program and read commands and verify 'Dhawal is in' readback."
}

###############################################################################
# Module Initialization
###############################################################################

spi_init()
{
    log_info "========================================="
    log_info "Starting SPI Validation"
    log_info "========================================="

    log_info "SPI Configuration:"
    log_info "  Primary Device : $SPI_DEVICE"
    log_info "  Test Speed     : $SPI_TEST_SPEED Hz"
    log_info "  High Speed     : $SPI_HIGH_SPEED Hz"
    log_info "  TX Data        : $SPI_TRANSFER_DATA"
    log_info "  Stability Loops: $SPI_STABILITY_LOOPS"
    log_info "  Runtime Dir    : $SPI_RUNTIME_DIR"

    #
    # Create runtime directory.
    #
    if ! spi_create_runtime_directory
    then
        log_info "ERROR: SPI runtime directory initialization failed."
        return 1
    fi

    #
    # Do not perform discovery here.
    #
    # SPI-001 is responsible for discovery.
    #
    spi_register_tests

    return 0
}

###############################################################################
# Module Initialization When Sourced
###############################################################################

spi_init

###############################################################################
# End Of File
###############################################################################
