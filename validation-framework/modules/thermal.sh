#!/bin/bash
###############################################################################
# Module      : Thermal Validation
# Description : Thermal validation test cases
###############################################################################

#
# THERMAL-001
# Read Initial Thermal Zones
#
thermal_001()
{
    run_command \
        "THERMAL-001" \
        "Read Initial Thermal Zones" \
        "cat /sys/class/thermal/thermal_zone*/temp"
}

#
# THERMAL-002
# Run CPU Stress for 5 Minutes
#
thermal_002()
{
    run_command \
        "THERMAL-002" \
        "Run CPU Stress for 5 Minutes" \
        "stress-ng --cpu 4 --timeout 300"
}

#
# THERMAL-003
# Read Thermal Zones After Stress
#
thermal_003()
{
    run_command \
        "THERMAL-003" \
        "Read Thermal Zones After Stress" \
        "cat /sys/class/thermal/thermal_zone*/temp"
}

###############################################################################
# Execute all Thermal Test Cases
###############################################################################
run_test()
{
    log_info "========================================="
    log_info "Starting Thermal Validation"
    log_info "========================================="

    thermal_001
    thermal_002
    thermal_003

    log_info "========================================="
    log_info "Thermal Validation Completed"
    log_info "========================================="
}
