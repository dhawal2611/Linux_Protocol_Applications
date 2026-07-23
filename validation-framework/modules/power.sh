#!/bin/bash
###############################################################################
# Module      : Power Validation
# Description : Power rail validation test cases
###############################################################################

#
# POWER-001
# Check Regulator Messages
#
power_001()
{
    run_command \
        "POWER-001" \
        "Check Regulator Messages" \
        "dmesg | grep -i regulator"
}

#
# POWER-002
# Measure Power Rails using Multimeter
#
power_002()
{
    log_info "[POWER-002] Measure Power Rails using Multimeter"

    echo "=================================================================="
    echo "MANUAL TEST REQUIRED"
    echo "=================================================================="
    echo "Measure all board power rails using a calibrated multimeter."
    echo ""
    echo "Expected Result:"
    echo "  - All power rails are within the specified tolerance."
    echo ""
    echo "Press 'p' for PASS"
    echo "Press 'f' for FAIL"
    echo "=================================================================="

    while true
    do
        read -rp "Enter Result (p/f): " RESULT

        case "$RESULT" in
            p|P)
                log_pass "POWER-002"
                break
                ;;
            f|F)
                log_fail "POWER-002"
                break
                ;;
            *)
                echo "Invalid input. Please enter p or f."
                ;;
        esac
    done
}

###############################################################################
# Execute all Power Test Cases
###############################################################################
run_test()
{
    log_info "========================================="
    log_info "Starting Power Validation"
    log_info "========================================="

    power_001
    power_002

    log_info "========================================="
    log_info "Power Validation Completed"
    log_info "========================================="
}
