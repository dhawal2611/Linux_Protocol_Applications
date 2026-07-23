#!/bin/bash
###############################################################################
# Module      : RTC Post Validation
# Description : RTC Validation After Reboot
###############################################################################

#
# RTC-007
# Verify RTC Time
#
rtc_007()
{
    run_command \
        "RTC-007" \
        "Verify RTC Time" \
        "hwclock -r"
}

#
# RTC-008
# Verify System Time
#
rtc_008()
{
    run_command \
        "RTC-008" \
        "Verify System Time" \
        "date"
}

#
# RTC-009
# Verify RTC Driver Messages
#
rtc_009()
{
    run_command \
        "RTC-009" \
        "Verify RTC Driver Messages" \
        "dmesg | grep -i rtc"
}

#
# RTC-010
# Verify Wake Alarm Status
#
rtc_010()
{
    run_command \
        "RTC-010" \
        "Verify RTC Wake Alarm Status" \
        "cat ${RTC_SYSFS}/wakealarm"
}

###############################################################################
# Execute RTC Post Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting RTC Post Validation"
    log_info "========================================="

    rtc_007
    rtc_008
    rtc_009
    rtc_010

    log_info "========================================="
    log_info "RTC Post Validation Completed"
    log_info "========================================="
}
