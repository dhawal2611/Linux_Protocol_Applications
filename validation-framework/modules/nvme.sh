#!/bin/bash
###############################################################################
# Module      : NVMe Validation
# Description : NVMe SSD validation test cases
###############################################################################

#
# NVME-001
# Enumerate NVMe Devices
#
nvme_001()
{
    run_command \
        "NVME-001" \
        "Enumerate NVMe Devices" \
        "nvme list"
}

#
# NVME-002
# Read SMART Log
#
nvme_002()
{
    run_command \
        "NVME-002" \
        "Read SMART Log" \
        "nvme smart-log /dev/nvme0"
}

#
# NVME-003
# Run FIO Benchmark
#
nvme_003()
{
    run_command \
        "NVME-003" \
        "Run FIO Read/Write Benchmark" \
        "fio --name=rw --filename=/dev/nvme0n1 --rw=randrw --runtime=60"
}

#
# NVME-004
# Check NVMe Temperature
#
nvme_004()
{
    run_command \
        "NVME-004" \
        "Check NVMe Temperature" \
        "nvme smart-log /dev/nvme0 | grep -i temperature"
}

###############################################################################
# Execute all NVMe Test Cases
###############################################################################
run_test()
{
    log_info "========================================="
    log_info "Starting NVMe Validation"
    log_info "========================================="

    nvme_001
    nvme_002
    nvme_003
    nvme_004

    log_info "========================================="
    log_info "NVMe Validation Completed"
    log_info "========================================="
}
