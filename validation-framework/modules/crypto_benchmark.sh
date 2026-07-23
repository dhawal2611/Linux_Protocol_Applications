#!/bin/bash
###############################################################################
# Module      : Crypto Benchmark Validation
# Description : OpenSSL Crypto Performance Validation
###############################################################################

#
# CRYPTO-BENCH-001
# AES-128 Benchmark
#
crypto_bench_001()
{
    run_command \
        "CRYPTO-BENCH-001" \
        "AES-128 CBC Benchmark" \
        "openssl speed -seconds ${OPENSSL_BENCH_TIME} -evp aes-128-cbc"
}

#
# CRYPTO-BENCH-002
# AES-256 Benchmark
#
crypto_bench_002()
{
    run_command \
        "CRYPTO-BENCH-002" \
        "AES-256 CBC Benchmark" \
        "openssl speed -seconds ${OPENSSL_BENCH_TIME} -evp aes-256-cbc"
}

#
# CRYPTO-BENCH-003
# SHA1 Benchmark
#
crypto_bench_003()
{
    run_command \
        "CRYPTO-BENCH-003" \
        "SHA1 Benchmark" \
        "openssl speed -seconds ${OPENSSL_BENCH_TIME} sha1"
}

#
# CRYPTO-BENCH-004
# SHA256 Benchmark
#
crypto_bench_004()
{
    run_command \
        "CRYPTO-BENCH-004" \
        "SHA256 Benchmark" \
        "openssl speed -seconds ${OPENSSL_BENCH_TIME} sha256"
}

#
# CRYPTO-BENCH-005
# RSA2048 Benchmark
#
crypto_bench_005()
{
    run_command \
        "CRYPTO-BENCH-005" \
        "RSA2048 Benchmark" \
        "openssl speed -seconds ${OPENSSL_BENCH_TIME} rsa2048"
}

#
# CRYPTO-BENCH-006
# RSA4096 Benchmark
#
crypto_bench_006()
{
    run_command \
        "CRYPTO-BENCH-006" \
        "RSA4096 Benchmark" \
        "openssl speed -seconds ${OPENSSL_BENCH_TIME} rsa4096"
}

#
# CRYPTO-BENCH-007
# Verify SHA Driver Logs
#
crypto_bench_007()
{
    run_command \
        "CRYPTO-BENCH-007" \
        "Check SHA Driver Logs" \
        "dmesg | grep -i ${SHA_LOG_PATTERN}"
}

#
# CRYPTO-BENCH-008
# Vendor HW Crypto Benchmark
#
crypto_bench_008()
{
    if [ "${ENABLE_HW_CRYPTO_TEST}" -eq 1 ]
    then
        run_command \
            "CRYPTO-BENCH-008" \
            "Vendor Hardware Crypto Benchmark" \
            "${HW_CRYPTO_CMD}"
    else
        log_info "[CRYPTO-BENCH-008] Vendor benchmark skipped."
    fi
}

###############################################################################
# Execute Crypto Benchmark Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Crypto Benchmark Validation"
    log_info "========================================="

    crypto_bench_001
    crypto_bench_002
    crypto_bench_003
    crypto_bench_004
    crypto_bench_005
    crypto_bench_006
    crypto_bench_007
    crypto_bench_008

    log_info "========================================="
    log_info "Crypto Benchmark Validation Completed"
    log_info "========================================="
}
