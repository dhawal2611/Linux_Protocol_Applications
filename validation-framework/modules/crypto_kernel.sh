#!/bin/bash
###############################################################################
# Module      : Crypto Kernel Validation
# Description : Validate Linux Kernel Crypto Framework
###############################################################################

#
# CRYPTO-KERNEL-001
# Check Kernel Boot Messages
#
crypto_kernel_001()
{
    run_command \
        "CRYPTO-KERNEL-001" \
        "Check Kernel Crypto Messages" \
        "dmesg | grep -i ${CRYPTO_DMESG_PATTERN}"
}

#
# CRYPTO-KERNEL-002
# Check Loaded Crypto Modules
#
crypto_kernel_002()
{
    run_command \
        "CRYPTO-KERNEL-002" \
        "Check Loaded Crypto Modules" \
        "lsmod | grep ${CRYPTO_MODULE_PATTERN}"
}

#
# CRYPTO-KERNEL-003
# Verify Kernel Crypto Capabilities
#
crypto_kernel_003()
{
    run_command \
        "CRYPTO-KERNEL-003" \
        "Verify Kernel Crypto Capabilities" \
        "cat ${PROC_CRYPTO}"
}

#
# CRYPTO-KERNEL-004
# Verify Crypto API Count
#
crypto_kernel_004()
{
    run_command \
        "CRYPTO-KERNEL-004" \
        "Count Registered Crypto Algorithms" \
        "grep '^name' ${PROC_CRYPTO} | wc -l"
}

###############################################################################
# Execute Crypto Kernel Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Crypto Kernel Validation"
    log_info "========================================="

    crypto_kernel_001
    crypto_kernel_002
    crypto_kernel_003
    crypto_kernel_004

    log_info "========================================="
    log_info "Crypto Kernel Validation Completed"
    log_info "========================================="
}
