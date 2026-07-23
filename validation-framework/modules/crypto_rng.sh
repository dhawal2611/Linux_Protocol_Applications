#!/bin/bash
###############################################################################
# Module      : Crypto RNG Validation
# Description : Hardware Random Number Generator Validation
###############################################################################

#
# CRYPTO-RNG-001
# Verify RNG Registration
#
crypto_rng_001()
{
    run_command \
        "CRYPTO-RNG-001" \
        "Verify RNG Registration" \
        "cat /proc/crypto | grep -i rng"
}

#
# CRYPTO-RNG-002
# Verify Hardware RNG Device
#
crypto_rng_002()
{
    run_command \
        "CRYPTO-RNG-002" \
        "Verify Hardware RNG Device" \
        "ls -l ${HWRNG_DEVICE}"
}

#
# CRYPTO-RNG-003
# Read Random Data
#
crypto_rng_003()
{
    run_command \
        "CRYPTO-RNG-003" \
        "Read Random Data From HWRNG" \
        "dd if=${HWRNG_DEVICE} of=${RNG_OUTPUT_FILE} bs=1K count=${RNG_DATA_SIZE_KB}"
}

#
# CRYPTO-RNG-004
# Verify Generated File
#
crypto_rng_004()
{
    run_command \
        "CRYPTO-RNG-004" \
        "Verify Generated Random File" \
        "ls -lh ${RNG_OUTPUT_FILE}"
}

#
# CRYPTO-RNG-005
# Check Entropy
#
crypto_rng_005()
{
    run_command \
        "CRYPTO-RNG-005" \
        "Check Kernel Entropy" \
        "cat /proc/sys/kernel/random/entropy_avail"
}

#
# CRYPTO-RNG-006
# Validate Entropy Threshold
#
crypto_rng_006()
{
    run_command \
        "CRYPTO-RNG-006" \
        "Validate Entropy Threshold (${MIN_ENTROPY})" \
        "[ \$(cat /proc/sys/kernel/random/entropy_avail) -ge ${MIN_ENTROPY} ]"
}

#
# CRYPTO-RNG-007
# Display Random Device Information
#
crypto_rng_007()
{
    run_command \
        "CRYPTO-RNG-007" \
        "Display Random Device Information" \
        "cat /proc/sys/kernel/random/uuid"
}

#
# CRYPTO-RNG-008
# Cleanup
#
crypto_rng_008()
{
    run_command \
        "CRYPTO-RNG-008" \
        "Cleanup Random File" \
        "rm -f ${RNG_OUTPUT_FILE}"
}

###############################################################################
# Execute Crypto RNG Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Crypto RNG Validation"
    log_info "========================================="

    crypto_rng_001
    crypto_rng_002
    crypto_rng_003
    crypto_rng_004
    crypto_rng_005
    crypto_rng_006
    crypto_rng_007
    crypto_rng_008

    log_info "========================================="
    log_info "Crypto RNG Validation Completed"
    log_info "========================================="
}
