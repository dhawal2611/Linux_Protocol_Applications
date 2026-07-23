#!/bin/bash
###############################################################################
# Module      : I2C Validation
# Description : I2C bus validation test cases
###############################################################################

#
# I2C-001
# List Available I2C Buses
#
i2c_001()
{
    run_command \
        "I2C-001" \
        "List Available I2C Buses" \
        "i2cdetect -l"
}

#
# I2C-002
# Scan I2C Bus 0
#
i2c_002()
{
    run_command \
        "I2C-002" \
        "Scan I2C Bus 0" \
        "i2cdetect -y 0"
}

#
# I2C-003
# Read Register 0x00
#
i2c_003()
{
    run_command \
        "I2C-003" \
        "Read Register 0x00 from Slave 0x50" \
        "i2cget -y 0 0x50 0x00"
}

#
# I2C-004
# Write Register 0x00
#
i2c_004()
{
    run_command \
        "I2C-004" \
        "Write 0x12 to Register 0x00 of Slave 0x50" \
        "i2cset -y 0 0x50 0x00 0x12"
}

#
# I2C-005
# Verify Register Value
#
i2c_005()
{
    run_command \
        "I2C-005" \
        "Verify Register 0x00" \
        "i2cget -y 0 0x50 0x00"
}

#
# I2C-006
# Stress Read Test (1000 Iterations)
#
i2c_006()
{
    run_command \
        "I2C-006" \
        "Stress Read Register 0x00 (1000 Iterations)" \
        "for i in \$(seq 1 1000); do i2cget -y 0 0x50 0x00; done"
}

###############################################################################
# Execute all I2C Test Cases
###############################################################################
run_test()
{
    log_info "========================================="
    log_info "Starting I2C Validation"
    log_info "========================================="

    i2c_001
    i2c_002
    i2c_003
    i2c_004
    i2c_005
    i2c_006

    log_info "========================================="
    log_info "I2C Validation Completed"
    log_info "========================================="
}
