#!/bin/bash
###############################################################################
# Module      : DHCP Validation
# Description : DHCP client validation test cases
###############################################################################

#
# DHCP-001
# Release DHCP Lease
#
dhcp_001()
{
    run_command \
        "DHCP-001" \
        "Release DHCP Lease" \
        "udhcpc -R -i ${ETH_INTERFACE}"
}

#
# DHCP-002
# Request New DHCP Lease
#
dhcp_002()
{
    run_command \
        "DHCP-002" \
        "Request New DHCP Lease" \
        "udhcpc -i ${ETH_INTERFACE}"
}

#
# DHCP-003
# Verify Assigned IP Address
#
dhcp_003()
{
    run_command \
        "DHCP-003" \
        "Verify Assigned IP Address" \
        "ip addr show ${ETH_INTERFACE}"
}

#
# DHCP-004
# Verify Routing Table
#
dhcp_004()
{
    run_command \
        "DHCP-004" \
        "Verify Routing Table" \
        "ip route"
}

###############################################################################
# Execute all DHCP Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting DHCP Validation"
    log_info "Interface : ${ETH_INTERFACE}"
    log_info "========================================="

    dhcp_001
    dhcp_002
    dhcp_003
    dhcp_004

    log_info "========================================="
    log_info "DHCP Validation Completed"
    log_info "========================================="
}
