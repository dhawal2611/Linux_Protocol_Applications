#!/bin/bash
###############################################################################
# Module      : SPI Validation
# Description : SPI Loopback validation test cases
###############################################################################

#
# SPI-001
# Check spidev Node
#
spi_001()
{
    run_command \
        "SPI-001" \
        "Check spidev Node" \
        "ls /dev/spidev*"
}

#
# SPI-002
# Run SPI Loopback Test
#
spi_002()
{
    run_command \
        "SPI-002" \
        "Run SPI Loopback Test" \
        "spidev_test -D /dev/spidev0.0 -v"
}

#
# SPI-003
# Run 4KB Transfer
#
spi_003()
{
    run_command \
        "SPI-003" \
        "Run 4KB SPI Transfer" \
        "spidev_test -D /dev/spidev0.0 -s 4096"
}

#
# SPI-004
# Repeat SPI Transfer 1000 Times
#
spi_004()
{
    run_command \
        "SPI-004" \
        "Repeat SPI Transfer 1000 Times" \
        "for i in \$(seq 1 1000); do spidev_test -D /dev/spidev0.0; done"
}

###############################################################################
# Execute all SPI Test Cases
###############################################################################
run_test()
{
    log_info "========================================="
    log_info "Starting SPI Validation"
    log_info "========================================="

    spi_001
    spi_002
    spi_003
    spi_004

    log_info "========================================="
    log_info "SPI Validation Completed"
    log_info "========================================="
}
