#!/bin/bash
###############################################################################
# Module      : SATA Validation
# Description : SATA storage validation test cases
###############################################################################

#
# SATA-001
# Check SATA Kernel Messages
#
sata_001()
{
    run_command \
        "SATA-001" \
        "Check SATA Kernel Messages" \
        "dmesg | grep -i sata"
}

#
# SATA-002
# List SATA Disk
#
sata_002()
{
    run_command \
        "SATA-002" \
        "List SATA Disk" \
        "lsblk"
}

#
# SATA-003
# Run SATA Throughput Test
#
sata_003()
{
    run_command \
        "SATA-003" \
        "Run SATA Throughput Test" \
        "hdparm -tT /dev/sda"
}

#
# SATA-004
# Write Test File to SATA Disk
#
sata_004()
{
    run_command \
        "SATA-004" \
        "Write Test File to SATA Disk" \
        "dd if=/dev/zero of=/mnt/test.bin bs=1M count=100"
}

###############################################################################
# Execute all SATA Test Cases
###############################################################################
run_test()
{
    log_info "========================================="
    log_info "Starting SATA Validation"
    log_info "========================================="

    sata_001
    sata_002
    sata_003
    sata_004

    log_info "========================================="
    log_info "SATA Validation Completed"
    log_info "========================================="
}
