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
# I2C Runtime Variables
###############################################################################

I2C_BUSES=""

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    i2cdetect
    awk
    sort
    grep
    tr
)

###############################################################################
# I2C Bus Discovery
###############################################################################

i2c_get_buses()
{
    i2cdetect -l 2>/dev/null |
    while read -r BUS REST
    do
        case "$BUS" in
            i2c-*)
                echo "$BUS" |
                    sed 's/^i2c-//'
                ;;
        esac
    done |
    sort -n -u
}

###############################################################################
# I2C Slave Address Scanner
###############################################################################

i2c_scan_bus()
{
    local BUS="$1"

    if [ -z "$BUS" ]
    then
        echo "ERROR: I2C bus number is empty."
        return 1
    fi

    echo "I2C BUS : $BUS"
    echo "----------------------------------------"

    i2cdetect -y "$BUS"

    return $?
}

###############################################################################
# I2C-001 Command Helper
###############################################################################

i2c_cmd_scan_all_buses()
{
    local BUSES
    local BUS
    local STATUS=0

    echo "Detecting available I2C buses..."

    BUSES=$(i2c_get_buses)

    if [ -z "$BUSES" ]
    then
        echo "ERROR: No I2C buses detected."
        return 1
    fi

    echo ""
    echo "Available I2C buses:"
    echo "$BUSES"
    echo ""

    for BUS in $BUSES
    do
        echo "==========================================================="
        echo "Scanning I2C Bus : $BUS"
        echo "==========================================================="

        if ! i2c_scan_bus "$BUS"
        then
            echo "ERROR: Failed to scan I2C bus $BUS."
            STATUS=1
        fi

        echo ""
    done

    return "$STATUS"
}

###############################################################################
# I2C-001 : Detect & Scan All I2C Buses
###############################################################################

i2c_001()
{
    local BUSES

    log_info "[I2C-001] Detect & Scan All I2C Buses"

    run_command \
        "I2C-001" \
        "Detect & Scan All I2C Buses" \
        "i2c_cmd_scan_all_buses"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to detect or scan available I2C buses."
        test_fail
        return
    fi

    BUSES=$(i2c_get_buses)

    if [ -z "$BUSES" ]
    then
        TEST_MESSAGE="No I2C buses detected."
        test_fail
        return
    fi

    TEST_MESSAGE="I2C buses detected and scanned successfully: $(echo "$BUSES" | tr '\n' ' ')"

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
        -g "i2c,i2cdetect,bus,scan" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect all available Linux I2C adapters and scan each bus for connected slave addresses."
}

###############################################################################
# Module Initialization
###############################################################################

i2c_init()
{
    log_info "========================================="
    log_info "Starting I2C Validation"
    log_info "========================================="

    if ! command -v i2cdetect >/dev/null 2>&1
    then
        TEST_MESSAGE="i2cdetect utility is not installed."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    I2C_BUSES=$(i2c_get_buses)

    if [ -z "$I2C_BUSES" ]
    then
        TEST_MESSAGE="No Linux I2C buses detected."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    log_info "Detected I2C buses:"
    echo "$I2C_BUSES"

    i2c_register_tests

    return 0
}

###############################################################################
# Module Initialization When Sourced
###############################################################################

i2c_init

###############################################################################
# End Of File
###############################################################################


```
#i2c_get_buses()                                                                                                                                   
#{                                                                                                                                                 
#    i2cdetect -l 2>/dev/null |                                                                                                                    
#    sed -n 's/^i2c-\([0-9][0-9]*\).*/\1/p' |                                                                                                      
#    sort -n -u                                                                                                                                    
#}



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
# I2C Runtime Variables
###############################################################################

I2C_BUS=""
I2C_ADDRESS=""
I2C_REGISTER=""
I2C_READ_LENGTH=""
I2C_WRITE_DATA=""

###############################################################################
# Board-Specific I2C Configuration
###############################################################################

# I2C-0
I2C0_TMP1075_1_ADDRESS="0x48"
I2C0_TMP1075_2_ADDRESS="0x49"
I2C0_EEPROM_ADDRESS="0x50"
I2C0_PAC1931_ADDRESS="0x1F"

# I2C-1
I2C1_ATECC608B_ADDRESS="0x60"

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    i2cdetect
    i2ctransfer
    i2cdetect
    ls
    awk
    grep
    sed
    tr
    sort
    uniq
    printf
)

###############################################################################
# Helper Functions
###############################################################################

###############################################################################
# I2C-001
# Detect all available I2C buses
###############################################################################

i2c_get_buses()
{
    local LINE
    local BUS

    i2cdetect -l 2>/dev/null |
    while IFS= read -r LINE
    do
        BUS=$(printf '%s\n' "$LINE" |
            sed -n 's/^[[:space:]]*\(i2c-[0-9][0-9]*\)[[:space:]].*/\1/p')

        if [ -n "$BUS" ]
        then
            printf '%s\n' "${BUS#i2c-}"
        fi
    done |
    sort -n -u
}

###############################################################################
# I2C-001 Command Helper
###############################################################################

i2c_cmd_detect_buses()
{
    local BUSES

    BUSES=$(i2c_get_buses)

    if [ -z "$BUSES" ]
    then
        echo "ERROR: No I2C buses detected."
        return 1
    fi

    echo "Available I2C buses:"
    echo "$BUSES"

    echo ""
    echo "I2C adapter information:"
    i2cdetect -l

    return 0
}

###############################################################################
# I2C-002 Command Helper
# Verify I2C device nodes
###############################################################################

i2c_cmd_device_nodes()
{
    local DEVICES

    DEVICES=$(ls /dev/i2c-* 2>/dev/null)

    if [ -z "$DEVICES" ]
    then
        echo "ERROR: No /dev/i2c-* device nodes found."
        return 1
    fi

    echo "Detected I2C device nodes:"
    echo "$DEVICES"

    return 0
}

###############################################################################
# Extract slave addresses from i2cdetect output
###############################################################################

i2c_print_detected_addresses()
{
    local OUTPUT="$1"
    local ADDRESSES

    ADDRESSES=$(echo "$OUTPUT" |
        awk '
        /^[[:space:]]*[0-9a-fA-F][0-9a-fA-F][[:space:]]/ {
            for (i = 2; i <= NF; i++) {
                if ($i ~ /^[0-9a-fA-F]{2}$/ &&
                    $i != "--")
                {
                    print "0x" toupper($i)
                }
            }
        }' |
        sort -u)

    echo ""
    echo "Detected I2C Slave Addresses:"

    if [ -z "$ADDRESSES" ]
    then
        echo "  None"
        return 0
    fi

    echo "$ADDRESSES" |
        while read -r ADDRESS
        do
            [ -n "$ADDRESS" ] && echo "  $ADDRESS"
        done

    echo ""
    echo "Total Slave Addresses Detected: $(echo "$ADDRESSES" | wc -l)"

    return 0
}

###############################################################################
# I2C-003 Command Helper
# Scan ALL available I2C buses
###############################################################################

i2c_cmd_scan_all_buses()
{
    local BUS
    local BUSES
    local OUTPUT
    local BUS_STATUS=0

    BUSES=$(i2c_get_buses)

    if [ -z "$BUSES" ]
    then
        echo "ERROR: No I2C buses available for scanning."
        return 1
    fi

    echo "=============================================================="
    echo "I2C BUS SCAN"
    echo "=============================================================="

    echo "Available buses:"
    echo "$BUSES"
    echo ""

    for BUS in $BUSES
    do
        echo "--------------------------------------------------------------"
        echo "Scanning I2C Bus $BUS"
        echo "Command: i2cdetect -y $BUS"
        echo "--------------------------------------------------------------"

        OUTPUT=$(i2cdetect -y "$BUS" 2>&1)
        local RET=$?

        echo "$OUTPUT"

        if [ "$RET" -ne 0 ]
        then
            echo ""
            echo "ERROR: Failed to scan I2C Bus $BUS."
            BUS_STATUS=1
            continue
        fi

        i2c_print_detected_addresses "$OUTPUT"

        echo ""
    done

    echo "=============================================================="
    echo "I2C BUS SCAN COMPLETED"
    echo "=============================================================="

    return "$BUS_STATUS"
}

###############################################################################
# I2C-004 Command Helper
# TMP1075 Temperature Sensor #1
###############################################################################

i2c_cmd_tmp1075_1()
{
    echo "I2C Bus     : 0"
    echo "Slave       : $I2C0_TMP1075_1_ADDRESS"
    echo "Device      : TMP1075NDRLR"
    echo "Operation   : Read temperature register"
    echo ""

    i2ctransfer \
        -y 0 \
        w1@"$I2C0_TMP1075_1_ADDRESS" 0x00 \
        r2
}

###############################################################################
# I2C-005 Command Helper
# TMP1075 Temperature Sensor #2
###############################################################################

i2c_cmd_tmp1075_2()
{
    echo "I2C Bus     : 0"
    echo "Slave       : $I2C0_TMP1075_2_ADDRESS"
    echo "Device      : TMP1075NDRLR"
    echo "Operation   : Read temperature register"
    echo ""

    i2ctransfer \
        -y 0 \
        w1@"$I2C0_TMP1075_2_ADDRESS" 0x00 \
        r2
}

###############################################################################
# I2C-006 Command Helper
# EEPROM 24LC64 Write + Read
###############################################################################

i2c_cmd_eeprom()
{
    echo "I2C Bus     : 0"
    echo "Slave       : $I2C0_EEPROM_ADDRESS"
    echo "Device      : 24LC64T-E/MNY"
    echo "Operation   : Write + Read"
    echo ""

    echo "EEPROM write:"
    i2ctransfer \
        -y 0 \
        w3@"$I2C0_EEPROM_ADDRESS" 0x00 0x10 0x0A

    if [ $? -ne 0 ]
    then
        echo "ERROR: EEPROM write failed."
        return 1
    fi

    sleep 0.01

    echo "EEPROM read:"
    i2ctransfer \
        -y 0 \
        w2@"$I2C0_EEPROM_ADDRESS" 0x00 0x10 \
        r1
}

###############################################################################
# I2C-007 Command Helper
# PAC1931 Current Sensor
###############################################################################

i2c_cmd_pac1931()
{
    echo "I2C Bus     : 0"
    echo "Slave       : $I2C0_PAC1931_ADDRESS"
    echo "Device      : PAC1931T-I/J6CX"
    echo "Operation   : Register write + read"
    echo ""

    echo "PAC1931 configuration:"
    i2ctransfer \
        -y 0 \
        w2@"$I2C0_PAC1931_ADDRESS" 0x00 0x00

    if [ $? -ne 0 ]
    then
        echo "ERROR: PAC1931 configuration command failed."
        return 1
    fi

    sleep 0.1

    echo "PAC1931 register read:"
    i2ctransfer \
        -y 0 \
        w1@"$I2C0_PAC1931_ADDRESS" 0x0B \
        r2
}

###############################################################################
# I2C-008 Command Helper
# ATECC608B Authentication IC
###############################################################################

i2c_cmd_atecc608b()
{
    echo "I2C Bus     : 1"
    echo "Slave       : $I2C1_ATECC608B_ADDRESS"
    echo "Device      : ATECC608B"
    echo "Operation   : Wake + command + response"
    echo ""

    echo "ATECC608B wake:"
    i2ctransfer \
        -y 1 \
        w1@0x00 0x00 \
        2>/dev/null

    if [ $? -ne 0 ]
    then
        echo "ERROR: ATECC608B wake command failed."
        return 1
    fi

    sleep 0.0025

    echo "ATECC608B command:"
    i2ctransfer \
        -y 1 \
        w8@"$I2C1_ATECC608B_ADDRESS" \
        0x03 0x07 0x1B 0x00 0x00 0x00 0x03 0xA7

    if [ $? -ne 0 ]
    then
        echo "ERROR: ATECC608B command failed."
        return 1
    fi

    echo "ATECC608B response:"
    i2ctransfer \
        -y 1 \
        r35@"$I2C1_ATECC608B_ADDRESS"
}

###############################################################################
# I2C-009 Command Helper
# Generic slave address verification
#
# Configuration:
#
# I2C_CUSTOM_BUS
# I2C_CUSTOM_ADDRESS
###############################################################################

i2c_cmd_custom_address()
{
    local BUS="$I2C_CUSTOM_BUS"
    local ADDRESS="$I2C_CUSTOM_ADDRESS"
    local OUTPUT

    if [ -z "$BUS" ] || [ -z "$ADDRESS" ]
    then
        echo "SKIP: I2C_CUSTOM_BUS or I2C_CUSTOM_ADDRESS is not configured."
        return 3
    fi

    echo "I2C Bus     : $BUS"
    echo "Slave       : $ADDRESS"
    echo ""

    OUTPUT=$(i2cdetect -y "$BUS" 2>&1)

    echo "$OUTPUT"

    if echo "$OUTPUT" |
        grep -Eiq "(^|[[:space:]])${ADDRESS#0x}([[:space:]]|$)"
    then
        echo ""
        echo "Slave address $ADDRESS detected on I2C Bus $BUS."
        return 0
    fi

    echo ""
    echo "ERROR: Slave address $ADDRESS was not detected on I2C Bus $BUS."

    return 1
}

###############################################################################
# I2C-010 Command Helper
# Generic I2C Read
#
# Configuration:
#
# I2C_CUSTOM_BUS
# I2C_CUSTOM_ADDRESS
# I2C_CUSTOM_REGISTER
# I2C_CUSTOM_READ_LENGTH
###############################################################################

i2c_cmd_custom_read()
{
    local BUS="$I2C_CUSTOM_BUS"
    local ADDRESS="$I2C_CUSTOM_ADDRESS"
    local REGISTER="$I2C_CUSTOM_REGISTER"
    local READ_LENGTH="$I2C_CUSTOM_READ_LENGTH"

    if [ -z "$BUS" ] ||
       [ -z "$ADDRESS" ] ||
       [ -z "$REGISTER" ] ||
       [ -z "$READ_LENGTH" ]
    then
        echo "SKIP: Generic I2C read configuration is incomplete."
        return 3
    fi

    echo "I2C Bus     : $BUS"
    echo "Slave       : $ADDRESS"
    echo "Register    : $REGISTER"
    echo "Read Length : $READ_LENGTH"
    echo ""

    i2ctransfer \
        -y "$BUS" \
        w1@"$ADDRESS" "$REGISTER" \
        r"$READ_LENGTH"
}

###############################################################################
# I2C-011 Command Helper
# Generic I2C Write
#
# Configuration:
#
# I2C_CUSTOM_BUS
# I2C_CUSTOM_ADDRESS
# I2C_CUSTOM_REGISTER
# I2C_CUSTOM_WRITE_DATA
###############################################################################

i2c_cmd_custom_write()
{
    local BUS="$I2C_CUSTOM_BUS"
    local ADDRESS="$I2C_CUSTOM_ADDRESS"
    local REGISTER="$I2C_CUSTOM_REGISTER"
    local WRITE_DATA="$I2C_CUSTOM_WRITE_DATA"

    if [ -z "$BUS" ] ||
       [ -z "$ADDRESS" ] ||
       [ -z "$REGISTER" ] ||
       [ -z "$WRITE_DATA" ]
    then
        echo "SKIP: Generic I2C write configuration is incomplete."
        return 3
    fi

    echo "I2C Bus     : $BUS"
    echo "Slave       : $ADDRESS"
    echo "Register    : $REGISTER"
    echo "Write Data  : $WRITE_DATA"
    echo ""

    i2ctransfer \
        -y "$BUS" \
        w2@"$ADDRESS" "$REGISTER" "$WRITE_DATA"
}

###############################################################################
# I2C-012 Command Helper
# Generic I2C Write + Readback
#
# NOTE:
# This test should only be enabled for devices/registers where writing is safe.
###############################################################################

i2c_cmd_custom_write_readback()
{
    local BUS="$I2C_CUSTOM_BUS"
    local ADDRESS="$I2C_CUSTOM_ADDRESS"
    local REGISTER="$I2C_CUSTOM_REGISTER"
    local WRITE_DATA="$I2C_CUSTOM_WRITE_DATA"
    local READ_LENGTH="$I2C_CUSTOM_READ_LENGTH"

    if [ -z "$BUS" ] ||
       [ -z "$ADDRESS" ] ||
       [ -z "$REGISTER" ] ||
       [ -z "$WRITE_DATA" ] ||
       [ -z "$READ_LENGTH" ]
    then
        echo "SKIP: Generic I2C write/readback configuration is incomplete."
        return 3
    fi

    echo "I2C Bus     : $BUS"
    echo "Slave       : $ADDRESS"
    echo "Register    : $REGISTER"
    echo "Write Data  : $WRITE_DATA"
    echo "Read Length : $READ_LENGTH"
    echo ""

    echo "Write:"
    i2ctransfer \
        -y "$BUS" \
        w2@"$ADDRESS" "$REGISTER" "$WRITE_DATA"

    if [ $? -ne 0 ]
    then
        echo "ERROR: Generic I2C write failed."
        return 1
    fi

    sleep 0.01

    echo "Readback:"
    i2ctransfer \
        -y "$BUS" \
        w1@"$ADDRESS" "$REGISTER" \
        r"$READ_LENGTH"
}

###############################################################################
# I2C-013 Command Helper
# I2C adapter / bus information
###############################################################################

i2c_cmd_bus_information()
{
    local BUSES
    local BUS

    BUSES=$(i2c_get_buses)

    if [ -z "$BUSES" ]
    then
        echo "ERROR: No I2C buses detected."
        return 1
    fi

    echo "I2C adapter information:"
    echo ""

    i2cdetect -l

    echo ""
    echo "Detected bus device nodes:"
    echo ""

    for BUS in $BUSES
    do
        if [ -e "/dev/i2c-$BUS" ]
        then
            echo "Bus $BUS : /dev/i2c-$BUS"
        else
            echo "WARNING: /dev/i2c-$BUS not found."
        fi
    done

    return 0
}

###############################################################################
# I2C-014 Command Helper
# Invalid address/error handling
#
# Configuration:
#
# I2C_ERROR_TEST_BUS
# I2C_ERROR_TEST_ADDRESS
###############################################################################

i2c_cmd_invalid_address()
{
    local BUS="${I2C_ERROR_TEST_BUS:-0}"
    local ADDRESS="${I2C_ERROR_TEST_ADDRESS:-0x7E}"

    echo "I2C Bus       : $BUS"
    echo "Test Address  : $ADDRESS"
    echo ""
    echo "Attempting transaction to intentionally invalid/unused address."
    echo ""

    i2ctransfer \
        -y "$BUS" \
        w1@"$ADDRESS" 0x00 \
        r1 >/dev/null 2>&1

    if [ $? -eq 0 ]
    then
        echo "WARNING: Address $ADDRESS responded."
        echo "Verify that this address is unused before enabling this test."
        return 1
    fi

    echo "Expected I2C transaction failure received."
    echo "Invalid-address error handling verified."

    return 0
}

###############################################################################
# I2C-015 Command Helper
# Final I2C validation summary
###############################################################################

i2c_cmd_final_summary()
{
    echo "=============================================================="
    echo "I2C VALIDATION CONFIGURATION"
    echo "=============================================================="

    echo ""
    echo "Expected I2C-0 Devices:"
    echo "  0x48 - TMP1075NDRLR #1"
    echo "  0x49 - TMP1075NDRLR #2"
    echo "  0x50 - 24LC64T-E/MNY EEPROM"
    echo "  0x1F - PAC1931T-I/J6CX"

    echo ""
    echo "Expected I2C-1 Devices:"
    echo "  0x60 - ATECC608B"

    echo ""
    echo "Available I2C buses:"
    i2c_get_buses

    echo ""
    echo "I2C adapter information:"
    i2cdetect -l

    echo ""
    echo "I2C validation configuration summary completed."

    return 0
}

###############################################################################
# I2C-001 : Detect Available I2C Buses
###############################################################################

i2c_001()
{
    log_info "[I2C-001] Detect Available I2C Buses"

    run_command \
        "I2C-001" \
        "Detect Available I2C Buses" \
        "i2c_cmd_detect_buses"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to detect I2C buses."
        test_fail
        return
    fi

    TEST_MESSAGE="Available I2C buses detected successfully."

    test_pass
}

###############################################################################
# I2C-002 : Verify I2C Device Nodes
###############################################################################

i2c_002()
{
    log_info "[I2C-002] Verify I2C Device Nodes"

    run_command \
        "I2C-002" \
        "Verify I2C Device Nodes" \
        "i2c_cmd_device_nodes"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="No /dev/i2c-* device nodes detected."
        test_fail
        return
    fi

    TEST_MESSAGE="I2C device nodes detected successfully."

    test_pass
}

###############################################################################
# I2C-003 : Scan All I2C Buses
###############################################################################

i2c_003()
{
    log_info "[I2C-003] Scan All I2C Buses and Detect Slave Addresses"

    run_command \
        "I2C-003" \
        "Scan All I2C Buses and Detect Slave Addresses" \
        "i2c_cmd_scan_all_buses"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="One or more I2C buses could not be scanned."
        test_fail
        return
    fi

    TEST_MESSAGE="All available I2C buses scanned and detected slave addresses printed."

    test_pass
}

###############################################################################
# I2C-004 : TMP1075 #1
###############################################################################

i2c_004()
{
    log_info "[I2C-004] Verify TMP1075 Temperature Sensor #1"

    run_command \
        "I2C-004" \
        "Verify TMP1075 Temperature Sensor #1" \
        "i2c_cmd_tmp1075_1"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="TMP1075 sensor at 0x48 did not respond correctly."
        test_fail
        return
    fi

    TEST_MESSAGE="TMP1075 sensor at I2C-0 address 0x48 responded successfully."

    test_pass
}

###############################################################################
# I2C-005 : TMP1075 #2
###############################################################################

i2c_005()
{
    log_info "[I2C-005] Verify TMP1075 Temperature Sensor #2"

    run_command \
        "I2C-005" \
        "Verify TMP1075 Temperature Sensor #2" \
        "i2c_cmd_tmp1075_2"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="TMP1075 sensor at 0x49 did not respond correctly."
        test_fail
        return
    fi

    TEST_MESSAGE="TMP1075 sensor at I2C-0 address 0x49 responded successfully."

    test_pass
}

###############################################################################
# I2C-006 : EEPROM
###############################################################################

i2c_006()
{
    log_info "[I2C-006] Verify EEPROM 24LC64"

    run_command \
        "I2C-006" \
        "Verify EEPROM Write and Read" \
        "i2c_cmd_eeprom"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="EEPROM write/read operation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="EEPROM at I2C-0 address 0x50 responded successfully."

    test_pass
}

###############################################################################
# I2C-007 : PAC1931
###############################################################################

i2c_007()
{
    log_info "[I2C-007] Verify PAC1931 Current Sensor"

    run_command \
        "I2C-007" \
        "Verify PAC1931 Current Sensor" \
        "i2c_cmd_pac1931"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="PAC1931 communication failed."
        test_fail
        return
    fi

    TEST_MESSAGE="PAC1931 at I2C-0 address 0x1F responded successfully."

    test_pass
}

###############################################################################
# I2C-008 : ATECC608B
###############################################################################

i2c_008()
{
    log_info "[I2C-008] Verify ATECC608B Authentication IC"

    run_command \
        "I2C-008" \
        "Verify ATECC608B Authentication IC" \
        "i2c_cmd_atecc608b"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="ATECC608B communication failed."
        test_fail
        return
    fi

    TEST_MESSAGE="ATECC608B at I2C-1 address 0x60 responded successfully."

    test_pass
}

###############################################################################
# I2C-009 : Generic Address
###############################################################################

i2c_009()
{
    log_info "[I2C-009] Verify Custom I2C Slave Address"

    run_command \
        "I2C-009" \
        "Verify Custom I2C Slave Address" \
        "i2c_cmd_custom_address"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="Custom I2C slave address is not configured."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Configured custom I2C slave address was not detected."
        test_fail
        return
    fi

    TEST_MESSAGE="Configured custom I2C slave address detected successfully."

    test_pass
}

###############################################################################
# I2C-010 : Generic Read
###############################################################################

i2c_010()
{
    log_info "[I2C-010] Verify Custom I2C Read"

    run_command \
        "I2C-010" \
        "Verify Custom I2C Read" \
        "i2c_cmd_custom_read"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="Custom I2C read configuration is not available."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Custom I2C read operation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Custom I2C read operation completed successfully."

    test_pass
}

###############################################################################
# I2C-011 : Generic Write
###############################################################################

i2c_011()
{
    log_info "[I2C-011] Verify Custom I2C Write"

    run_command \
        "I2C-011" \
        "Verify Custom I2C Write" \
        "i2c_cmd_custom_write"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="Custom I2C write configuration is not available."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Custom I2C write operation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Custom I2C write operation completed successfully."

    test_pass
}

###############################################################################
# I2C-012 : Generic Write + Readback
###############################################################################

i2c_012()
{
    log_info "[I2C-012] Verify Custom I2C Write and Readback"

    run_command \
        "I2C-012" \
        "Verify Custom I2C Write and Readback" \
        "i2c_cmd_custom_write_readback"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="Custom I2C write/readback configuration is not available."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Custom I2C write/readback operation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Custom I2C write/readback operation completed successfully."

    test_pass
}

###############################################################################
# I2C-013 : Bus Information
###############################################################################

i2c_013()
{
    log_info "[I2C-013] Verify I2C Bus Information"

    run_command \
        "I2C-013" \
        "Verify I2C Bus Information" \
        "i2c_cmd_bus_information"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to retrieve I2C adapter information."
        test_fail
        return
    fi

    TEST_MESSAGE="I2C bus and adapter information retrieved successfully."

    test_pass
}

###############################################################################
# I2C-014 : Invalid Address Handling
###############################################################################

i2c_014()
{
    log_info "[I2C-014] Verify I2C Invalid Address Handling"

    run_command \
        "I2C-014" \
        "Verify I2C Invalid Address Handling" \
        "i2c_cmd_invalid_address"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="I2C invalid-address error handling verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="I2C invalid-address error handling verified successfully."

    test_pass
}

###############################################################################
# I2C-015 : Final Summary
###############################################################################

i2c_015()
{
    log_info "[I2C-015] I2C Final Validation Summary"

    run_command \
        "I2C-015" \
        "I2C Final Validation Summary" \
        "i2c_cmd_final_summary"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to generate I2C validation summary."
        test_fail
        return
    fi

    TEST_MESSAGE="I2C validation summary generated successfully."

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
        -n "Detect Available I2C Buses" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "i2c,bus,detect" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect all available Linux I2C buses."

    register_test \
        -i "I2C-002" \
        -f i2c_002 \
        -n "Verify I2C Device Nodes" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "i2c,device,node" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify that /dev/i2c-* device nodes are available."

    register_test \
        -i "I2C-003" \
        -f i2c_003 \
        -n "Scan All I2C Buses and Detect Slave Addresses" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "i2c,scan,address,i2cdetect" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Scan every available I2C bus and print all detected slave addresses."

    register_test \
        -i "I2C-004" \
        -f i2c_004 \
        -n "Verify TMP1075 Temperature Sensor #1" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 40 \
        -g "i2c,tmp1075,temperature,0x48" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify TMP1075 sensor communication at I2C-0 address 0x48."

    register_test \
        -i "I2C-005" \
        -f i2c_005 \
        -n "Verify TMP1075 Temperature Sensor #2" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 50 \
        -g "i2c,tmp1075,temperature,0x49" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify TMP1075 sensor communication at I2C-0 address 0x49."

    register_test \
        -i "I2C-006" \
        -f i2c_006 \
        -n "Verify EEPROM Write and Read" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 60 \
        -g "i2c,eeprom,24lc64,read,write" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify 24LC64 EEPROM write and read communication."

    register_test \
        -i "I2C-007" \
        -f i2c_007 \
        -n "Verify PAC1931 Current Sensor" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 70 \
        -g "i2c,pac1931,current,0x1f" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify PAC1931 current sensor communication."

    register_test \
        -i "I2C-008" \
        -f i2c_008 \
        -n "Verify ATECC608B Authentication IC" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 80 \
        -g "i2c,atecc608b,authentication,0x60" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify ATECC608B authentication IC communication."

    register_test \
        -i "I2C-009" \
        -f i2c_009 \
        -n "Verify Custom I2C Slave Address" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 90 \
        -g "i2c,custom,address" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify a configurable custom I2C slave address."

    register_test \
        -i "I2C-010" \
        -f i2c_010 \
        -n "Verify Custom I2C Read" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 100 \
        -g "i2c,custom,read" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify a configurable custom I2C read operation."

    register_test \
        -i "I2C-011" \
        -f i2c_011 \
        -n "Verify Custom I2C Write" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 110 \
        -g "i2c,custom,write" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify a configurable custom I2C write operation."

    register_test \
        -i "I2C-012" \
        -f i2c_012 \
        -n "Verify Custom I2C Write and Readback" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 120 \
        -g "i2c,custom,write,readback" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify configurable I2C write followed by readback."

    register_test \
        -i "I2C-013" \
        -f i2c_013 \
        -n "Verify I2C Bus Information" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 130 \
        -g "i2c,bus,adapter" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify I2C adapter and bus information."

    register_test \
        -i "I2C-014" \
        -f i2c_014 \
        -n "Verify I2C Invalid Address Handling" \
        -c "peripheral" \
        -t "auto" \
        -p "low" \
        -o 140 \
        -g "i2c,error,invalid,address" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify expected I2C failure when accessing an unused address."

    register_test \
        -i "I2C-015" \
        -f i2c_015 \
        -n "I2C Final Validation Summary" \
        -c "peripheral" \
        -t "auto" \
        -p "low" \
        -o 150 \
        -g "i2c,summary,validation" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Generate the final I2C validation configuration and bus summary."
}

###############################################################################
# Module Initialization
###############################################################################

i2c_init()
{
    log_info "========================================="
    log_info "Starting I2C Validation"
    log_info "========================================="

    if ! command -v i2cdetect >/dev/null 2>&1
    then
        TEST_MESSAGE="i2cdetect utility is not installed."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    if ! command -v i2ctransfer >/dev/null 2>&1
    then
        TEST_MESSAGE="i2ctransfer utility is not installed."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    log_info "Expected I2C-0 Devices:"
    log_info "  0x48 - TMP1075NDRLR #1"
    log_info "  0x49 - TMP1075NDRLR #2"
    log_info "  0x50 - 24LC64T-E/MNY EEPROM"
    log_info "  0x1F - PAC1931T-I/J6CX"

    log_info "Expected I2C-1 Device:"
    log_info "  0x60 - ATECC608B"

    i2c_register_tests

    return 0
}

###############################################################################
# Module Initialization When Sourced
###############################################################################

i2c_init

###############################################################################
# End Of File
###############################################################################
```
