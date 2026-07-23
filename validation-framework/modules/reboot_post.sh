#!/bin/bash
###############################################################################
# Module      : Reboot Post Validation
# Description : Verify system after reboot
###############################################################################

#
# REBOOT-003
# Verify System Login
#
reboot_003()
{
    run_command \
        "REBOOT-003" \
        "Verify System Login" \
        "whoami"
}

#
# REBOOT-004
# Verify Filesystem
#
reboot_004()
{
    run_command \
        "REBOOT-004" \
        "Verify Filesystem Messages" \
        "dmesg | grep EXT4"
}

#
# REBOOT-005
# Verify Peripheral Devices
#
reboot_005()
{
    run_command \
        "REBOOT-005" \
        "Verify Storage Devices" \
        "lsblk"

    run_command \
        "REBOOT-006" \
        "Verify Network Interfaces" \
        "ip link"
}

###############################################################################
# Execute Post-Reboot Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Post-Reboot Validation"
    log_info "========================================="

    reboot_003
    reboot_004
    reboot_005

    log_info "========================================="
    log_info "Post-Reboot Validation Completed"
    log_info "========================================="
}
