#!/bin/bash
###############################################################################
# Module      : SPI NOR Validation
# Description : SPI NOR Flash validation test cases
###############################################################################

#
# SPINOR-001
# Enumerate MTD Devices
#
spinor_001()
{
    run_command \
        "SPINOR-001" \
        "Enumerate MTD Devices" \
        "cat /proc/mtd"
}

#
# SPINOR-002
# Read MTD Information
#
spinor_002()
{
    run_command \
        "SPINOR-002" \
        "Read MTD Information" \
        "mtdinfo /dev/mtd0"
}

#
# SPINOR-003
# Dump SPI NOR Content
#
spinor_003()
{
    run_command \
        "SPINOR-003" \
        "Dump SPI NOR Content" \
        "hexdump -C /dev/mtd0 | head"
}

###############################################################################
# Execute all SPI NOR Test Cases
###############################################################################
run_test()
{
    log_info "========================================="
    log_info "Starting SPI NOR Validation"
    log_info "========================================="

    spinor_001
    spinor_002
    spinor_003

    log_info "========================================="
    log_info "SPI NOR Validation Completed"
    log_info "========================================="
}
