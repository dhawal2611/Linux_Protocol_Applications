#!/bin/bash
###############################################################################
# Module      : Suspend / Resume Validation
# Description : Suspend and Resume validation test cases
###############################################################################

#
# SUSPEND-001
# Check Supported Power States
#
suspend_001()
{
    run_command \
        "SUSPEND-001" \
        "Check Supported Power States" \
        "cat /sys/power/state"
}

#
# SUSPEND-002
# Configure RTC Wake Alarm
#
suspend_002()
{
    run_command \
        "SUSPEND-002" \
        "Configure RTC Wake Alarm (${SUSPEND_WAKEUP_TIME} Seconds)" \
        "echo 0 > /sys/class/rtc/${RTC_DEVICE}/wakealarm && \
         echo +${SUSPEND_WAKEUP_TIME} > /sys/class/rtc/${RTC_DEVICE}/wakealarm"
}

#
# SUSPEND-003
# Verify RTC Wake Alarm
#
suspend_003()
{
    run_command \
        "SUSPEND-003" \
        "Verify RTC Wake Alarm" \
        "echo 'Alarm Epoch:' && \
         cat /sys/class/rtc/${RTC_DEVICE}/wakealarm && \
         echo '' && \
         echo 'Alarm Time:' && \
         date -d @\$(cat /sys/class/rtc/${RTC_DEVICE}/wakealarm)"
}

#
# SUSPEND-004
# Enter Suspend Mode
#
suspend_004()
{
    log_info "[SUSPEND-004] System will enter Suspend Mode"

    echo ""
    echo "==========================================================="
    echo "The board will suspend now."
    echo "It should automatically wake after ${SUSPEND_WAKEUP_TIME} seconds."
    echo "==========================================================="
    echo ""

    run_command \
        "SUSPEND-004" \
        "Enter Suspend Mode" \
        "echo mem > /sys/power/state"
}

#
# SUSPEND-005
# Check Kernel Messages After Resume
#
suspend_005()
{
    run_command \
        "SUSPEND-005" \
        "Check Kernel Messages After Resume" \
        "dmesg | tail -50"
}

#
# SUSPEND-006
# Verify Ethernet Connectivity
#
suspend_006()
{
    run_command \
        "SUSPEND-006" \
        "Verify Ethernet Connectivity" \
        "ping -c 4 ${SUSPEND_GATEWAY_IP}"
}

#
# SUSPEND-007
# Verify Storage Devices
#
suspend_007()
{
    run_command \
        "SUSPEND-007" \
        "Verify Storage Devices" \
        "lsblk"
}

###############################################################################
# Execute Suspend/Resume Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Suspend/Resume Validation"
    log_info "========================================="

    suspend_001
    suspend_002
    suspend_003
    suspend_004
    suspend_005
    suspend_006
    suspend_007

    log_info "========================================="
    log_info "Suspend/Resume Validation Completed"
    log_info "========================================="
}
