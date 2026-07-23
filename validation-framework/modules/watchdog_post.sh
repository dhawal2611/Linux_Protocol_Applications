#!/bin/bash
###############################################################################
# Module      : Watchdog Post Validation
# Description : Verify system after watchdog reset
###############################################################################

#
# WDT-005
# Verify System Boot After Watchdog Reset
#
wdt_005()
{
    run_command \
        "WDT-005" \
        "Verify System Boot After Watchdog Reset" \
        "uptime"
}

#
# WDT-006
# Verify Watchdog Driver
#
wdt_006()
{
    run_command \
        "WDT-006" \
        "Verify Watchdog Driver After Boot" \
        "dmesg | grep -i watchdog"
}

###############################################################################
# Execute Watchdog Post Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Watchdog Post Validation"
    log_info "========================================="

    wdt_005
    wdt_006

    log_info "========================================="
    log_info "Watchdog Post Validation Completed"
    log_info "========================================="
}
