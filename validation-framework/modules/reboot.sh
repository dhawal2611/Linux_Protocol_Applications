#!/bin/bash
###############################################################################
# Module      : Reboot Validation
# Description : System reboot validation test cases
###############################################################################

#
# REBOOT-001
# Capture System Uptime
#
reboot_001()
{
    run_command \
        "REBOOT-001" \
        "Capture System Uptime" \
        "uptime"
}

#
# REBOOT-002
# Initiate System Reboot
#
reboot_002()
{
    log_info "[REBOOT-002] Manual Reboot Test"

    echo ""
    echo "==========================================================="
    echo "               MANUAL TEST REQUIRED"
    echo "==========================================================="
    echo "The system will reboot."
    echo ""
    echo "After the board boots successfully, execute:"
    echo ""
    echo "    ./validate.sh reboot_post"
    echo ""
    read -p "Press ENTER to reboot..."

    run_command \
        "REBOOT-002" \
        "Initiate System Reboot" \
        "reboot"
}

###############################################################################
# Execute Reboot Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Reboot Validation"
    log_info "========================================="

    reboot_001
    reboot_002

    log_info "========================================="
    log_info "Reboot Validation Completed"
    log_info "========================================="
}
