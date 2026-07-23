#!/bin/bash
###############################################################################
# Module      : Journald Post Validation
# Description : Verify previous boot journal
###############################################################################

#
# JOURNALD-010
# Verify Previous Boot Logs
#
journald_010()
{
    run_command \
        "JOURNALD-010" \
        "Verify Previous Boot Logs" \
        "journalctl -b -1"
}

###############################################################################
# Execute Journald Post Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Journald Post Validation"
    log_info "========================================="

    journald_010

    log_info "========================================="
    log_info "Journald Post Validation Completed"
    log_info "========================================="
}
