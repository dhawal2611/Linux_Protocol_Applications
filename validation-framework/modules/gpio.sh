#!/bin/bash
###############################################################################
# Module      : GPIO Validation
# Description : GPIO validation test cases
###############################################################################

#
# GPIO-001
# Export GPIO
#
gpio_001()
{
    run_command \
        "GPIO-001" \
        "Export GPIO${GPIO_NUM}" \
        "echo ${GPIO_NUM} > ${GPIO_SYSFS}/export"
}

#
# GPIO-002
# Set Direction Output
#
gpio_002()
{
    run_command \
        "GPIO-002" \
        "Set GPIO${GPIO_NUM} Direction Output" \
        "echo out > ${GPIO_PATH}/direction"
}

#
# GPIO-003
# Drive GPIO HIGH
#
gpio_003()
{
    run_command \
        "GPIO-003" \
        "Drive GPIO${GPIO_NUM} HIGH" \
        "echo 1 > ${GPIO_PATH}/value"
}

#
# GPIO-004
# Drive GPIO LOW
#
gpio_004()
{
    run_command \
        "GPIO-004" \
        "Drive GPIO${GPIO_NUM} LOW" \
        "echo 0 > ${GPIO_PATH}/value"
}

#
# GPIO-005
# Set Direction Input
#
gpio_005()
{
    run_command \
        "GPIO-005" \
        "Set GPIO${GPIO_NUM} Direction Input" \
        "echo in > ${GPIO_PATH}/direction"
}

#
# GPIO-006
# Read GPIO Value
#
gpio_006()
{
    run_command \
        "GPIO-006" \
        "Read GPIO${GPIO_NUM}" \
        "cat ${GPIO_PATH}/value"
}

#
# GPIO-007
# Unexport GPIO
#
gpio_007()
{
    run_command \
        "GPIO-007" \
        "Unexport GPIO${GPIO_NUM}" \
        "echo ${GPIO_NUM} > ${GPIO_SYSFS}/unexport"
}

###############################################################################
# Execute all GPIO Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting GPIO Validation"
    log_info "GPIO Number : ${GPIO_NUM}"
    log_info "========================================="

    for GPIO_NUM in "${GPIO_LIST[@]}"
    do
        gpio_001
        gpio_002
        gpio_003
        gpio_004
        gpio_005
        gpio_006
        gpio_007
    done
    log_info "========================================="
    log_info "GPIO Validation Completed"
    log_info "========================================="
}
