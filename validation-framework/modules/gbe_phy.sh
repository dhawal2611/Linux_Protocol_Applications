#!/bin/bash
###############################################################################
# Module      : GbE PHY Validation
# Description : Gigabit Ethernet PHY validation test cases
###############################################################################

#
# GBEPHY-001
# Read PHY Status
#
gbephy_001()
{
    run_command \
        "GBEPHY-001" \
        "Read PHY Status" \
        "ethtool ${ETH_INTERFACE}"
}

#
# GBEPHY-002
# Dump PHY Register
#
gbephy_002()
{
    run_command \
        "GBEPHY-002" \
        "Dump PHY Register" \
        "phytool read ${ETH_INTERFACE}/${PHY_ADDR}/0"
}

#
# GBEPHY-003
# Read BMCR Register
#
gbephy_003()
{
    run_command \
        "GBEPHY-003" \
        "Read BMCR Register" \
        "phytool read ${ETH_INTERFACE}/${PHY_ADDR}/${PHY_BMCR_REG}"
}

#
# GBEPHY-004
# Disconnect Ethernet Cable (Manual Test)
#
gbephy_004()
{
    log_info "[GBEPHY-004] Disconnect Ethernet Cable"

    echo ""
    echo "==========================================================="
    echo " MANUAL TEST REQUIRED"
    echo "==========================================================="
    echo "Disconnect the Ethernet cable from the DUT."
    echo ""
    echo "Expected Result:"
    echo "  - Link should go DOWN."
    echo "  - LEDs should indicate link loss."
    echo ""
    read -p "Press ENTER after disconnecting the cable..."

    run_command \
        "GBEPHY-004" \
        "Verify Link Down" \
        "ethtool ${ETH_INTERFACE}"
}

#
# GBEPHY-005
# Reconnect Ethernet Cable (Manual Test)
#
gbephy_005()
{
    log_info "[GBEPHY-005] Reconnect Ethernet Cable"

    echo ""
    echo "==========================================================="
    echo " MANUAL TEST REQUIRED"
    echo "==========================================================="
    echo "Reconnect the Ethernet cable."
    echo ""
    echo "Expected Result:"
    echo "  - Link should come UP."
    echo "  - PHY should renegotiate successfully."
    echo ""
    read -p "Press ENTER after reconnecting the cable..."

    run_command \
        "GBEPHY-005" \
        "Verify Link Up" \
        "ethtool ${ETH_INTERFACE}"
}

###############################################################################
# Execute all GbE PHY Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting GbE PHY Validation"
    log_info "========================================="

    gbephy_001
    gbephy_002
    gbephy_003
    gbephy_004
    gbephy_005

    log_info "========================================="
    log_info "GbE PHY Validation Completed"
    log_info "========================================="
}
