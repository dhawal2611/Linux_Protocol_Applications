#!/bin/bash
###############################################################################
# Module      : Ethernet Validation
# Description : Ethernet interface validation test cases
###############################################################################

#
# ETH-001
# Check Network Interface
#
eth_001()
{
    run_command \
        "ETH-001" \
        "Check Network Interface" \
        "ip addr show ${ETH_INTERFACE}"
}

#
# ETH-002
# Verify PHY Link
#
eth_002()
{
    run_command \
        "ETH-002" \
        "Verify PHY Link" \
        "ethtool ${ETH_INTERFACE}"
}

#
# ETH-003
# Acquire DHCP Lease
#
eth_003()
{
    run_command \
        "ETH-003" \
        "Acquire DHCP Lease" \
        "udhcpc -i ${ETH_INTERFACE}"
}

#
# ETH-004
# Ping Gateway
#
eth_004()
{
    run_command \
        "ETH-004" \
        "Ping Gateway" \
        "ping -c 4 ${GATEWAY_IP}"
}

#
# ETH-005
# Run Throughput Test
#
eth_005()
{
    run_command \
        "ETH-005" \
        "Run iPerf3 Throughput Test" \
        "iperf3 -c ${IPERF_SERVER}"
}

#
# ETH-006
# Check Ethernet Statistics
#
eth_006()
{
    run_command \
        "ETH-006" \
        "Check Ethernet Statistics" \
        "ethtool -S ${ETH_INTERFACE}"
}

#
# ETH-007
# Configure Jumbo Frame MTU
#
eth_007()
{
    run_command \
        "ETH-007" \
        "Configure Jumbo Frame MTU" \
        "ip link set ${ETH_INTERFACE} mtu ${JUMBO_MTU}"
}

#
# ETH-008
# Ping Using Jumbo Frames
#
eth_008()
{
    run_command \
        "ETH-008" \
        "Ping Using Jumbo Frames" \
        "ping -M do -s 8972 ${PEER_IP}"
}

###############################################################################
# Execute all Ethernet Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Ethernet Validation"
    log_info "Interface : ${ETH_INTERFACE}"
    log_info "========================================="

    eth_001
    eth_002
    eth_003
    eth_004
    eth_005
    eth_006
    eth_007
    eth_008

    log_info "========================================="
    log_info "Ethernet Validation Completed"
    log_info "========================================="
}

register_test \
    -i "ETH-001" \
    -f eth_001 \
    -n "Verify Ethernet Link" \
    -c network \
    -t auto \
    -p high \
    -o 30 \
    -g "ethernet,link" \
    -w "Networking Team" \
    -b "RPi4,IMX6ULL" \
    -e yes \
    -d "Verify Ethernet link state and speed."
