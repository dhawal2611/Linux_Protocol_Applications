#!/bin/bash
###############################################################################
# Module      : PCIe Validation
# Description : PCIe interface validation test cases
###############################################################################

#
# PCIE-001
# Check PCIe Kernel Messages
#
pcie_001()
{
    run_command \
        "PCIE-001" \
        "Check PCIe Kernel Messages" \
        "dmesg | grep -i pci"
}

#
# PCIE-002
# Enumerate PCIe Devices
#
pcie_002()
{
    run_command \
        "PCIE-002" \
        "Enumerate PCIe Devices" \
        "lspci"
}

#
# PCIE-003
# Verify PCIe Link Details
#
pcie_003()
{
    run_command \
        "PCIE-003" \
        "Verify PCIe Link Details" \
        "lspci -vv"
}

#
# PCIE-004
# Rescan PCIe Bus
#
pcie_004()
{
    run_command \
        "PCIE-004" \
        "Rescan PCIe Bus" \
        "echo 1 > /sys/bus/pci/rescan"
}

#
# PCIE-005
# Check MSI Capability
#
pcie_005()
{
    run_command \
        "PCIE-005" \
        "Check MSI Capability" \
        "lspci -vv | grep -i MSI"
}

###############################################################################
# Execute all PCIe Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting PCIe Validation"
    log_info "========================================="

    pcie_001
    pcie_002
    pcie_003
    pcie_004
    pcie_005

    log_info "========================================="
    log_info "PCIe Validation Completed"
    log_info "========================================="
}
