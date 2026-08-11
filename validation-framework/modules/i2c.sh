#!/bin/bash
###############################################################################
# File        : i2c.sh
# Description : I2C Peripheral Validation Module
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="I2C"
MODULE_DESCRIPTION="I2C Peripheral Validation"

###############################################################################
# Module Paths
###############################################################################

I2C_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
I2C_RUNTIME_DIR="${I2C_MODULE_DIR}/../runtime/i2c"

I2C_BUSES_FILE="${I2C_RUNTIME_DIR}/buses"
I2C_DISCOVERY_FILE="${I2C_RUNTIME_DIR}/discovery"
I2C_STATUS_FILE="${I2C_RUNTIME_DIR}/status"

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    i2cdetect
    i2ctransfer
    i2cget
    i2cset
    awk
    grep
    sort
    tr
)

###############################################################################
# Configuration Defaults
###############################################################################

#
# Generic I2C device
#
I2C_GENERIC_BUS="${I2C_GENERIC_BUS:-1}"
I2C_GENERIC_ADDRESS="${I2C_GENERIC_ADDRESS:-0x38}"

#
# Generic read/write configuration
#
I2C_GENERIC_WRITE_REGISTER="${I2C_GENERIC_WRITE_REGISTER:-0x00}"
I2C_GENERIC_WRITE_VALUE="${I2C_GENERIC_WRITE_VALUE:-0x12}"
I2C_GENERIC_READ_REGISTER="${I2C_GENERIC_READ_REGISTER:-0x00}"

#
# Configured generic devices.
#
# Format:
#
#   BUS:ADDRESS
#
# Example:
#
#   I2C_GENERIC_DEVICES=(
#       "1:0x38"
#       "1:0x60"
#   )
#

if [ -z "${I2C_GENERIC_DEVICES+x}" ]
then
    I2C_GENERIC_DEVICES=(
        "1:0x38"
    )
fi

###############################################################################
# Runtime Directory
###############################################################################

i2c_runtime_init()
{
    mkdir -p "$I2C_RUNTIME_DIR"

    #
    # Do not delete the files here if another test case already performed
    # discovery in the same validation execution.
    #
    if [ ! -f "$I2C_STATUS_FILE" ]
    then
        echo "DISCOVERY_DONE=0" > "$I2C_STATUS_FILE"
    fi
}

###############################################################################
# Runtime Cleanup
###############################################################################

i2c_runtime_cleanup()
{
    #
    # Runtime files can be removed after the complete validation run.
    #
    # This function is intentionally available but is not called between
    # individual test cases.
    #

    if [ -d "$I2C_RUNTIME_DIR" ]
    then
        rm -rf "$I2C_RUNTIME_DIR"
    fi
}

###############################################################################
# Get I2C Buses
###############################################################################

i2c_get_buses()
{
    i2cdetect -l 2>/dev/null |
    while read -r BUS REST
    do
        case "$BUS" in
            i2c-[0-9]*)
                echo "${BUS#i2c-}"
                ;;
        esac
    done |
    sort -n -u
}

###############################################################################
# Convert Address To Decimal
###############################################################################

i2c_address_to_decimal()
{
    local ADDRESS="$1"

    printf "%d\n" "$((ADDRESS))" 2>/dev/null
}

###############################################################################
# Normalize I2C Address
###############################################################################

i2c_normalize_address()
{
    local ADDRESS="$1"
    local DECIMAL_ADDRESS

    DECIMAL_ADDRESS=$(i2c_address_to_decimal "$ADDRESS")

    if [ -z "$DECIMAL_ADDRESS" ]
    then
        return 1
    fi

    printf "%02x\n" "$DECIMAL_ADDRESS"
}

###############################################################################
# Store Detected Devices
###############################################################################

i2c_store_bus_devices()
{
    local SCAN_OUTPUT="$1"
    local TOKEN
    local ADDRESS

    echo "$SCAN_OUTPUT" |
    while read -r LINE
    do
        for TOKEN in $LINE
        do
            case "$TOKEN" in

                --)
                    ;;

                UU)
                    ;;

                [0-9a-fA-F][0-9a-fA-F])

                    ADDRESS=$(echo "$TOKEN" |
                        tr '[:upper:]' '[:lower:]')

                    #
                    # Ignore i2cdetect row headers.
                    #
                    case "$ADDRESS" in
                        00|10|20|30|40|50|60|70)
                            ;;

                        *)
                            echo "$ADDRESS"
                            ;;
                    esac
                    ;;

            esac
        done
    done |
    sort -u |
    tr '\n' ' ' |
    sed 's/[[:space:]]*$//'
}


###############################################################################
# Save Bus Device Information
###############################################################################

i2c_save_bus_devices()
{
    local BUS="$1"
    local DEVICES="$2"

    mkdir -p "$I2C_RUNTIME_DIR"

    #
    # Format:
    #
    # BUS=1 DEVICES="38 60"
    #
    echo "BUS=${BUS} DEVICES=\"${DEVICES}\"" >> "$I2C_DISCOVERY_FILE"
}

###############################################################################
# Load Devices For A Bus
###############################################################################

i2c_get_detected_devices()
{
    local BUS="$1"

    if [ ! -f "$I2C_DISCOVERY_FILE" ]
    then
        return 1
    fi

    awk -v bus="$BUS" '
        $0 ~ "^BUS=" bus " " {
            line=$0
            sub(/^BUS=[0-9]+ DEVICES="/, "", line)
            sub(/"$/, "", line)
            print line
            exit
        }
    ' "$I2C_DISCOVERY_FILE"
}

###############################################################################
# Check Whether Device Was Detected
###############################################################################

i2c_device_detected()
{
    local BUS="$1"
    local ADDRESS="$2"
    local NORMALIZED_ADDRESS
    local DETECTED_DEVICES
    local DEVICE

    NORMALIZED_ADDRESS=$(i2c_normalize_address "$ADDRESS")

    if [ -z "$NORMALIZED_ADDRESS" ]
    then
        return 1
    fi

    DETECTED_DEVICES=$(i2c_get_detected_devices "$BUS")

    if [ -z "$DETECTED_DEVICES" ]
    then
        return 1
    fi

    for DEVICE in $DETECTED_DEVICES
    do
        DEVICE=$(echo "$DEVICE" |
            tr '[:upper:]' '[:lower:]')

        if [ "$DEVICE" = "$NORMALIZED_ADDRESS" ]
        then
            return 0
        fi
    done

    return 1
}


###############################################################################
# Verify Discovery
###############################################################################

i2c_discovery_done()
{
    if [ ! -f "$I2C_STATUS_FILE" ]
    then
        return 1
    fi

    grep -q '^DISCOVERY_DONE=1$' "$I2C_STATUS_FILE"
}

###############################################################################
# Verify Expected Device
###############################################################################

i2c_verify_expected_device()
{
    local BUS="$1"
    local ADDRESS="$2"
    local DEVICE_NAME="$3"

    if ! i2c_discovery_done
    then
        echo "ERROR: I2C discovery has not been completed."
        echo "Please execute I2C-001 before running device tests."
        return 1
    fi

    if ! i2c_device_detected "$BUS" "$ADDRESS"
    then
        echo "ERROR: $DEVICE_NAME not detected."
        echo
        echo "Expected:"
        echo "  Bus     : $BUS"
        echo "  Address : $ADDRESS"
        echo

        echo "Detected devices on bus $BUS:"
        i2c_get_detected_devices "$BUS"

        return 1
    fi

    echo "$DEVICE_NAME detected successfully."
    echo "  Bus     : $BUS"
    echo "  Address : $ADDRESS"

    return 0
}

###############################################################################
# I2C-001
# Detect & Scan All I2C Buses
###############################################################################


i2c_cmd_scan_all_buses()
{
    local BUS
    local SCAN_OUTPUT
    local DEVICES
    local STATUS=0

    i2c_runtime_init

    #
    # Avoid duplicate discovery.
    #
    if i2c_discovery_done
    then
        echo "I2C discovery already completed."
        echo
        echo "Previously detected I2C buses:"
        cat "$I2C_BUSES_FILE"

        return 0
    fi

    #
    # Start fresh discovery file.
    #
    : > "$I2C_DISCOVERY_FILE"

    echo "Detecting available I2C buses..."
    echo

    I2C_BUSES=$(i2c_get_buses)

    if [ -z "$I2C_BUSES" ]
    then
        echo "ERROR: No I2C buses detected."

        echo "DISCOVERY_DONE=0" > "$I2C_STATUS_FILE"

        return 1
    fi

    #
    # Store bus list.
    #
    echo "$I2C_BUSES" > "$I2C_BUSES_FILE"

    echo "Available I2C buses:"
    echo "$I2C_BUSES"
    echo

    #
    # Scan every detected bus.
    #
    for BUS in $I2C_BUSES
    do
        echo "## I2C BUS : $BUS"
        echo

        SCAN_OUTPUT=$(i2cdetect -y "$BUS" 2>&1)
        COMMAND_RC=$?

        echo "$SCAN_OUTPUT"
        echo

        if [ "$COMMAND_RC" -ne 0 ]
        then
            echo "ERROR: Failed to scan I2C bus $BUS."
            STATUS=1
            continue
        fi

        DEVICES=$(i2c_store_bus_devices "$SCAN_OUTPUT")

        i2c_save_bus_devices "$BUS" "$DEVICES"

        echo "Detected slave addresses on bus $BUS:"

        if [ -n "$DEVICES" ]
        then
            echo "$DEVICES"
        else
            echo "None"
        fi

        echo
    done

    #
    # Only mark discovery complete if every bus scan succeeded.
    #
    if [ "$STATUS" -eq 0 ]
    then
        echo "DISCOVERY_DONE=1" > "$I2C_STATUS_FILE"
    else
        echo "DISCOVERY_DONE=0" > "$I2C_STATUS_FILE"
    fi

    return "$STATUS"
}

###############################################################################
# I2C-001 : Detect & Scan All I2C Buses
###############################################################################

i2c_001()
{
    log_info "[I2C-001] Detect & Scan All I2C Buses"

    run_command \
        "I2C-001" \
        "Detect & Scan All I2C Buses" \
        "i2c_cmd_scan_all_buses"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="I2C bus detection or scanning failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Detected and scanned all I2C buses successfully."

    test_pass
}


###############################################################################
# I2C-002
# Verify TMP1075 @ 0x48
###############################################################################

i2c_002()
{
    log_info "[I2C-002] Verify TMP1075 Temperature Sensor @ 0x48"

    if ! i2c_verify_expected_device \
        "0" \
        "0x48" \
        "TMP1075 Temperature Sensor"
    then
        TEST_MESSAGE="TMP1075 at bus 0 address 0x48 was not detected."
        test_fail
        return
    fi

    run_command \
        "I2C-002" \
        "Read TMP1075 Temperature Sensor @ 0x48" \
        "i2ctransfer -y 0 w1@0x48 0x00 r2"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="TMP1075 transaction failed at bus 0 address 0x48."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="TMP1075 returned empty output."
        test_fail
        return
    fi

    TEST_MESSAGE="TMP1075 @ 0x48 transaction completed successfully."

    test_pass
}

###############################################################################
# I2C-003
# Verify TMP1075 @ 0x49
###############################################################################

i2c_003()
{
    log_info "[I2C-003] Verify TMP1075 Temperature Sensor @ 0x49"

    if ! i2c_verify_expected_device \
        "0" \
        "0x49" \
        "TMP1075 Temperature Sensor"
    then
        TEST_MESSAGE="TMP1075 at bus 0 address 0x49 was not detected."
        test_fail
        return
    fi

    run_command \
        "I2C-003" \
        "Read TMP1075 Temperature Sensor @ 0x49" \
        "i2ctransfer -y 0 w1@0x49 0x00 r2"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="TMP1075 transaction failed at bus 0 address 0x49."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="TMP1075 returned empty output."
        test_fail
        return
    fi

    TEST_MESSAGE="TMP1075 @ 0x49 transaction completed successfully."

    test_pass
}

###############################################################################
# I2C-004
# Verify EEPROM @ 0x50
###############################################################################

i2c_004()
{
    log_info "[I2C-004] Verify EEPROM @ 0x50"

    if ! i2c_verify_expected_device \
        "0" \
        "0x50" \
        "EEPROM 24LC64"
    then
        TEST_MESSAGE="EEPROM at bus 0 address 0x50 was not detected."
        test_fail
        return
    fi

    run_command \
        "I2C-004" \
        "Read EEPROM @ 0x50" \
        "i2ctransfer -y 0 w2@0x50 0x00 0x10 r1"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="EEPROM transaction failed at bus 0 address 0x50."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="EEPROM returned empty output."
        test_fail
        return
    fi

    TEST_MESSAGE="EEPROM @ 0x50 transaction completed successfully."

    test_pass
}

###############################################################################
# I2C-005
# Verify PAC1931 @ 0x1F
###############################################################################

i2c_005()
{
    log_info "[I2C-005] Verify PAC1931 Current Sensor @ 0x1F"

    if ! i2c_verify_expected_device \
        "0" \
        "0x1F" \
        "PAC1931 Current Sensor"
    then
        TEST_MESSAGE="PAC1931 at bus 0 address 0x1F was not detected."
        test_fail
        return
    fi

    run_command \
        "I2C-005" \
        "Read PAC1931 @ 0x1F" \
        "i2ctransfer -y 0 w1@0x1F 0x0B r2"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="PAC1931 transaction failed at bus 0 address 0x1F."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="PAC1931 returned empty output."
        test_fail
        return
    fi

    TEST_MESSAGE="PAC1931 @ 0x1F transaction completed successfully."

    test_pass
}

###############################################################################
# I2C-006
# Verify ATECC608B @ 0x60
###############################################################################

i2c_cmd_atecc608b()
{
    i2ctransfer \
        -y 1 \
        w8@0x60 \
        0x03 0x07 0x1B 0x00 0x00 0x00 0x03 0xA7

    if [ $? -ne 0 ]
    then
        return 1
    fi

    sleep 0.003

    i2ctransfer \
        -y 1 \
        r35@0x60
}

i2c_006()
{
    log_info "[I2C-006] Verify ATECC608B Authentication IC @ 0x60"

    if ! i2c_verify_expected_device \
        "1" \
        "0x60" \
        "ATECC608B Authentication IC"
    then
        TEST_MESSAGE="ATECC608B at bus 1 address 0x60 was not detected."
        test_fail
        return
    fi

    run_command \
        "I2C-006" \
        "Read ATECC608B @ 0x60" \
        "i2c_cmd_atecc608b"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="ATECC608B transaction failed."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="ATECC608B returned empty output."
        test_fail
        return
    fi

    TEST_MESSAGE="ATECC608B @ 0x60 transaction completed successfully."

    test_pass
}

###############################################################################
# I2C-007
# Verify Generic I2C Slave Address
###############################################################################

i2c_007()
{
    log_info "[I2C-007] Verify Generic I2C Slave Address"

    if ! i2c_verify_expected_device \
        "$I2C_GENERIC_BUS" \
        "$I2C_GENERIC_ADDRESS" \
        "Generic I2C Device"
    then
        TEST_MESSAGE="Generic I2C device $I2C_GENERIC_ADDRESS was not detected on bus $I2C_GENERIC_BUS."
        test_fail
        return
    fi

    TEST_MESSAGE="Generic I2C slave $I2C_GENERIC_ADDRESS detected on bus $I2C_GENERIC_BUS."

    test_pass
}

###############################################################################
# I2C-008
# Generic I2C Read
###############################################################################

i2c_008()
{
    log_info "[I2C-008] Verify Generic I2C Read"

    if ! i2c_verify_expected_device \
        "$I2C_GENERIC_BUS" \
        "$I2C_GENERIC_ADDRESS" \
        "Generic I2C Device"
    then
        TEST_MESSAGE="Generic I2C device was not detected."
        test_fail
        return
    fi

    run_command \
        "I2C-008" \
        "Generic I2C Read" \
        "i2cget -y $I2C_GENERIC_BUS $I2C_GENERIC_ADDRESS $I2C_GENERIC_READ_REGISTER"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Generic I2C read failed."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="Generic I2C read returned empty output."
        test_fail
        return
    fi

    TEST_MESSAGE="Generic I2C read completed successfully."

    test_pass
}

###############################################################################
# I2C-009
# Generic I2C Write
###############################################################################

i2c_009()
{
    log_info "[I2C-009] Verify Generic I2C Write"

    if ! i2c_verify_expected_device \
        "$I2C_GENERIC_BUS" \
        "$I2C_GENERIC_ADDRESS" \
        "Generic I2C Device"
    then
        TEST_MESSAGE="Generic I2C device was not detected."
        test_fail
        return
    fi

    run_command \
        "I2C-009" \
        "Generic I2C Write" \
        "i2cset -y $I2C_GENERIC_BUS $I2C_GENERIC_ADDRESS $I2C_GENERIC_WRITE_REGISTER $I2C_GENERIC_WRITE_VALUE"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Generic I2C write failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Generic I2C write completed successfully."

    test_pass
}


###############################################################################
# I2C-010
# Generic Write + Readback
###############################################################################

i2c_cmd_generic_write_readback()
{
    local READ_VALUE

    echo "Generic I2C write + readback"
    echo
    echo "Bus            : $I2C_GENERIC_BUS"
    echo "Address        : $I2C_GENERIC_ADDRESS"
    echo "Write Register : $I2C_GENERIC_WRITE_REGISTER"
    echo "Write Value    : $I2C_GENERIC_WRITE_VALUE"
    echo "Read Register  : $I2C_GENERIC_READ_REGISTER"
    echo

    echo "Writing $I2C_GENERIC_WRITE_VALUE..."

    i2cset \
        -y "$I2C_GENERIC_BUS" \
        "$I2C_GENERIC_ADDRESS" \
        "$I2C_GENERIC_WRITE_REGISTER" \
        "$I2C_GENERIC_WRITE_VALUE"

    if [ $? -ne 0 ]
    then
        echo "ERROR: I2C write failed."
        return 1
    fi

    echo "Write successful."
    echo

    echo "Reading back..."

    READ_VALUE=$(i2cget \
        -y "$I2C_GENERIC_BUS" \
        "$I2C_GENERIC_ADDRESS" \
        "$I2C_GENERIC_READ_REGISTER" 2>&1)

    if [ $? -ne 0 ]
    then
        echo "$READ_VALUE"
        echo "ERROR: I2C readback failed."
        return 1
    fi

    echo "Read Value : $READ_VALUE"
    echo

    READ_VALUE=$(echo "$READ_VALUE" |
        tr '[:upper:]' '[:lower:]')

    EXPECTED_VALUE=$(echo "$I2C_GENERIC_WRITE_VALUE" |
        tr '[:upper:]' '[:lower:]')

    if [ "$READ_VALUE" != "$EXPECTED_VALUE" ]
    then
        echo "ERROR: Write/readback mismatch."
        echo "Expected : $EXPECTED_VALUE"
        echo "Read     : $READ_VALUE"
        return 1
    fi

    echo "Write/readback verification successful."

    return 0
}

i2c_010()
{
    log_info "[I2C-010] Verify Generic I2C Write + Readback"

    if ! i2c_verify_expected_device \
        "$I2C_GENERIC_BUS" \
        "$I2C_GENERIC_ADDRESS" \
        "Generic I2C Device"
    then
        TEST_MESSAGE="Generic I2C device was not detected."
        test_fail
        return
    fi

    run_command \
        "I2C-010" \
        "Generic I2C Write + Readback" \
        "i2c_cmd_generic_write_readback"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Generic I2C write/readback verification failed."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="Generic I2C write/readback returned empty output."
        test_fail
        return
    fi

    TEST_MESSAGE="Generic I2C write/readback verification completed successfully."

    test_pass
}


###############################################################################
# I2C-011
# Validate Configured Generic Devices
###############################################################################

i2c_parse_generic_device()
{
    local DEVICE="$1"

    I2C_GENERIC_DEVICE_BUS="${DEVICE%%:*}"
    I2C_GENERIC_DEVICE_ADDRESS="${DEVICE##*:}"
}

i2c_cmd_validate_configured_devices()
{
    local DEVICE
    local BUS
    local ADDRESS
    local STATUS=0

    if [ "${#I2C_GENERIC_DEVICES[@]}" -eq 0 ]
    then
        echo "No generic I2C devices configured."
        return 0
    fi

    echo "Configured Generic I2C Devices:"
    echo

    for DEVICE in "${I2C_GENERIC_DEVICES[@]}"
    do
        i2c_parse_generic_device "$DEVICE"

        BUS="$I2C_GENERIC_DEVICE_BUS"
        ADDRESS="$I2C_GENERIC_DEVICE_ADDRESS"

        echo "Device:"
        echo "  Bus     : $BUS"
        echo "  Address : $ADDRESS"

        if i2c_device_detected "$BUS" "$ADDRESS"
        then
            echo "  Status  : DETECTED"
        else
            echo "  Status  : NOT DETECTED"
            STATUS=1
        fi

        echo
    done

    return "$STATUS"
}

i2c_011()
{
    log_info "[I2C-011] Validate Configured Generic I2C Devices"

    run_command \
        "I2C-011" \
        "Validate Configured Generic I2C Devices" \
        "i2c_cmd_validate_configured_devices"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="One or more configured generic I2C devices were not detected."
        test_fail
        return
    fi

    TEST_MESSAGE="All configured generic I2C devices were detected successfully."

    test_pass
}

###############################################################################
# I2C-012
# Report Detected But Unconfigured Devices
###############################################################################

i2c_cmd_report_unconfigured_devices()
{
    local BUS
    local DETECTED_DEVICES
    local DEVICE
    local CONFIG_DEVICE
    local CONFIGURED
    local DETECTED_ADDRESS
    local CONFIG_ADDRESS
    local FOUND_UNCONFIGURED=0

    echo "Checking detected I2C devices against configuration..."
    echo

    for BUS in $I2C_BUSES
    do
        DETECTED_DEVICES=$(i2c_get_detected_devices "$BUS")

        for DEVICE in $DETECTED_DEVICES
        do
            DETECTED_ADDRESS="0x$DEVICE"
            CONFIGURED=0

            for CONFIG_DEVICE in "${I2C_GENERIC_DEVICES[@]}"
            do
                i2c_parse_generic_device "$CONFIG_DEVICE"

                if [ "$I2C_GENERIC_DEVICE_BUS" != "$BUS" ]
                then
                    continue
                fi

                CONFIG_ADDRESS=$(i2c_normalize_address \
                    "$I2C_GENERIC_DEVICE_ADDRESS")

                if [ "$CONFIG_ADDRESS" = "$DEVICE" ]
                then
                    CONFIGURED=1
                    break
                fi
            done

            if [ "$CONFIGURED" -eq 0 ]
            then
                echo "[WARN] Detected but unconfigured I2C device:"
                echo "       Bus     : $BUS"
                echo "       Address : $DETECTED_ADDRESS"
                echo

                FOUND_UNCONFIGURED=1
            fi
        done
    done

    if [ "$FOUND_UNCONFIGURED" -eq 1 ]
    then
        echo "WARNING: One or more detected I2C devices are not configured."
    else
        echo "All detected generic I2C devices are configured."
    fi

    #
    # I2C-012 is informational.
    #
    # Do not fail because an extra device was detected.
    #
    return 0
}


i2c_012()
{
    log_info "[I2C-012] Report Detected but Unconfigured I2C Devices"

    run_command \
        "I2C-012" \
        "Report Detected but Unconfigured I2C Devices" \
        "i2c_cmd_report_unconfigured_devices"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to complete detected-device configuration audit."
        test_fail
        return
    fi

    TEST_MESSAGE="I2C detected-device configuration audit completed."

    test_pass
}

###############################################################################
# Register I2C Tests
###############################################################################

i2c_register_tests()
{
    register_test \
        -i "I2C-001" \
        -f i2c_001 \
        -n "Detect & Scan All I2C Buses" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "i2c,detect,scan,bus,slave" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect all available I2C buses, scan every bus and record detected slave addresses."

    register_test \
        -i "I2C-002" \
        -f i2c_002 \
        -n "Verify TMP1075 Temperature Sensor @ 0x48" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "i2c,tmp1075,temperature,0x48" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify TMP1075 temperature sensor at bus 0 address 0x48."

    register_test \
        -i "I2C-003" \
        -f i2c_003 \
        -n "Verify TMP1075 Temperature Sensor @ 0x49" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "i2c,tmp1075,temperature,0x49" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify TMP1075 temperature sensor at bus 0 address 0x49."

    register_test \
        -i "I2C-004" \
        -f i2c_004 \
        -n "Verify EEPROM @ 0x50" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 40 \
        -g "i2c,eeprom,24lc64,0x50" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify 24LC64 EEPROM at bus 0 address 0x50."

    register_test \
        -i "I2C-005" \
        -f i2c_005 \
        -n "Verify PAC1931 Current Sensor @ 0x1F" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 50 \
        -g "i2c,pac1931,current,0x1f" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify PAC1931 current sensor at bus 0 address 0x1F."

    register_test \
        -i "I2C-006" \
        -f i2c_006 \
        -n "Verify ATECC608B Authentication IC @ 0x60" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 60 \
        -g "i2c,atecc608b,authentication,0x60" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify ATECC608B authentication IC at bus 1 address 0x60."

    register_test \
        -i "I2C-007" \
        -f i2c_007 \
        -n "Verify Generic I2C Slave Address" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 70 \
        -g "i2c,generic,slave,address" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify configured generic I2C slave address is detected."

    register_test \
        -i "I2C-008" \
        -f i2c_008 \
        -n "Verify Generic I2C Read" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 80 \
        -g "i2c,generic,read,i2cget" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify generic I2C register read operation."

    register_test \
        -i "I2C-009" \
        -f i2c_009 \
        -n "Verify Generic I2C Write" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 90 \
        -g "i2c,generic,write,i2cset" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify generic I2C register write operation."

    register_test \
        -i "I2C-010" \
        -f i2c_010 \
        -n "Verify Generic I2C Write + Readback" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 100 \
        -g "i2c,generic,write,readback" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify generic I2C write followed by readback comparison."

    register_test \
        -i "I2C-011" \
        -f i2c_011 \
        -n "Validate Configured Generic I2C Devices" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 110 \
        -g "i2c,generic,configured,devices" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify all configured generic I2C devices are physically detected."

    register_test \
        -i "I2C-012" \
        -f i2c_012 \
        -n "Report Detected but Unconfigured I2C Devices" \
        -c "peripheral" \
        -t "auto" \
        -p "low" \
        -o 120 \
        -g "i2c,generic,unconfigured,audit" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Report I2C devices detected on the system but not configured."
}

###############################################################################
# Module Initialization
###############################################################################

i2c_init()
{
    log_info "========================================="
    log_info "Starting I2C Validation"
    log_info "========================================="

    i2c_runtime_init

    log_info "I2C Runtime Directory:"
    log_info "  $I2C_RUNTIME_DIR"

    log_info "Generic I2C Device:"
    log_info "  Bus     : $I2C_GENERIC_BUS"
    log_info "  Address : $I2C_GENERIC_ADDRESS"

    if [ "${#I2C_GENERIC_DEVICES[@]}" -gt 0 ]
    then
        log_info "Configured Generic I2C Devices:"

        for DEVICE in "${I2C_GENERIC_DEVICES[@]}"
        do
            log_info "  $DEVICE"
        done
    fi

    i2c_register_tests

    return 0
}

###############################################################################
# Module Initialization
###############################################################################

i2c_init

###############################################################################
# End Of File
###############################################################################
