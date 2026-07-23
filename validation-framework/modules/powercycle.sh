#!/bin/bash
###############################################################################
# Module      : Power Cycle Validation
# Description : Power Cycle Pre-Test Validation
###############################################################################

#
# POWER-001
# Manual Power Cycle
#
power_001()
{
    log_info "[POWER-001] Manual Power Cycle Test"

    echo ""
    echo "==========================================================="
    echo "               MANUAL TEST REQUIRED"
    echo "==========================================================="
    echo "1. Remove power from the board."
    echo "2. Wait for at least 10 seconds."
    echo "3. Re-apply power."
    echo "4. Allow Linux to boot completely."
    echo ""
    echo "After login execute:"
    echo ""
    echo "    ./validate.sh power_cycle_post"
    echo ""
    read -p "Press ENTER after reading the instructions..."
}

###############################################################################
# Execute Power Cycle Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Power Cycle Validation"
    log_info "========================================="

    power_001

    log_info "========================================="
    log_info "Power Cycle Validation Completed"
    log_info "========================================="
}
