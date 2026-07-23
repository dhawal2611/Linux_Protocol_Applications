#!/bin/bash
###############################################################################
# Module      : Long Duration Stress Validation
# Description : 24-Hour Stress Validation
###############################################################################

CPU_PID=0
MEM_PID=0
IPERF_PID=0

#
# STRESS-001
#
stress_001()
{
    log_info "[STRESS-001] Starting CPU Stress"

    stress-ng \
        --cpu ${STRESS_CPU_WORKERS} \
        --timeout ${STRESS_DURATION} \
        > logs/cpu_stress.log 2>&1 &

    CPU_PID=$!
}

#
# STRESS-002
#
stress_002()
{
    log_info "[STRESS-002] Starting Memory Stress"

    stress-ng \
        --vm ${STRESS_VM_WORKERS} \
        --vm-bytes ${STRESS_VM_BYTES} \
        --timeout ${STRESS_DURATION} \
        > logs/memory_stress.log 2>&1 &

    MEM_PID=$!
}

#
# STRESS-003
#
stress_003()
{
    log_info "[STRESS-003] Starting iperf3"

    iperf3 \
        -c ${IPERF3_SERVER} \
        -t ${STRESS_DURATION} \
        > logs/iperf3.log 2>&1 &

    IPERF_PID=$!
}

#
# STRESS-004
#
stress_004()
{
    log_info "[STRESS-004] Monitoring Temperature"

    while true
    do
        RUNNING=0

        kill -0 ${CPU_PID} 2>/dev/null && RUNNING=1
        kill -0 ${MEM_PID} 2>/dev/null && RUNNING=1
        kill -0 ${IPERF_PID} 2>/dev/null && RUNNING=1

        [ ${RUNNING} -eq 0 ] && break

        TEMP=$(cat ${THERMAL_ZONE})

        echo "$(date '+%F %T') Temperature : ${TEMP}" \
            | tee -a logs/temperature.log

        sleep ${TEMP_MONITOR_INTERVAL}
    done
}

#
# STRESS-005
#
stress_005()
{
    log_info "[STRESS-005] Waiting For Stress Completion"

    wait ${CPU_PID}
    CPU_STATUS=$?

    wait ${MEM_PID}
    MEM_STATUS=$?

    wait ${IPERF_PID}
    IPERF_STATUS=$?

    log_info "CPU Stress Exit Code    : ${CPU_STATUS}"
    log_info "Memory Stress Exit Code : ${MEM_STATUS}"
    log_info "iperf3 Exit Code        : ${IPERF_STATUS}"
}

#
# STRESS-006
#
stress_006()
{
    run_command \
        "STRESS-006" \
        "Check Kernel Errors" \
        "dmesg -T | grep -Ei 'error|fail|panic|oops'"
}

#
# STRESS-007
#
stress_007()
{
    run_command \
        "STRESS-007" \
        "Check Journal Errors" \
        "journalctl -p err"
}

#
# STRESS-008
#
stress_008()
{
    run_command \
        "STRESS-008" \
        "Verify System Uptime" \
        "uptime"
}

#
# STRESS-009
#
stress_009()
{
    run_command \
        "STRESS-009" \
        "Verify Memory Status" \
        "free -h"
}

#
# STRESS-010
#
stress_010()
{
    run_command \
        "STRESS-010" \
        "Verify Storage Devices" \
        "lsblk"
}

#
# STRESS-011
#
stress_011()
{
    run_command \
        "STRESS-011" \
        "Verify Mounted Filesystems" \
        "mount"
}

#
# STRESS-012
#
stress_012()
{
    run_command \
        "STRESS-012" \
        "Verify Network Interfaces" \
        "ip link"
}

#
# STRESS-013
#
stress_013()
{
    run_command \
        "STRESS-013" \
        "Filesystem Usage" \
        "df -h"
}

#
# STRESS-014
#
stress_014()
{
    run_command \
        "STRESS-014" \
        "CPU Utilization" \
        "top -bn1 | head -20"
}

#
# STRESS-015
#
stress_015()
{
    run_command \
        "STRESS-015" \
        "System Load" \
        "cat /proc/loadavg"
}

###############################################################################
# Execute Module
###############################################################################

run_test()
{
    log_info "====================================================="
    log_info "Starting Long Duration Stress Validation"
    log_info "Duration : ${STRESS_DURATION} Seconds"
    log_info "====================================================="

    stress_001
    stress_002
    stress_003

    stress_004

    stress_005

    stress_006
    stress_007
    stress_008
    stress_009
    stress_010
    stress_011
    stress_012
    stress_013
    stress_014
    stress_015

    log_info "====================================================="
    log_info "Long Duration Stress Validation Completed"
    log_info "====================================================="
}
