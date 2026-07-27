#!/bin/bash
###############################################################################
# Module      : CPU Validation
# Description : CPU validation test cases
###############################################################################

#
# CPU-001
# Verify CPU Architecture and Cores
#
cpu_001()
{
    run_command \
        "CPU-001" \
        "Verify CPU Architecture and Cores" \
        "lscpu"

    echo "$++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "$COMMAND_OUTPUT" | grep "Architecture"
    echo "$++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    if echo "$COMMAND_OUTPUT" | grep -q "Architecture"
    then
        log_info "CPU Architecture Found"
    else
        log_fail "CPU-001 Output Validation"
    fi

}

#
# CPU-002
# Verify CPU Information
#
cpu_002()
{
    run_command \
        "CPU-002" \
        "Verify CPU Information" \
        "cat /proc/cpuinfo"

    if echo "$COMMAND_OUTPUT" | grep -q "^processor"
    then
        log_info "Processor Entries Found"
    else
        log_fail "CPU-002 Output Validation"
    fi

}

#
# CPU-003
# Verify Online CPUs
#
cpu_003()
{
    run_command \
        "CPU-003" \
        "Verify Online CPUs" \
        "cat /sys/devices/system/cpu/online"
}

#
# CPU-004
# Verify CPU Governor
#
cpu_004()
{
    run_command \
        "CPU-004" \
        "Verify CPU Governor" \
        "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
}

###############################################################################
# Execute all CPU Test Cases
###############################################################################
run_test()
{
    log_info "========================================="
    log_info "Starting CPU Validation"
    log_info "========================================="

    cpu_001
    cpu_002
    cpu_003
    cpu_004

    log_info "========================================="
    log_info "CPU Validation Completed"
    log_info "========================================="
}
