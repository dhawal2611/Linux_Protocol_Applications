#!/bin/bash
###############################################################################
# Module      : RTC Validation
# Description : RTC Pre-Reboot Validation
###############################################################################

#
# RTC-001
# Read RTC Time
#
rtc_001()
{
    run_command \
        "RTC-001" \
        "Read RTC Time" \
        "hwclock -r"
}

#
# RTC-002
# Synchronize RTC With System Time
#
rtc_002()
{
    run_command \
        "RTC-002" \
        "Synchronize RTC With System Time" \
        "hwclock -w"
}

#
# RTC-003
# Read System Time
#
rtc_003()
{
    run_command \
        "RTC-003" \
        "Read System Time" \
        "date"
}

#
# RTC-004
# Configure RTC Wake Alarm
#
rtc_004()
{
    run_command \
        "RTC-004" \
        "Configure RTC Wake Alarm (${RTC_WAKEUP_TIME}s)" \
        "echo 0 > ${RTC_SYSFS}/wakealarm && \
         echo +${RTC_WAKEUP_TIME} > ${RTC_SYSFS}/wakealarm"
}

#
# RTC-005
# Verify RTC Wake Alarm
#
rtc_005()
{
    run_command \
        "RTC-005" \
        "Verify RTC Wake Alarm" \
        "echo 'Alarm Epoch :' && \
         cat ${RTC_SYSFS}/wakealarm && \
         echo '' && \
         echo 'Alarm Time :' && \
         date -d @\$(cat ${RTC_SYSFS}/wakealarm)"
}

#
# RTC-006
# Reboot System
#
rtc_006()
{
    log_info "[RTC-006] Manual Reboot Test"

    echo ""
    echo "==========================================================="
    echo "               MANUAL TEST REQUIRED"
    echo "==========================================================="
    echo "The board will reboot."
    echo ""
    echo "After boot execute:"
    echo ""
    echo "    ./validate.sh rtc_post"
    echo ""
    read -p "Press ENTER to reboot..."

    run_command \
        "RTC-006" \
        "Reboot System" \
        "reboot"
}

###############################################################################
# Execute RTC Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting RTC Validation"
    log_info "RTC Device : ${RTC_DEVICE}"
    log_info "========================================="

    rtc_001
    rtc_002
    rtc_003
    rtc_004
    rtc_005
    rtc_006

    log_info "========================================="
    log_info "RTC Validation Completed"
    log_info "========================================="
}
