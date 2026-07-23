#!/bin/bash
###############################################################################
# Module      : SGMII Validation
# Description : SGMII interface validation test cases
###############################################################################

#
# SGMII-001
# Verify Network Interface
#
sgmii_001()
{
    run_command \
        "SGMII-001" \
        "Verify SGMII Interface" \
        "ip link show ${SGMII_INTERFACE}"
}

#
# SGMII-002
# Verify Link Negotiation
#
sgmii_002()
{
    run_command \
        "SGMII-002" \
        "Check Link Negotiation" \
        "ethtool ${SGMII_INTERFACE}"
}

#
# SGMII-003
# Ping Peer
#
sgmii_003()
{
    run_command \
        "SGMII-003" \
        "Ping Peer Device" \
        "ping -c 4 ${SGMII_PEER_IP}"
}

#
# SGMII-004
# Run Throughput Test
#
sgmii_004()
{
    run_command \
        "SGMII-004" \
        "Run iPerf3 Throughput Test" \
        "iperf3 -c ${SGMII_IPERF_SERVER}"
}

#
# SGMII-005
# Check Interface Statistics
#
sgmii_005()
{
    run_command \
        "SGMII-005" \
        "Check Interface Statistics" \
        "ethtool -S ${SGMII_INTERFACE}"
}

#
# SGMII-006
# Verify Link Synchronization Lock
#
sgmii_006()
{
    run_command \
        "SGMII-006" \
        "Verify Link Synchronization Lock" \
        "ethtool ${SGMII_INTERFACE}; \
         mii-tool -v ${SGMII_INTERFACE}; \
         mii-tool -v ${SGMII_INTERFACE} | grep -q 'basic status:.*link ok' && \
         echo 'LINK SYNC LOCK: ACHIEVED' || \
         echo 'LINK SYNC LOCK: FAILED'"
}

###############################################################################
# Execute all SGMII Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting SGMII Validation"
    log_info "Interface : ${SGMII_INTERFACE}"
    log_info "========================================="

    sgmii_001
    sgmii_002
    sgmii_003
    sgmii_004
    sgmii_005
    sgmii_006

    log_info "========================================="
    log_info "SGMII Validation Completed"
    log_info "========================================="
}
