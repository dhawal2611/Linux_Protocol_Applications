#!/bin/bash
###############################################################################
# Module      : Crypto Stress Validation
# Description : Long Duration Crypto Validation
###############################################################################

AES_PID=0
SHA_PID=0

#
# CRYPTO-STRESS-001
# Start AES Benchmark
#
crypto_stress_001()
{
    log_info "[CRYPTO-STRESS-001] Starting AES Benchmark"

    openssl speed \
        -seconds ${CRYPTO_STRESS_DURATION} \
        -evp ${CRYPTO_STRESS_ALGORITHM} \
        > ${CRYPTO_LOG_DIR}/crypto_aes.log 2>&1 &

    AES_PID=$!
}

#
# CRYPTO-STRESS-002
# Start SHA Benchmark
#
crypto_stress_002()
{
    if [ "${ENABLE_SHA_STRESS}" -eq 1 ]
    then
        log_info "[CRYPTO-STRESS-002] Starting SHA Benchmark"

        openssl speed \
            -seconds ${CRYPTO_STRESS_DURATION} \
            ${CRYPTO_SHA_ALGORITHM} \
            > ${CRYPTO_LOG_DIR}/crypto_sha.log 2>&1 &

        SHA_PID=$!
    fi
}

#
# CRYPTO-STRESS-003
# Monitor Temperature
#
crypto_stress_003()
{
    log_info "[CRYPTO-STRESS-003] Monitoring Temperature"

    while true
    do
        RUNNING=0

        kill -0 ${AES_PID} 2>/dev/null && RUNNING=1

        if [ "${ENABLE_SHA_STRESS}" -eq 1 ]
        then
            kill -0 ${SHA_PID} 2>/dev/null && RUNNING=1
        fi

        [ ${RUNNING} -eq 0 ] && break

        TEMP=$(cat ${CRYPTO_THERMAL_ZONE})

        echo "$(date '+%F %T') Temperature : ${TEMP}" \
            | tee -a ${CRYPTO_LOG_DIR}/crypto_temperature.log

        sleep ${CRYPTO_TEMP_INTERVAL}
    done
}

#
# CRYPTO-STRESS-004
# Wait for Completion
#
crypto_stress_004()
{
    wait ${AES_PID}

    if [ "${ENABLE_SHA_STRESS}" -eq 1 ]
    then
        wait ${SHA_PID}
    fi
}

#
# CRYPTO-STRESS-005
# Check Crypto Driver Logs
#
crypto_stress_005()
{
    run_command \
        "CRYPTO-STRESS-005" \
        "Check Crypto Driver Logs" \
        "dmesg | grep -i crypto"
}

#
# CRYPTO-STRESS-006
# Check SHA Driver Logs
#
crypto_stress_006()
{
    run_command \
        "CRYPTO-STRESS-006" \
        "Check SHA Driver Logs" \
        "dmesg | grep -i sha"
}

#
# CRYPTO-STRESS-007
# Check Kernel Errors
#
crypto_stress_007()
{
    run_command \
        "CRYPTO-STRESS-007" \
        "Kernel Errors" \
        "dmesg -T | grep -Ei 'error|fail|panic|oops'"
}

#
# CRYPTO-STRESS-008
# Check Journal Errors
#
crypto_stress_008()
{
    run_command \
        "CRYPTO-STRESS-008" \
        "Journal Errors" \
        "journalctl -p err"
}

#
# CRYPTO-STRESS-009
# Verify System Uptime
#
crypto_stress_009()
{
    run_command \
        "CRYPTO-STRESS-009" \
        "System Uptime" \
        "uptime"
}

#
# CRYPTO-STRESS-010
# Verify CPU Usage
#
crypto_stress_010()
{
    run_command \
        "CRYPTO-STRESS-010" \
        "CPU Utilization" \
        "top -bn1 | head -20"
}

#
# CRYPTO-STRESS-011
# Verify Memory Usage
#
crypto_stress_011()
{
    run_command \
        "CRYPTO-STRESS-011" \
        "Memory Usage" \
        "free -h"
}

#
# CRYPTO-STRESS-012
# Verify Load Average
#
crypto_stress_012()
{
    run_command \
        "CRYPTO-STRESS-012" \
        "System Load" \
        "cat /proc/loadavg"
}

###############################################################################
# Execute Module
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Crypto Stress Validation"
    log_info "Duration : ${CRYPTO_STRESS_DURATION} Seconds"
    log_info "========================================="

    crypto_stress_001
    crypto_stress_002
    crypto_stress_003
    crypto_stress_004

    crypto_stress_005
    crypto_stress_006
    crypto_stress_007
    crypto_stress_008
    crypto_stress_009
    crypto_stress_010
    crypto_stress_011
    crypto_stress_012

    log_info "========================================="
    log_info "Crypto Stress Validation Completed"
    log_info "========================================="
}
