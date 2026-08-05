#!/bin/bash
###############################################################################
# File        : spinor.sh
# Description : SPI NOR Flash Validation Module
###############################################################################

MODULE_NAME="SPINOR"
MODULE_DESCRIPTION="SPI NOR Flash Validation"

###############################################################################
# Runtime Configuration
###############################################################################

SPINOR_DEVICE="${SPINOR_DEVICE:-/dev/mtd0}"
SPINOR_MTD_NAME=""

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    cat
    grep
    awk
    sed
    tr
    head
    tail
    ls
    dd
    dmesg
)

###############################################################################
# Helper Functions
###############################################################################

spinor_device_exists()
{
    [ -c "$SPINOR_DEVICE" ] || [ -b "$SPINOR_DEVICE" ]
}

spinor_get_mtd_number()
{
    echo "$SPINOR_DEVICE" | sed 's#^/dev/mtd##'
}

spinor_get_mtd_name()
{
    local MTD_NUMBER

    MTD_NUMBER=$(spinor_get_mtd_number)

    awk -v mtd="mtd${MTD_NUMBER}:" '$1 == mtd {gsub(/"/, "", $4); print $4; exit}' /proc/mtd 2>/dev/null
}

spinor_get_sysfs_path()
{
    local MTD_NUMBER

    MTD_NUMBER=$(spinor_get_mtd_number)

    echo "/sys/class/mtd/mtd${MTD_NUMBER}"
}

spinor_get_sysfs_value()
{
    local FILE="$1"

    if [ -f "$FILE" ]
    then
        cat "$FILE" 2>/dev/null
    fi
}

###############################################################################
# SPINOR-001 : Enumerate MTD Devices
###############################################################################

spinor_001()
{
    local MTD_NUMBER

    log_info "[SPINOR-001] Enumerate MTD Devices"

    run_command \
        "SPINOR-001" \
        "Enumerate MTD Devices" \
        "cat /proc/mtd"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to read /proc/mtd."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="No MTD devices were reported."
        test_fail
        return
    fi

    MTD_NUMBER=$(spinor_get_mtd_number)

    if ! echo "$COMMAND_OUTPUT" | awk -v mtd="mtd${MTD_NUMBER}:" '$1 == mtd {found=1} END {exit !found}'
    then
        TEST_MESSAGE="Configured SPI NOR device ${SPINOR_DEVICE} was not found in /proc/mtd."
        test_fail
        return
    fi

    TEST_MESSAGE="MTD device ${SPINOR_DEVICE} is present in /proc/mtd."
    test_pass
}

###############################################################################
# SPINOR-002 : Read MTD Information
###############################################################################

spinor_002()
{
    log_info "[SPINOR-002] Read MTD Information"

    if ! command -v mtdinfo >/dev/null 2>&1
    then
        TEST_ID="SPINOR-002"
        LAST_COMMAND="mtdinfo \"$SPINOR_DEVICE\""
        COMMAND_OUTPUT="mtdinfo utility is not installed."
        TEST_MESSAGE="mtdinfo utility is not installed."
        test_skip
        return
    fi

    run_command \
        "SPINOR-002" \
        "Read MTD Information" \
        "mtdinfo \"$SPINOR_DEVICE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to read MTD information for ${SPINOR_DEVICE}."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="mtdinfo returned empty output."
        test_fail
        return
    fi

    TEST_MESSAGE="MTD geometry and configuration information read successfully."
    test_pass
}

###############################################################################
# SPINOR-003 : Verify SPI NOR MTD Device Node
###############################################################################

spinor_003()
{
    local MTD_NUMBER
    local MTD_NAME

    log_info "[SPINOR-003] Verify SPI NOR MTD Device Node"

    run_command \
        "SPINOR-003" \
        "Verify SPI NOR MTD Device Node" \
        "ls -l \"$SPINOR_DEVICE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI NOR device node ${SPINOR_DEVICE} does not exist."
        test_fail
        return
    fi

    if ! spinor_device_exists
    then
        TEST_MESSAGE="Configured SPI NOR device ${SPINOR_DEVICE} is not a valid device node."
        test_fail
        return
    fi

    MTD_NUMBER=$(spinor_get_mtd_number)
    MTD_NAME=$(spinor_get_mtd_name)
    SPINOR_MTD_NAME="$MTD_NAME"

    TEST_MESSAGE="Device=${SPINOR_DEVICE}, MTD=mtd${MTD_NUMBER}, Name=${MTD_NAME:-N/A}"
    test_pass
}

###############################################################################
# SPINOR-004 : Dump SPI NOR Content
# Read-only operation. No erase or write operation is performed.
###############################################################################

spinor_004()
{
    log_info "[SPINOR-004] Dump SPI NOR Content"

    if ! spinor_device_exists
    then
        TEST_MESSAGE="SPI NOR device ${SPINOR_DEVICE} does not exist."
        test_fail
        return
    fi

    if ! command -v hexdump >/dev/null 2>&1
    then
        TEST_MESSAGE="hexdump utility is not installed."
        test_skip
        return
    fi

    run_command \
        "SPINOR-004" \
        "Dump SPI NOR Content" \
        "hexdump -C \"$SPINOR_DEVICE\" | head"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to read SPI NOR content from ${SPINOR_DEVICE}."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="SPI NOR read returned empty output."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI NOR content is readable."
    test_pass
}

###############################################################################
# SPINOR-005 : Check SPI NOR Kernel Messages
###############################################################################

spinor_005()
{
    log_info "[SPINOR-005] Check SPI NOR Kernel Messages"

    run_command \
        "SPINOR-005" \
        "Check SPI NOR Kernel Messages" \
        "dmesg | grep -Ei 'spi|nor|mtd|jedec'"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="No SPI NOR related kernel messages were found."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="SPI NOR kernel message output is empty."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI/NOR/MTD related kernel messages were detected."
    test_pass
}

###############################################################################
# SPINOR-006 : Verify SPI NOR Sysfs Information
###############################################################################

spinor_006()
{
    local SYSFS_PATH
    local NAME=""
    local SIZE=""
    local ERASESIZE=""
    local TYPE=""

    log_info "[SPINOR-006] Verify SPI NOR Sysfs Information"

    SYSFS_PATH=$(spinor_get_sysfs_path)

    run_command \
        "SPINOR-006" \
        "Verify SPI NOR Sysfs Information" \
        "ls -l \"$SYSFS_PATH\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI NOR sysfs entry ${SYSFS_PATH} does not exist."
        test_fail
        return
    fi

    NAME=$(spinor_get_sysfs_value "${SYSFS_PATH}/name")
    SIZE=$(spinor_get_sysfs_value "${SYSFS_PATH}/size")
    ERASESIZE=$(spinor_get_sysfs_value "${SYSFS_PATH}/erasesize")
    TYPE=$(spinor_get_sysfs_value "${SYSFS_PATH}/type")

    if [ -z "$SIZE" ]
    then
        TEST_MESSAGE="SPI NOR sysfs size information is unavailable."
        test_fail
        return
    fi

    TEST_MESSAGE="Name=${NAME:-N/A}, Size=${SIZE}, EraseSize=${ERASESIZE:-N/A}, Type=${TYPE:-N/A}"
    test_pass
}

###############################################################################
# SPINOR-007 : Final SPI NOR Read Verification
# Read-only verification. No flash modification is performed.
###############################################################################

spinor_007()
{
    log_info "[SPINOR-007] Final SPI NOR Read Verification"

    if ! spinor_device_exists
    then
        TEST_MESSAGE="SPI NOR device ${SPINOR_DEVICE} does not exist."
        test_fail
        return
    fi

    run_command \
        "SPINOR-007" \
        "Final SPI NOR Read Verification" \
        "dd if=\"$SPINOR_DEVICE\" of=/dev/null bs=1K count=1"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SPI NOR read verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="SPI NOR read operation completed successfully."
    test_pass
}

###############################################################################
# Register SPI NOR Tests
###############################################################################

spinor_register_tests()
{
    register_test \
        -i "SPINOR-001" \
        -f spinor_001 \
        -n "Enumerate MTD Devices" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "spinor,mtd,proc" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Enumerate MTD devices and verify the configured SPI NOR device."

    register_test \
        -i "SPINOR-002" \
        -f spinor_002 \
        -n "Read MTD Information" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "spinor,mtd,mtdinfo,geometry" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Read SPI NOR MTD geometry and configuration information."

    register_test \
        -i "SPINOR-003" \
        -f spinor_003 \
        -n "Verify SPI NOR MTD Device Node" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "spinor,mtd,device,node" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify that the configured SPI NOR MTD device node exists."

    register_test \
        -i "SPINOR-004" \
        -f spinor_004 \
        -n "Dump SPI NOR Content" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "spinor,mtd,read,hexdump" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Read and display the beginning of SPI NOR contents without modifying flash."

    register_test \
        -i "SPINOR-005" \
        -f spinor_005 \
        -n "Check SPI NOR Kernel Messages" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "spinor,spi,nor,mtd,dmesg" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SPI NOR related kernel messages."

    register_test \
        -i "SPINOR-006" \
        -f spinor_006 \
        -n "Verify SPI NOR Sysfs Information" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "spinor,mtd,sysfs,size,erase" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SPI NOR MTD information exposed through sysfs."

    register_test \
        -i "SPINOR-007" \
        -f spinor_007 \
        -n "Final SPI NOR Read Verification" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "spinor,mtd,read,validation" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Perform a final read-only verification of the SPI NOR device."
}

###############################################################################
# Module Initialization
###############################################################################

spinor_init()
{
    log_info "========================================="
    log_info "Starting SPI NOR Validation"
    log_info "========================================="

    if [ -z "$SPINOR_DEVICE" ]
    then
        TEST_MESSAGE="SPINOR_DEVICE is not configured."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    log_info "Configured SPI NOR Device : $SPINOR_DEVICE"

    spinor_register_tests

    return 0
}

###############################################################################
# Module Initialization When Sourced
###############################################################################

spinor_init

###############################################################################
# End Of File
###############################################################################
