#!/bin/bash
###############################################################################
# Module      : eMMC Validation
# Description : eMMC validation test cases
###############################################################################

#
# EMMC-001
# List Block Devices
#
emmc_001()
{
    run_command \
        "EMMC-001" \
        "List Block Devices" \
        "lsblk"
}

#
# EMMC-002
# Check eMMC Partitions
#
emmc_002()
{
    run_command \
        "EMMC-002" \
        "Check eMMC Partitions" \
        "fdisk -l /dev/mmcblk0"
}

#
# EMMC-003
# Read eMMC EXT_CSD Register
#
emmc_003()
{
    run_command \
        "EMMC-003" \
        "Read eMMC EXT_CSD Register" \
        "mmc extcsd read /dev/mmcblk0"
}

#
# EMMC-004
# Write Test File to eMMC
#
emmc_004()
{
    run_command \
        "EMMC-004" \
        "Write Test File to eMMC" \
        "dd if=/dev/zero of=/tmp/emmc.bin bs=1M count=100"
}

#
# EMMC-005
# Measure eMMC Read Performance
#
emmc_005()
{
    run_command \
        "EMMC-005" \
        "Measure eMMC Read Performance" \
        "hdparm -tT /dev/mmcblk0"
}

###############################################################################
# Execute all eMMC Test Cases
###############################################################################
run_test()
{
    log_info "========================================="
    log_info "Starting eMMC Validation"
    log_info "========================================="

    emmc_001
    emmc_002
    emmc_003
    emmc_004
    emmc_005

    log_info "========================================="
    log_info "eMMC Validation Completed"
    log_info "========================================="
}
