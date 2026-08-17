#!/bin/bash
###############################################################################
#
# File        : gpio.sh
# Description : GPIO Peripheral Validation Module
#
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="GPIO"
MODULE_DESCRIPTION="GPIO Peripheral Validation"

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    echo
    cat
    test
)

###############################################################################
# Helper : Calculate Sysfs GPIO Number
#
# Logical GPIO:
#     18
#
# GPIO offset:
#     512
#
# Sysfs GPIO:
#     512 + 18 = 530
#
###############################################################################

gpio_get_sysfs_gpio()
{
    local GPIO="$1"

    if ! [[ "$GPIO" =~ ^[0-9]+$ ]]
    then
        echo "ERROR: Invalid GPIO number: $GPIO"
        return 1
    fi

    if ! [[ "$GPIO_OFFSET" =~ ^[0-9]+$ ]]
    then
        echo "ERROR: Invalid GPIO_OFFSET: $GPIO_OFFSET"
        return 1
    fi

    echo $((GPIO_OFFSET + GPIO))

    return 0
}

###############################################################################
# Helper : Check GPIO Sysfs Interface
###############################################################################

gpio_check_sysfs_interface()
{
    if [ ! -d "$GPIO_SYSFS_BASE" ]
    then
        echo "ERROR: GPIO sysfs interface not available."
        echo "Expected : $GPIO_SYSFS_BASE"
        return 1
    fi

    if [ ! -w "$GPIO_SYSFS_BASE/export" ]
    then
        echo "ERROR: GPIO export interface is not writable."
        echo "Path : $GPIO_SYSFS_BASE/export"
        return 1
    fi

    if [ ! -w "$GPIO_SYSFS_BASE/unexport" ]
    then
        echo "ERROR: GPIO unexport interface is not writable."
        echo "Path : $GPIO_SYSFS_BASE/unexport"
        return 1
    fi

    return 0
}

###############################################################################
# Helper : Check Configured GPIO List
###############################################################################

gpio_validate_configuration()
{
    local GPIO

    if [ -z "$GPIO_PINS" ]
    then
        echo "ERROR: GPIO_PINS is not configured."
        return 1
    fi

    if ! [[ "$GPIO_OFFSET" =~ ^[0-9]+$ ]]
    then
        echo "ERROR: GPIO_OFFSET is invalid: $GPIO_OFFSET"
        return 1
    fi

    for GPIO in $GPIO_PINS
    do
        if ! [[ "$GPIO" =~ ^[0-9]+$ ]]
        then
            echo "ERROR: Invalid GPIO pin configured: $GPIO"
            return 1
        fi
    done

    return 0
}

###############################################################################
# Helper : Check Whether GPIO Is Already Exported
###############################################################################

gpio_is_exported()
{
    local SYSFS_GPIO="$1"

    [ -d "$GPIO_SYSFS_BASE/gpio${SYSFS_GPIO}" ]
}

###############################################################################
# Helper : Export GPIO
###############################################################################

gpio_export()
{
    local SYSFS_GPIO="$1"

    echo "$SYSFS_GPIO" > "$GPIO_SYSFS_BASE/export" 2>/dev/null

    if [ $? -ne 0 ]
    then
        #
        # GPIO may already be exported.
        #
        if gpio_is_exported "$SYSFS_GPIO"
        then
            return 0
        fi

        echo "ERROR: Failed to export GPIO $SYSFS_GPIO"
        return 1
    fi

    #
    # Wait until sysfs directory appears.
    #
    local COUNT=0

    while [ ! -d "$GPIO_SYSFS_BASE/gpio${SYSFS_GPIO}" ]
    do
        sleep 0.1

        COUNT=$((COUNT + 1))

        if [ "$COUNT" -ge 20 ]
        then
            echo "ERROR: GPIO sysfs node did not appear:"
            echo "$GPIO_SYSFS_BASE/gpio${SYSFS_GPIO}"
            return 1
        fi
    done

    return 0
}

###############################################################################
# Helper : Set GPIO Direction
###############################################################################

gpio_set_direction()
{
    local SYSFS_GPIO="$1"
    local DIRECTION="$2"
    local DIRECTION_FILE="$GPIO_SYSFS_BASE/gpio${SYSFS_GPIO}/direction"

    if [ ! -e "$DIRECTION_FILE" ]
    then
        echo "ERROR: GPIO direction file does not exist:"
        echo "$DIRECTION_FILE"
        return 1
    fi

    echo "$DIRECTION" > "$DIRECTION_FILE" 2>/dev/null

    if [ $? -ne 0 ]
    then
        echo "ERROR: Failed to set GPIO $SYSFS_GPIO direction to $DIRECTION"
        return 1
    fi

    #
    # Verify direction.
    #
    local CURRENT_DIRECTION

    CURRENT_DIRECTION=$(cat "$DIRECTION_FILE" 2>/dev/null)

    if [ "$CURRENT_DIRECTION" != "$DIRECTION" ]
    then
        echo "ERROR: GPIO direction verification failed."
        echo "Expected : $DIRECTION"
        echo "Actual   : $CURRENT_DIRECTION"
        return 1
    fi

    return 0
}

###############################################################################
# Helper : Set GPIO Value
###############################################################################

gpio_set_value()
{
    local SYSFS_GPIO="$1"
    local VALUE="$2"
    local VALUE_FILE="$GPIO_SYSFS_BASE/gpio${SYSFS_GPIO}/value"

    if [ ! -e "$VALUE_FILE" ]
    then
        echo "ERROR: GPIO value file does not exist:"
        echo "$VALUE_FILE"
        return 1
    fi

    echo "$VALUE" > "$VALUE_FILE" 2>/dev/null

    if [ $? -ne 0 ]
    then
        echo "ERROR: Failed to set GPIO $SYSFS_GPIO value to $VALUE"
        return 1
    fi

    #
    # Verify value.
    #
    local CURRENT_VALUE

    CURRENT_VALUE=$(cat "$VALUE_FILE" 2>/dev/null)

    if [ "$CURRENT_VALUE" != "$VALUE" ]
    then
        echo "ERROR: GPIO value verification failed."
        echo "Expected : $VALUE"
        echo "Actual   : $CURRENT_VALUE"
        return 1
    fi

    return 0
}

###############################################################################
# Helper : Get GPIO Value
###############################################################################

gpio_get_value()
{
    local SYSFS_GPIO="$1"
    local VALUE_FILE="$GPIO_SYSFS_BASE/gpio${SYSFS_GPIO}/value"

    if [ ! -e "$VALUE_FILE" ]
    then
        return 1
    fi

    cat "$VALUE_FILE" 2>/dev/null

    return $?
}

###############################################################################
# Helper : Unexport GPIO
###############################################################################

gpio_unexport()
{
    local SYSFS_GPIO="$1"

    #
    # GPIO may already be unexported.
    #
    if ! gpio_is_exported "$SYSFS_GPIO"
    then
        return 0
    fi

    echo "$SYSFS_GPIO" > "$GPIO_SYSFS_BASE/unexport" 2>/dev/null

    if [ $? -ne 0 ]
    then
        echo "ERROR: Failed to unexport GPIO $SYSFS_GPIO"
        return 1
    fi

    #
    # Verify GPIO node disappeared.
    #
    local COUNT=0

    while [ -d "$GPIO_SYSFS_BASE/gpio${SYSFS_GPIO}" ]
    do
        sleep 0.1

        COUNT=$((COUNT + 1))

        if [ "$COUNT" -ge 20 ]
        then
            echo "ERROR: GPIO node still exists after unexport:"
            echo "$GPIO_SYSFS_BASE/gpio${SYSFS_GPIO}"
            return 1
        fi
    done

    return 0
}

###############################################################################
# GPIO Cleanup
#
# Ensures GPIO is unexported even if a test fails.
###############################################################################

gpio_cleanup()
{
    local SYSFS_GPIO="$1"

    if [ -n "$SYSFS_GPIO" ]
    then
        gpio_unexport "$SYSFS_GPIO" >/dev/null 2>&1
    fi
}

###############################################################################
# GPIO Discovery
#
# Validate GPIO sysfs and configured GPIOs.
#
###############################################################################

gpio_cmd_discover()
{
    local GPIO
    local SYSFS_GPIO

    echo "Detecting GPIO sysfs interface..."
    echo

    #
    # Check sysfs interface.
    #
    if ! gpio_check_sysfs_interface
    then
        GPIO_DISCOVERY_DONE=0
        return 1
    fi

    #
    # Validate GPIO configuration.
    #
    if ! gpio_validate_configuration
    then
        GPIO_DISCOVERY_DONE=0
        return 1
    fi

    echo "GPIO sysfs base : $GPIO_SYSFS_BASE"
    echo "GPIO offset     : $GPIO_OFFSET"
    echo

    echo "Configured GPIO pins:"
    echo

    for GPIO in $GPIO_PINS
    do
        SYSFS_GPIO=$(gpio_get_sysfs_gpio "$GPIO")

        if [ $? -ne 0 ]
        then
            GPIO_DISCOVERY_DONE=0
            return 1
        fi

        echo "Logical GPIO : $GPIO"
        echo "Sysfs GPIO   : $SYSFS_GPIO"

        #
        # If GPIO is already exported, verify its node.
        #
        if gpio_is_exported "$SYSFS_GPIO"
        then
            echo "Status       : EXPORTED"
        else
            echo "Status       : AVAILABLE"
        fi

        echo
    done

    GPIO_DISCOVERY_DONE=1

    echo "GPIO discovery completed successfully."

    return 0
}

###############################################################################
# Verify GPIO Discovery
###############################################################################

gpio_verify_discovery()
{
    if [ "$GPIO_DISCOVERY_DONE" -ne 1 ]
    then
        echo "ERROR: GPIO discovery has not been completed."
        return 1
    fi

    return 0
}

###############################################################################
# Validate Individual GPIO
#
# This performs:
#
#   1. Calculate sysfs GPIO
#   2. Export
#   3. Set direction = out
#   4. Set HIGH
#   5. Verify HIGH
#   6. Wait 5 seconds
#   7. Set LOW
#   8. Verify LOW
#   9. Wait 5 seconds
#  10. Unexport
#
###############################################################################

gpio_cmd_validate_pin()
{
    local GPIO_PIN="$1"
    local SYSFS_GPIO
    local GPIO_PATH
    local VALUE

    echo "Validating GPIO $GPIO_PIN"
    echo

    ###########################################################################
    # Validate GPIO pin argument
    ###########################################################################

    if [ -z "$GPIO_PIN" ]
    then
        echo "ERROR: GPIO pin not specified."
        return 1
    fi

    ###########################################################################
    # Validate GPIO_OFFSET
    ###########################################################################

    if ! [[ "$GPIO_OFFSET" =~ ^[0-9]+$ ]]
    then
        echo "ERROR: Invalid GPIO_OFFSET: $GPIO_OFFSET"
        return 1
    fi

    ###########################################################################
    # Validate GPIO pin exists in configured GPIO_PINS
    ###########################################################################

    local PIN_CONFIGURED=0
    local PIN

    for PIN in "${GPIO_PINS[@]}"
    do
        if [ "$PIN" = "$GPIO_PIN" ]
        then
            PIN_CONFIGURED=1
            break
        fi
    done

    if [ "$PIN_CONFIGURED" -ne 1 ]
    then
        echo "ERROR: GPIO $GPIO_PIN is not configured."
        echo "Configured GPIOs: $GPIO_PINS"
        return 1
    fi

    ###########################################################################
    # Calculate Linux Sysfs GPIO number
    ###########################################################################

    SYSFS_GPIO=$((GPIO_OFFSET + GPIO_PIN))
    GPIO_PATH="${GPIO_SYSFS_BASE}/gpio${SYSFS_GPIO}"

    echo "GPIO Configuration:"
    echo "  Logical GPIO : $GPIO_PIN"
    echo "  GPIO Offset  : $GPIO_OFFSET"
    echo "  Sysfs GPIO   : $SYSFS_GPIO"
    echo "  Sysfs Path   : $GPIO_PATH"
    echo

    ###########################################################################
    # Export GPIO
    ###########################################################################

    if [ ! -d "$GPIO_PATH" ]
    then
        echo "Exporting GPIO $SYSFS_GPIO..."

        if ! echo "$SYSFS_GPIO" > "$GPIO_SYSFS_BASE/export"
        then
            echo "ERROR: Failed to export GPIO $SYSFS_GPIO."
            return 1
        fi

        sleep 1

        if [ ! -d "$GPIO_PATH" ]
        then
            echo "ERROR: GPIO $SYSFS_GPIO was not created after export."
            return 1
        fi

        echo "GPIO $SYSFS_GPIO exported successfully."
    else
        echo "GPIO $SYSFS_GPIO is already exported."
    fi

    ###########################################################################
    # Set direction to output
    ###########################################################################

    echo "Setting GPIO $SYSFS_GPIO direction to output..."

    if ! echo "out" > "$GPIO_PATH/direction"
    then
        echo "ERROR: Failed to set GPIO $SYSFS_GPIO direction."
        echo "$SYSFS_GPIO" > "$GPIO_SYSFS_BASE/unexport" 2>/dev/null
        return 1
    fi

    echo "GPIO $SYSFS_GPIO direction set to output successfully."

    ###########################################################################
    # Drive HIGH
    ###########################################################################

    echo
    echo "Driving GPIO $GPIO_PIN HIGH..."

    if ! echo "1" > "$GPIO_PATH/value"
    then
        echo "ERROR: Failed to drive GPIO $GPIO_PIN HIGH."
        echo "$SYSFS_GPIO" > "$GPIO_SYSFS_BASE/unexport" 2>/dev/null
        return 1
    fi

    VALUE=$(cat "$GPIO_PATH/value" 2>/dev/null)

    if [ "$VALUE" != "1" ]
    then
        echo "ERROR: GPIO $GPIO_PIN failed to reach HIGH state."
        echo "$SYSFS_GPIO" > "$GPIO_SYSFS_BASE/unexport" 2>/dev/null
        return 1
    fi

    echo "GPIO $GPIO_PIN HIGH successfully."
    echo "Waiting 5 seconds..."
    sleep 5

    ###########################################################################
    # Drive LOW
    ###########################################################################

    echo
    echo "Driving GPIO $GPIO_PIN LOW..."

    if ! echo "0" > "$GPIO_PATH/value"
    then
        echo "ERROR: Failed to drive GPIO $GPIO_PIN LOW."
        echo "$SYSFS_GPIO" > "$GPIO_SYSFS_BASE/unexport" 2>/dev/null
        return 1
    fi

    VALUE=$(cat "$GPIO_PATH/value" 2>/dev/null)

    if [ "$VALUE" != "0" ]
    then
        echo "ERROR: GPIO $GPIO_PIN failed to reach LOW state."
        echo "$SYSFS_GPIO" > "$GPIO_SYSFS_BASE/unexport" 2>/dev/null
        return 1
    fi

    echo "GPIO $GPIO_PIN LOW successfully."
    echo "Waiting 5 seconds..."
    sleep 5

    ###########################################################################
    # Unexport GPIO
    ###########################################################################

    echo
    echo "Unexporting GPIO $SYSFS_GPIO..."

    if ! echo "$SYSFS_GPIO" > "$GPIO_SYSFS_BASE/unexport"
    then
        echo "ERROR: Failed to unexport GPIO $SYSFS_GPIO."
        return 1
    fi

    sleep 1

    if [ -d "$GPIO_PATH" ]
    then
        echo "ERROR: GPIO $SYSFS_GPIO still exists after unexport."
        return 1
    fi

    echo "GPIO $SYSFS_GPIO unexported successfully."
    echo

    echo "GPIO $GPIO_PIN validation completed successfully."

    return 0
}

###############################################################################
# GPIO-001 : Detect GPIO Sysfs Interface
###############################################################################

gpio_001()
{
    log_info "[GPIO-001] Detect GPIO Sysfs Interface and Configured GPIOs"

    run_command \
        "GPIO-001" \
        "Detect GPIO Sysfs Interface and Configured GPIOs" \
        "gpio_cmd_discover"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="GPIO sysfs interface or configured GPIO detection failed."
        test_fail
        return
    fi

    TEST_MESSAGE="GPIO sysfs interface and configured GPIOs detected successfully."

    test_pass
}

###############################################################################
# GPIO-002 : Validate GPIO 17
###############################################################################

gpio_002()
{
    log_info "[GPIO-002] Validate GPIO ${GPIO_PINS[0]}"

    run_command \
        "GPIO-002" \
        "Validate GPIO ${GPIO_PINS[0]}" \
        "gpio_cmd_validate_pin ${GPIO_PINS[0]}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="GPIO ${GPIO_PINS[0]} validation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="GPIO ${GPIO_PINS[0]} HIGH/LOW validation completed successfully."

    test_pass
}

###############################################################################
# GPIO-003 : Validate GPIO 18
###############################################################################

gpio_003()
{
    log_info "[GPIO-003] Validate GPIO ${GPIO_PINS[1]}"

    run_command \
        "GPIO-003" \
        "Validate GPIO ${GPIO_PINS[1]}" \
        "gpio_cmd_validate_pin ${GPIO_PINS[1]}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="GPIO ${GPIO_PINS[1]} validation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="GPIO ${GPIO_PINS[1]} HIGH/LOW validation completed successfully."

    test_pass
}

###############################################################################
# GPIO-004 : Validate GPIO 22
###############################################################################

gpio_004()
{
    log_info "[GPIO-004] Validate GPIO ${GPIO_PINS[2]}"

    run_command \
        "GPIO-004" \
        "Validate GPIO ${GPIO_PINS[2]}" \
        "gpio_cmd_validate_pin ${GPIO_PINS[2]}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="GPIO ${GPIO_PINS[2]} validation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="GPIO ${GPIO_PINS[2]} HIGH/LOW validation completed successfully."

    test_pass
}

###############################################################################
# GPIO-005 : Validate GPIO 23
###############################################################################

gpio_005()
{
    log_info "[GPIO-005] Validate GPIO ${GPIO_PINS[3]}"

    run_command \
        "GPIO-005" \
        "Validate GPIO ${GPIO_PINS[3]}" \
        "gpio_cmd_validate_pin ${GPIO_PINS[3]}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="GPIO ${GPIO_PINS[3]} validation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="GPIO ${GPIO_PINS[3]} HIGH/LOW validation completed successfully."

    test_pass
}

###############################################################################
# Register GPIO Tests
###############################################################################

gpio_register_tests()
{
    register_test \
        -i "GPIO-001" \
        -f gpio_001 \
        -n "Detect GPIO Sysfs Interface and Configured GPIOs" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "gpio,sysfs,detect,discover" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect GPIO sysfs interface and validate configured GPIO pins."

    register_test \
        -i "GPIO-002" \
        -f gpio_002 \
        -n "Validate GPIO ${GPIO_PINS[0]}" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "gpio,${GPIO_PINS[0]},high,low,sysfs" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Export GPIO ${GPIO_PINS[0]}, configure output, drive HIGH and LOW, verify values and unexport."

    register_test \
        -i "GPIO-003" \
        -f gpio_003 \
        -n "Validate GPIO ${GPIO_PINS[1]}" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "gpio,${GPIO_PINS[1]},high,low,sysfs" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Export GPIO ${GPIO_PINS[1]}, configure output, drive HIGH and LOW, verify values and unexport."

    register_test \
        -i "GPIO-004" \
        -f gpio_004 \
        -n "Validate GPIO ${GPIO_PINS[2]}" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 40 \
        -g "gpio,${GPIO_PINS[2]},high,low,sysfs" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Export GPIO ${GPIO_PINS[2]}, configure output, drive HIGH and LOW, verify values and unexport."

    register_test \
        -i "GPIO-005" \
        -f gpio_005 \
        -n "Validate GPIO ${GPIO_PINS[3]}" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 50 \
        -g "gpio,${GPIO_PINS[3]},high,low,sysfs" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Export GPIO ${GPIO_PINS[3]}, configure output, drive HIGH and LOW, verify values and unexport."
}

###############################################################################
# Module Initialization
###############################################################################

gpio_init()
{
    log_info "===============================================================================" 
    log_info "Starting GPIO Validation"
    log_info "===============================================================================" 

    log_info "GPIO Configuration:"
    log_info "  Sysfs Base    : $GPIO_SYSFS_BASE"
    log_info "  GPIO Offset   : $GPIO_OFFSET"
    log_info "  GPIO Pins     : $GPIO_PINS"
    log_info "  Test Interval : ${GPIO_TEST_INTERVAL}s"

    gpio_register_tests

    return 0
}

###############################################################################
# Module Initialization When Sourced
###############################################################################

gpio_init

###############################################################################
# End Of File
###############################################################################

