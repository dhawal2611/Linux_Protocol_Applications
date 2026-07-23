#!/bin/bash
###############################################################################
# Module      : UART Validation
# Description : UART interface validation test cases
###############################################################################

#
# UART-001
# Verify UART Device Node
#
uart_001()
{
    run_command \
        "UART-001" \
        "Verify UART Device Node" \
        "ls /dev/tty*"
}

#
# UART-002
# Configure UART Baud Rate
#
uart_002()
{
    run_command \
        "UART-002" \
        "Configure UART Baud Rate to 115200" \
        "stty -F /dev/ttymxc0 115200"
}

#
# UART-003
# Transmit Data
#
uart_003()
{
    run_command \
        "UART-003" \
        "Transmit Test Data" \
        "echo test > /dev/ttymxc0"
}

#
# UART-004
# Receive Data
#
uart_004()
{
    run_command \
        "UART-004" \
        "Receive Test Data" \
        "timeout 5 cat /dev/ttymxc0"
}

#
# UART-005
# Long Duration Transfer
#
uart_005()
{
    run_command \
        "UART-005" \
        "Long Duration UART Transfer (1000 KB)" \
        "dd if=/dev/zero bs=1K count=1000 > /dev/ttymxc0"
}

###############################################################################
# Execute all UART Test Cases
###############################################################################
run_test()
{
    log_info "========================================="
    log_info "Starting UART Validation"
    log_info "========================================="

    uart_001
    uart_002
    uart_003
    uart_004
    uart_005

    log_info "========================================="
    log_info "UART Validation Completed"
    log_info "========================================="
}
