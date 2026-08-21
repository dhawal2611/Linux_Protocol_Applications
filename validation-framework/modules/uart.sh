#!/bin/bash
###############################################################################
# File        : uart.sh
# Description : UART Peripheral Validation Module
###############################################################################

MODULE_NAME="UART"
MODULE_DESCRIPTION="UART Peripheral Validation"

###############################################################################
# Runtime Directory
#
# Discovery information is stored here because run_command may execute
# commands in a different shell/process.
#
# Example:
#
# runtime/uart/
# ├── discovered_devices
# └── uart_rx_<pid>.tmp
#
###############################################################################

_UART_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_UART_FRAMEWORK_DIR="$(cd "${_UART_MODULE_DIR}/.." && pwd)"

UART_RUNTIME_DIR="${UART_RUNTIME_DIR:-${_UART_FRAMEWORK_DIR}/runtime/uart}"

UART_DISCOVERY_FILE="${UART_RUNTIME_DIR}/discovered_devices"

###############################################################################
# Runtime Variables
###############################################################################

UART_DEVICES=""
UART_DISCOVERY_DONE=0

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    stty
    timeout
    ls
    grep
    sort
    tr
    seq
)

###############################################################################
# UART Device Discovery
###############################################################################

uart_get_devices()
{
    {
        ls -1 /dev/ttyAMA* 2>/dev/null
        ls -1 /dev/ttyS*   2>/dev/null
        ls -1 /dev/ttyUSB* 2>/dev/null
        ls -1 /dev/ttyACM* 2>/dev/null
    } | sort -V -u
}

###############################################################################
# Check Whether UART Device Was Detected
#
# This function intentionally uses the discovery file instead of relying
# only on UART_DISCOVERY_DONE because run_command may execute tests in
# separate shell processes.
###############################################################################

uart_device_detected()
{
    local DEVICE="$1"
    local DISCOVERY_FILE="${UART_DISCOVERY_FILE}"

    if [ ! -f "$DISCOVERY_FILE" ]
    then
        echo "ERROR: UART discovery has not been completed."
        return 1
    fi

    if grep -Fxq "$DEVICE" "$DISCOVERY_FILE"
    then
        return 0
    fi

    return 1
}

###############################################################################
# Configure UART
###############################################################################

uart_configure()
{
    local DEVICE="$1"
    local BAUD="$2"

    local DATA_BITS
    local PARITY_OPT
    local STOP_BITS

    ###########################################################################
    # Data Bits
    ###########################################################################

    case "$UART_DATABITS" in

        5)
            DATA_BITS="cs5"
            ;;

        6)
            DATA_BITS="cs6"
            ;;

        7)
            DATA_BITS="cs7"
            ;;

        8)
            DATA_BITS="cs8"
            ;;

        *)
            echo "ERROR: Unsupported UART data bits: $UART_DATABITS"
            return 1
            ;;

    esac

    ###########################################################################
    # Parity
    ###########################################################################

    case "$(echo "$UART_PARITY" | tr '[:upper:]' '[:lower:]')" in

        none)
            PARITY_OPT="-parenb"
            ;;

        even)
            PARITY_OPT="parenb -parodd"
            ;;

        odd)
            PARITY_OPT="parenb parodd"
            ;;

        *)
            echo "ERROR: Unsupported UART parity: $UART_PARITY"
            return 1
            ;;

    esac

    ###########################################################################
    # Stop Bits
    ###########################################################################

    case "$UART_STOPBITS" in

        1)
            STOP_BITS="-cstopb"
            ;;

        2)
            STOP_BITS="cstopb"
            ;;

        *)
            echo "ERROR: Unsupported UART stop bits: $UART_STOPBITS"
            return 1
            ;;

    esac

    ###########################################################################
    # Configure UART
    ###########################################################################

    # shellcheck disable=SC2086
    stty -F "$DEVICE" \
        "$BAUD" \
        "$DATA_BITS" \
        $PARITY_OPT \
        $STOP_BITS \
        raw \
        -echo \
        -ixon \
        -ixoff \
        -crtscts \
        2>&1
}

###############################################################################
# UART-001 Command
#
# Detect all available UART devices and store them in runtime state.
###############################################################################

uart_cmd_discover()
{
    local RUNTIME_DIR="${UART_RUNTIME_DIR}"
    local DISCOVERY_FILE="${UART_DISCOVERY_FILE}"

    echo "Detecting available UART devices..."
    echo

    ###########################################################################
    # Create runtime directory
    ###########################################################################

    if ! mkdir -p "$RUNTIME_DIR"
    then
        echo "ERROR: Unable to create UART runtime directory:"
        echo "       $RUNTIME_DIR"
        return 1
    fi

    ###########################################################################
    # Detect UART devices
    ###########################################################################

    UART_DEVICES="$(uart_get_devices)"

    ###########################################################################
    # No UART devices
    ###########################################################################

    if [ -z "$UART_DEVICES" ]
    then
        UART_DISCOVERY_DONE=0

        rm -f "$DISCOVERY_FILE"

        echo "ERROR: No UART devices detected."

        return 1
    fi

    ###########################################################################
    # Store discovery result
    ###########################################################################

    if ! printf '%s\n' "$UART_DEVICES" > "$DISCOVERY_FILE"
    then
        echo "ERROR: Unable to save UART discovery information."
        echo "File : $DISCOVERY_FILE"

        return 1
    fi

    UART_DISCOVERY_DONE=1

    ###########################################################################
    # Display discovery result
    ###########################################################################

    echo "Available UART devices:"
    echo "$UART_DEVICES"
    echo

    echo "UART discovery state saved to:"
    echo "  $DISCOVERY_FILE"

    return 0
}

###############################################################################
# UART-002 Command
#
# Verify configured UART device exists in discovery results.
###############################################################################

uart_cmd_verify_device()
{
    local DEVICE="$UART_DEVICE"

    echo "Configured UART device verification"
    echo

    echo "Device : $DEVICE"
    echo

    if ! uart_device_detected "$DEVICE"
    then
        echo "ERROR: Configured UART device was not detected."
        echo
        echo "Expected device:"
        echo "  $DEVICE"

        return 1
    fi

    echo "UART device detected successfully."

    return 0
}

###############################################################################
# UART-003 Command
#
# Configure UART and display current configuration.
###############################################################################

uart_cmd_verify_configuration()
{
    local DEVICE="$UART_DEVICE"

    ###########################################################################
    # Verify discovery
    ###########################################################################

    if ! uart_device_detected "$DEVICE"
    then
        echo "ERROR: Configured UART device was not detected."
        echo "Device : $DEVICE"

        return 1
    fi

    ###########################################################################
    # Display requested configuration
    ###########################################################################

    echo "UART configuration requested:"
    echo
    echo "  Device    : $DEVICE"
    echo "  Baud      : $UART_BAUDRATE"
    echo "  Data bits : $UART_DATABITS"
    echo "  Parity    : $UART_PARITY"
    echo "  Stop bits : $UART_STOPBITS"
    echo

    ###########################################################################
    # Configure UART
    ###########################################################################

    if ! uart_configure "$DEVICE" "$UART_BAUDRATE"
    then
        echo "ERROR: Failed to configure UART."

        return 1
    fi

    echo
    echo "Current UART configuration:"
    echo

    stty -F "$DEVICE" -a 2>&1
}

###############################################################################
# UART TX/RX Helper
#
# Sends known data and waits only for the expected number of received bytes.
#
# Arguments:
#   $1 : UART device
#   $2 : Baud rate
#   $3 : Test data
#
# Return:
#   0 : TX/RX successful and data matched
#   1 : Failure
###############################################################################

uart_cmd_tx_rx()
{
    local DEVICE="$1"
    local BAUDRATE="$2"
    local TEST_DATA="$3"

    local RX_DATA=""
    local EXPECTED_LENGTH
    local TEMP_FILE
    local READ_TIMEOUT="${UART_READ_TIMEOUT:-3}"

    EXPECTED_LENGTH=${#TEST_DATA}

    TEMP_FILE=$(mktemp)

    if [ -z "$TEMP_FILE" ]
    then
        echo "ERROR: Unable to create temporary UART file."
        return 1
    fi

    echo "UART TX/RX Test"
    echo "Device       : $DEVICE"
    echo "Baudrate     : $BAUDRATE"
    echo "TX Data      : $TEST_DATA"
    echo "Expected Size: $EXPECTED_LENGTH bytes"
    echo "Read Timeout : ${READ_TIMEOUT}s"
    echo

    ###########################################################################
    # Configure UART
    ###########################################################################

    if ! stty -F "$DEVICE" "$BAUDRATE" \
        cs8 \
        -cstopb \
        -parenb \
        -ixon \
        -ixoff \
        -crtscts \
        raw \
        -echo
    then
        echo "ERROR: Failed to configure UART."
        rm -f "$TEMP_FILE"
        return 1
    fi

    ###########################################################################
    # Clear stale RX data
    ###########################################################################

    timeout 1 dd \
        if="$DEVICE" \
        of=/dev/null \
        bs=1 \
        count=1024 \
        status=none 2>/dev/null

    ###########################################################################
    # Start RX reader
    #
    # dd reads exactly EXPECTED_LENGTH bytes.
    # timeout prevents it from blocking forever.
    ###########################################################################

    timeout "$READ_TIMEOUT" dd \
        if="$DEVICE" \
        of="$TEMP_FILE" \
        bs=1 \
        count="$EXPECTED_LENGTH" \
        status=none 2>/dev/null &

    local RX_PID=$!

    ###########################################################################
    # Give RX process a moment to start
    ###########################################################################

    sleep 0.1

    ###########################################################################
    # Transmit data
    ###########################################################################

    printf '%s' "$TEST_DATA" > "$DEVICE"

    if [ $? -ne 0 ]
    then
        echo "ERROR: UART transmission failed."

        kill "$RX_PID" 2>/dev/null
        wait "$RX_PID" 2>/dev/null

        rm -f "$TEMP_FILE"
        return 1
    fi

    echo "TX completed successfully."
    echo

    ###########################################################################
    # Wait for RX process
    ###########################################################################

    wait "$RX_PID"
    local RX_STATUS=$?

    ###########################################################################
    # Read received data
    ###########################################################################

    RX_DATA=$(cat "$TEMP_FILE")

    rm -f "$TEMP_FILE"

    echo "RX Data      : $RX_DATA"
    echo "RX Size      : ${#RX_DATA} bytes"
    echo

    ###########################################################################
    # Check timeout / incomplete reception
    ###########################################################################

    if [ "$RX_STATUS" -ne 0 ]
    then
        echo "ERROR: UART receive timeout or incomplete reception."
        echo "Expected : $TEST_DATA"
        echo "Received : $RX_DATA"

        return 1
    fi

    ###########################################################################
    # Verify received data
    ###########################################################################

    if [ "$RX_DATA" != "$TEST_DATA" ]
    then
        echo "ERROR: UART TX/RX data mismatch."
        echo "Expected : $TEST_DATA"
        echo "Received : $RX_DATA"

        return 1
    fi

    echo "UART TX/RX loopback verified successfully."

    return 0
}
###############################################################################
# UART-004 Command
#
# Basic TX/RX loopback.
###############################################################################

uart_cmd_loopback()
{
    uart_cmd_tx_rx \
        "$UART_DEVICE" \
        "$UART_BAUDRATE" \
        "$UART_TEST_DATA"
}

###############################################################################
# UART-005 Command
#
# Multiple payload TX/RX validation.
###############################################################################

uart_cmd_multiple_payloads()
{
    local PAYLOAD
    local STATUS=0

    local PAYLOADS=(
        "UART_TEST_12345"
        "1234567890"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz"
        '!@#$%^&*()'
        "Hello UART"
        "Dhawal UART Test"
    )

    echo "UART multiple payload TX/RX validation"
    echo

    for PAYLOAD in "${PAYLOADS[@]}"
    do

        echo "----------------------------------------"
        echo "Payload : $PAYLOAD"
        echo "----------------------------------------"

        if ! uart_cmd_tx_rx \
            "$UART_DEVICE" \
            "$UART_BAUDRATE" \
            "$PAYLOAD"
        then
            STATUS=1
        fi

        echo

    done

    return "$STATUS"
}

###############################################################################
# UART-006 Command
#
# High-speed TX/RX validation.
###############################################################################

uart_cmd_high_speed()
{
    local PAYLOAD="UART_HIGH_SPEED_TEST_12345"

    echo "UART high-speed TX/RX validation"
    echo
    echo "Device : $UART_DEVICE"
    echo "Baud   : $UART_HIGH_SPEED"
    echo

    uart_cmd_tx_rx \
        "$UART_DEVICE" \
        "$UART_HIGH_SPEED" \
        "$PAYLOAD"
}

###############################################################################
# UART-007 Command
#
# Repeated TX/RX stability validation.
###############################################################################

uart_cmd_stability()
{
    local ITERATION
    local PAYLOAD="UART_STABILITY_TEST"

    local PASSED=0
    local FAILED=0

    echo "UART transfer stability validation"
    echo
    echo "Device     : $UART_DEVICE"
    echo "Baud       : $UART_BAUDRATE"
    echo "Iterations : $UART_STABILITY_ITERATIONS"
    echo

    for ITERATION in $(seq 1 "$UART_STABILITY_ITERATIONS")
    do

        if uart_cmd_tx_rx \
            "$UART_DEVICE" \
            "$UART_BAUDRATE" \
            "$PAYLOAD" \
            >/dev/null 2>&1
        then

            PASSED=$((PASSED + 1))

            echo "Iteration $ITERATION : PASS"

        else

            FAILED=$((FAILED + 1))

            echo "Iteration $ITERATION : FAIL"

        fi

    done

    echo
    echo "UART Stability Summary"
    echo "----------------------"
    echo "Total  : $UART_STABILITY_ITERATIONS"
    echo "Passed : $PASSED"
    echo "Failed : $FAILED"

    if [ "$FAILED" -ne 0 ]
    then
        return 1
    fi

    return 0
}

###############################################################################
# UART-001
#
# Detect & Scan UART Devices
###############################################################################

uart_001()
{
    log_info "[UART-001] Detect & Scan UART Devices"

    run_command \
        "UART-001" \
        "Detect & Scan UART Devices" \
        "uart_cmd_discover"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="UART device detection failed."

        test_fail

        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="UART discovery returned empty output."

        test_fail

        return
    fi

    TEST_MESSAGE="Detected all available UART devices successfully."

    test_pass
}

###############################################################################
# UART-002
#
# Verify Configured UART Device
###############################################################################

uart_002()
{
    log_info "[UART-002] Verify Configured UART Device"

    run_command \
        "UART-002" \
        "Verify Configured UART Device" \
        "uart_cmd_verify_device"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Configured UART device $UART_DEVICE was not detected."

        test_fail

        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="UART device verification returned empty output."

        test_fail

        return
    fi

    TEST_MESSAGE="Configured UART device $UART_DEVICE detected successfully."

    test_pass
}

###############################################################################
# UART-003
#
# Verify UART Configuration
###############################################################################

uart_003()
{
    log_info "[UART-003] Verify UART Configuration"

    run_command \
        "UART-003" \
        "Verify UART Configuration" \
        "uart_cmd_verify_configuration"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="UART configuration validation failed."

        test_fail

        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="UART configuration command returned empty output."

        test_fail

        return
    fi

    TEST_MESSAGE="UART configuration verified successfully."

    test_pass
}

###############################################################################
# UART-004
#
# Verify UART TX/RX Loopback
###############################################################################

uart_004()
{
    log_info "[UART-004] Verify UART TX/RX Loopback"

    run_command \
        "UART-004" \
        "UART TX/RX Loopback" \
        "uart_cmd_loopback"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="UART TX/RX loopback failed."

        test_fail

        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="UART TX/RX loopback returned empty output."

        test_fail

        return
    fi

    TEST_MESSAGE="UART TX/RX loopback completed successfully."

    test_pass
}

###############################################################################
# UART-005
#
# Verify UART Multiple Payload TX/RX
###############################################################################

uart_005()
{
    log_info "[UART-005] Verify UART Multiple Payload TX/RX"

    run_command \
        "UART-005" \
        "UART Multiple Payload TX/RX" \
        "uart_cmd_multiple_payloads"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="One or more UART payload TX/RX tests failed."

        test_fail

        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="UART multiple payload test returned empty output."

        test_fail

        return
    fi

    TEST_MESSAGE="All UART payload TX/RX tests completed successfully."

    test_pass
}

###############################################################################
# UART-006
#
# Verify UART High-Speed TX/RX
###############################################################################

uart_006()
{
    log_info "[UART-006] Verify UART High-Speed TX/RX"

    run_command \
        "UART-006" \
        "UART High-Speed TX/RX" \
        "uart_cmd_high_speed"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="UART high-speed TX/RX failed."

        test_fail

        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="UART high-speed TX/RX returned empty output."

        test_fail

        return
    fi

    TEST_MESSAGE="UART high-speed TX/RX completed successfully."

    test_pass
}

###############################################################################
# UART-007
#
# Verify UART Transfer Stability
###############################################################################

uart_007()
{
    log_info "[UART-007] Verify UART Transfer Stability"

    run_command \
        "UART-007" \
        "UART Transfer Stability" \
        "uart_cmd_stability"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="UART transfer stability validation failed."

        test_fail

        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="UART stability test returned empty output."

        test_fail

        return
    fi

    TEST_MESSAGE="UART transfer stability validation completed successfully."

    test_pass
}

###############################################################################
# Register UART Tests
###############################################################################

uart_register_tests()
{
    ###########################################################################
    # UART-001
    ###########################################################################

    register_test \
        -i "UART-001" \
        -f uart_001 \
        -n "Detect & Scan UART Devices" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "uart,serial,detect,scan" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect all available UART/serial devices and record the discovered devices."

    ###########################################################################
    # UART-002
    ###########################################################################

    register_test \
        -i "UART-002" \
        -f uart_002 \
        -n "Verify Configured UART Device" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "uart,serial,device" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify the configured UART device was detected during UART discovery."

    ###########################################################################
    # UART-003
    ###########################################################################

    register_test \
        -i "UART-003" \
        -f uart_003 \
        -n "Verify UART Configuration" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "uart,baud,parity,databits,stopbits,stty" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify UART baud rate, data bits, parity and stop bits."

    ###########################################################################
    # UART-004
    ###########################################################################

    register_test \
        -i "UART-004" \
        -f uart_004 \
        -n "Verify UART TX/RX Loopback" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 40 \
        -g "uart,tx,rx,loopback,data" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Transmit a known payload and verify the received UART data matches exactly."

    ###########################################################################
    # UART-005
    ###########################################################################

    register_test \
        -i "UART-005" \
        -f uart_005 \
        -n "Verify UART Multiple Payload TX/RX" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 50 \
        -g "uart,tx,rx,payload,ascii" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Validate UART TX/RX using multiple ASCII, numeric and special-character payloads."

    ###########################################################################
    # UART-006
    ###########################################################################

    register_test \
        -i "UART-006" \
        -f uart_006 \
        -n "Verify UART High-Speed TX/RX" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 60 \
        -g "uart,highspeed,baud,tx,rx" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Configure UART at the configured high-speed baud rate and validate TX/RX data."

    ###########################################################################
    # UART-007
    ###########################################################################

    register_test \
        -i "UART-007" \
        -f uart_007 \
        -n "Verify UART Transfer Stability" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 70 \
        -g "uart,stability,repeated,tx,rx" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Perform repeated UART TX/RX transfers and verify all iterations successfully."
}

###############################################################################
# UART Module Initialization
###############################################################################

uart_init()
{
    log_info "==============================================================================="

    log_info "Starting UART Validation"

    log_info "==============================================================================="

    log_info "Configured UART:"
    log_info "  Device          : $UART_DEVICE"
    log_info "  Baud Rate       : $UART_BAUDRATE"
    log_info "  High-Speed Rate : $UART_HIGH_SPEED"
    log_info "  Data Bits       : $UART_DATABITS"
    log_info "  Parity          : $UART_PARITY"
    log_info "  Stop Bits       : $UART_STOPBITS"
    log_info "  Test Data       : $UART_TEST_DATA"
    log_info "  Stability Count : $UART_STABILITY_ITERATIONS"

    uart_register_tests

    return 0
}

###############################################################################
# Initialize Module When Sourced
###############################################################################

uart_init

###############################################################################
# End Of File
###############################################################################
