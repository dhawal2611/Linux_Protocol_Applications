#!/bin/bash
###############################################################################
# Module      : SerDes Validation
# Description : SerDes interface validation test cases
###############################################################################

#
# SERDES-001
# Check SerDes Kernel Messages
#
serdes_001()
{
    run_command \
        "SERDES-001" \
        "Check SerDes Kernel Messages" \
        "dmesg | grep -i serdes"
}

#
# SERDES-002
# Verify PLL Lock Status
#
serdes_002()
{
    run_command \
        "SERDES-002" \
        "Verify PLL Lock Status" \
        "dmesg | grep -i pll"
}

#
# SERDES-003
# Inspect Clock Summary
#
serdes_003()
{
    run_command \
        "SERDES-003" \
        "Inspect Clock Summary" \
        "cat /sys/kernel/debug/clk/clk_summary"
}

#
# SERDES-004
# Run PRBS Test
#
serdes_004()
{
    run_command \
        "SERDES-004" \
        "Run PRBS Test" \
        "${SERDES_PRBS_CMD}"
}

###############################################################################
# Execute all SerDes Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting SerDes Validation"
    log_info "========================================="

    serdes_001
    serdes_002
    serdes_003
    serdes_004

    log_info "========================================="
    log_info "SerDes Validation Completed"
    log_info "========================================="
}
