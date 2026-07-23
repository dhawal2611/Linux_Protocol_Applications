#!/bin/bash
###############################################################################
# Module      : Watchdog Validation
# Description : Linux Watchdog validation test cases
###############################################################################

#
# WDT-001
# Verify Watchdog Device
#
wdt_001()
{
    run_command \
        "WDT-001" \
        "Verify Watchdog Device" \
        "ls -l ${WATCHDOG_DEVICE}*"
}

#
# WDT-002
# Check Watchdog Driver Status
#
wdt_002()
{
    run_command \
        "WDT-002" \
        "Check Watchdog Driver Status" \
        "dmesg | grep -i watchdog"
}

#
# WDT-003
# Configure Watchdog Timeout
#
wdt_003()
{
    run_command \
        "WDT-003" \
        "Configure Watchdog Timeout (${WATCHDOG_TIMEOUT} Seconds)" \
        "echo ${WATCHDOG_TIMEOUT} > /proc/sys/kernel/watchdog_thresh"
}

#
# WDT-004
# Trigger Watchdog Expiry
#
wdt_004()
{
    log_info "[WDT-004] Manual Watchdog Reset Test"

    echo ""
    echo "==========================================================="
    echo "               MANUAL TEST REQUIRED"
    echo "==========================================================="
    echo "The watchdog will be triggered."
    echo ""
    echo "Expected Result:"
    echo "  1. System should reboot automatically."
    echo "  2. No kernel panic should occur."
    echo "  3. Boot should complete successfully."
    echo ""
    read -p "Press ENTER to trigger the watchdog..."

    run_command \
        "WDT-004" \
        "Trigger Watchdog Expiry" \
        "echo V > ${WATCHDOG_DEVICE}"
}

###############################################################################
# Execute all Watchdog Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Watchdog Validation"
    log_info "========================================="

    wdt_001
    wdt_002
    wdt_003
    wdt_004

    log_info "========================================="
    log_info "Watchdog Validation Completed"
    log_info "========================================="
}
