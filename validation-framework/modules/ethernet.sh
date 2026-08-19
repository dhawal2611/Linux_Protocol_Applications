#!/bin/bash
###############################################################################
#
# File        : ethernet.sh
#
# Description : Ethernet Interface Validation Module
#
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="ETHERNET"
MODULE_DESCRIPTION="Ethernet Interface Validation"

###############################################################################
# Runtime Variables
###############################################################################

ETH_DISCOVERY_DONE=0

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    ip
    ethtool
    ping
    awk
    grep
    cut
    tr
)

###############################################################################
# Helper Functions
###############################################################################

###############################################################################
# Get local IP address of interface
###############################################################################

eth_get_local_ip()
{
    local INTERFACE="$1"

    ip -4 addr show "$INTERFACE" 2>/dev/null |
        awk '/inet / {print $2}' |
        cut -d/ -f1 |
        head -n1
}

###############################################################################
# Check interface exists
###############################################################################

eth_interface_exists()
{
    local INTERFACE="$1"

    ip link show "$INTERFACE" >/dev/null 2>&1
}

###############################################################################
# Get server IP configured for interface
###############################################################################

eth_get_server_ip()
{
    local INTERFACE="$1"
    local ENTRY
    local SERVER_IP

    for ENTRY in "${ETH_SERVER_MAP[@]}"
    do
        if [ "${ENTRY%%:*}" = "$INTERFACE" ]
        then
            SERVER_IP="${ENTRY#*:}"
            echo "$SERVER_IP"
            return 0
        fi
    done

    return 1
}

###############################################################################
# Validate configured interface
###############################################################################

eth_verify_interface()
{
    local INTERFACE="$1"

    if ! eth_interface_exists "$INTERFACE"
    then
        echo "ERROR: Ethernet interface $INTERFACE not found."
        return 1
    fi

    echo "Ethernet interface detected successfully."
    echo "Interface : $INTERFACE"

    return 0
}

###############################################################################
# ETH-001
#
# Detect Ethernet Interfaces
###############################################################################

eth_cmd_discover()
{
    local INTERFACE
    local STATUS=0
    local LOCAL_IP

    echo "Detecting configured Ethernet interfaces..."
    echo

    for INTERFACE in $ETH_INTERFACES
    do
        echo "Ethernet Interface : $INTERFACE"

        if eth_interface_exists "$INTERFACE"
        then
            LOCAL_IP=$(eth_get_local_ip "$INTERFACE")

            echo "  Status   : DETECTED"

            if [ -n "$LOCAL_IP" ]
            then
                echo "  Local IP : $LOCAL_IP"
            else
                echo "  Local IP : NOT CONFIGURED"
            fi
        else
            echo "  Status   : NOT DETECTED"
            STATUS=1
        fi

        echo
    done

    ETH_DISCOVERY_DONE=1

    return "$STATUS"
}

###############################################################################
# ETH-002
#
# Verify Ethernet Interface State
###############################################################################

eth_cmd_verify_state()
{
    local INTERFACE
    local STATE

    for INTERFACE in $ETH_INTERFACES
    do
        echo "Checking interface state : $INTERFACE"

        if ! eth_verify_interface "$INTERFACE"
        then
            return 1
        fi

        STATE=$(cat "/sys/class/net/$INTERFACE/operstate" 2>/dev/null)

        echo "  State : $STATE"

        if [ "$STATE" != "up" ]
        then
            echo "ERROR: Interface $INTERFACE is not UP."
            return 1
        fi

        echo "Interface $INTERFACE is UP."
        echo
    done

    return 0
}

###############################################################################
# ETH-003
#
# Verify Ethernet Link
###############################################################################

eth_cmd_verify_link()
{
    local INTERFACE
    local LINK

    for INTERFACE in $ETH_INTERFACES
    do
        echo "Checking Ethernet link : $INTERFACE"

        if ! eth_verify_interface "$INTERFACE"
        then
            return 1
        fi

        LINK=$(ethtool "$INTERFACE" 2>/dev/null |
            awk -F': ' '/Link detected/ {print $2}')

        echo "  Link detected : $LINK"

        if [ "$LINK" != "yes" ]
        then
            echo "ERROR: Ethernet link is DOWN on $INTERFACE."
            return 1
        fi

        echo "Ethernet link is UP on $INTERFACE."
        echo
    done

    return 0
}

###############################################################################
# ETH-004
#
# Verify Ethernet Speed & Duplex
###############################################################################

eth_cmd_verify_speed_duplex()
{
    local INTERFACE
    local SPEED
    local DUPLEX

    for INTERFACE in $ETH_INTERFACES
    do
        echo "Checking Ethernet speed and duplex : $INTERFACE"

        if ! eth_verify_interface "$INTERFACE"
        then
            return 1
        fi

        SPEED=$(ethtool "$INTERFACE" 2>/dev/null |
            awk -F': ' '/Speed:/ {print $2}')

        DUPLEX=$(ethtool "$INTERFACE" 2>/dev/null |
            awk -F': ' '/Duplex:/ {print $2}')

        echo "  Speed  : $SPEED"
        echo "  Duplex : $DUPLEX"

        if [ -z "$SPEED" ] || [ "$SPEED" = "Unknown!" ]
        then
            echo "ERROR: Unable to determine Ethernet speed."
            return 1
        fi

        if [ -z "$DUPLEX" ] || [ "$DUPLEX" = "Unknown!" ]
        then
            echo "ERROR: Unable to determine Ethernet duplex."
            return 1
        fi

        echo "Ethernet speed and duplex verified."
        echo
    done

    return 0
}

###############################################################################
# ETH-005
#
# Verify Local IP Configuration
###############################################################################

eth_cmd_verify_local_ip()
{
    local INTERFACE
    local LOCAL_IP

    for INTERFACE in $ETH_INTERFACES
    do
        echo "Checking local IP : $INTERFACE"

        if ! eth_verify_interface "$INTERFACE"
        then
            return 1
        fi

        LOCAL_IP=$(eth_get_local_ip "$INTERFACE")

        echo "  Local IP : $LOCAL_IP"

        if [ -z "$LOCAL_IP" ]
        then
            echo "ERROR: No IPv4 address configured on $INTERFACE."
            return 1
        fi

        echo "Local IP configuration verified."
        echo
    done

    return 0
}

###############################################################################
# ETH-006
#
# Verify Ethernet Connectivity
#
# Ping the configured server corresponding to each interface.
###############################################################################

eth_cmd_verify_connectivity()
{
    local INTERFACE
    local SERVER_IP

    for INTERFACE in $ETH_INTERFACES
    do
        SERVER_IP=$(eth_get_server_ip "$INTERFACE")

        if [ -z "$SERVER_IP" ]
        then
            echo "ERROR: No server IP configured for $INTERFACE."
            return 1
        fi

        echo "Testing connectivity:"
        echo "  Interface : $INTERFACE"
        echo "  Server IP : $SERVER_IP"

        if ! eth_verify_interface "$INTERFACE"
        then
            return 1
        fi

        if ! ping -I "$INTERFACE" -c 4 -W 2 "$SERVER_IP"
        then
            echo "ERROR: Ping failed on $INTERFACE."
            return 1
        fi

        echo "Ethernet connectivity verified."
        echo
    done

    return 0
}

###############################################################################
# ETH-007
#
# Verify Ethernet Packet Loss
###############################################################################

eth_cmd_verify_packet_loss()
{
    local INTERFACE
    local SERVER_IP
    local LOSS

    for INTERFACE in $ETH_INTERFACES
    do
        SERVER_IP=$(eth_get_server_ip "$INTERFACE")

        if [ -z "$SERVER_IP" ]
        then
            echo "ERROR: No server IP configured for $INTERFACE."
            return 1
        fi

        echo "Checking packet loss:"
        echo "  Interface : $INTERFACE"
        echo "  Server IP : $SERVER_IP"

        if ! eth_verify_interface "$INTERFACE"
        then
            return 1
        fi

        LOSS=$(ping \
            -I "$INTERFACE" \
            -c 10 \
            -W 2 \
            "$SERVER_IP" 2>&1 |
            awk -F', ' '/packet loss/ {print $3}' | awk '{print $1}')

        echo "  Packet Loss : $LOSS"

        case "$LOSS" in
            0%|0.0%)
                echo "Packet loss verification successful."
                ;;
            *)
                echo "ERROR: Packet loss detected."
                return 1
                ;;
        esac

        echo
    done

    return 0
}

###############################################################################
# ETH-008
#
# Verify Ethernet Throughput
#
# iperf3 client runs toward the configured server IP.
###############################################################################

eth_cmd_verify_throughput()
{
    local INTERFACE
    local SERVER_IP

    if ! command -v iperf3 >/dev/null 2>&1
    then
        echo "ERROR: iperf3 command not found."
        return 1
    fi

    for INTERFACE in $ETH_INTERFACES
    do
        SERVER_IP=$(eth_get_server_ip "$INTERFACE")

        if [ -z "$SERVER_IP" ]
        then
            echo "ERROR: No iperf3 server IP configured for $INTERFACE."
            return 1
        fi

        echo "Running iperf3:"
        echo "  Interface : $INTERFACE"
        echo "  Server IP : $SERVER_IP"
        echo "  Duration  : ${ETH_IPERF_DURATION}s"

        if ! eth_verify_interface "$INTERFACE"
        then
            return 1
        fi

        iperf3 \
            -c "$SERVER_IP" \
            -B "$(eth_get_local_ip "$INTERFACE")" \
            -t "$ETH_IPERF_DURATION"

        if [ $? -ne 0 ]
        then
            echo "ERROR: iperf3 throughput test failed on $INTERFACE."
            return 1
        fi

        echo "Ethernet throughput test completed."
        echo
    done

    return 0
}

###############################################################################
# ETH-009
#
# Verify Ethernet Interface Statistics
###############################################################################

eth_cmd_verify_statistics()
{
    local INTERFACE
    local RX_PACKETS
    local TX_PACKETS
    local RX_ERRORS
    local TX_ERRORS

    for INTERFACE in $ETH_INTERFACES
    do
        echo "Ethernet statistics : $INTERFACE"

        if ! eth_verify_interface "$INTERFACE"
        then
            return 1
        fi

        RX_PACKETS=$(cat "/sys/class/net/$INTERFACE/statistics/rx_packets")
        TX_PACKETS=$(cat "/sys/class/net/$INTERFACE/statistics/tx_packets")
        RX_ERRORS=$(cat "/sys/class/net/$INTERFACE/statistics/rx_errors")
        TX_ERRORS=$(cat "/sys/class/net/$INTERFACE/statistics/tx_errors")

        echo "  RX Packets : $RX_PACKETS"
        echo "  TX Packets : $TX_PACKETS"
        echo "  RX Errors  : $RX_ERRORS"
        echo "  TX Errors  : $TX_ERRORS"

        if [ "$RX_ERRORS" -ne 0 ] || [ "$TX_ERRORS" -ne 0 ]
        then
            echo "ERROR: Ethernet errors detected."
            return 1
        fi

        echo "Ethernet statistics verified."
        echo
    done

    return 0
}

###############################################################################
# ETH-010
#
# Verify Ethernet TX/RX Data
#
# Compare interface packet counters before and after traffic.
###############################################################################

eth_cmd_verify_tx_rx()
{
    local INTERFACE
    local SERVER_IP
    local RX_BEFORE
    local TX_BEFORE
    local RX_AFTER
    local TX_AFTER

    for INTERFACE in $ETH_INTERFACES
    do
        SERVER_IP=$(eth_get_server_ip "$INTERFACE")

        if [ -z "$SERVER_IP" ]
        then
            echo "ERROR: No server IP configured for $INTERFACE."
            return 1
        fi

        echo "Checking Ethernet TX/RX data:"
        echo "  Interface : $INTERFACE"
        echo "  Server IP : $SERVER_IP"

        if ! eth_verify_interface "$INTERFACE"
        then
            return 1
        fi

        RX_BEFORE=$(cat "/sys/class/net/$INTERFACE/statistics/rx_packets")
        TX_BEFORE=$(cat "/sys/class/net/$INTERFACE/statistics/tx_packets")

        echo "  RX before : $RX_BEFORE"
        echo "  TX before : $TX_BEFORE"

        ping \
            -I "$INTERFACE" \
            -c 5 \
            -W 2 \
            "$SERVER_IP" >/dev/null 2>&1

        sleep 1

        RX_AFTER=$(cat "/sys/class/net/$INTERFACE/statistics/rx_packets")
        TX_AFTER=$(cat "/sys/class/net/$INTERFACE/statistics/tx_packets")

        echo "  RX after  : $RX_AFTER"
        echo "  TX after  : $TX_AFTER"

        if [ "$RX_AFTER" -le "$RX_BEFORE" ]
        then
            echo "ERROR: RX packet count did not increase."
            return 1
        fi

        if [ "$TX_AFTER" -le "$TX_BEFORE" ]
        then
            echo "ERROR: TX packet count did not increase."
            return 1
        fi

        echo "Ethernet TX/RX data transfer verified."
        echo
    done

    return 0
}

###############################################################################
# Test Cases
###############################################################################

eth_001()
{
    log_info "[ETH-001] Detect Ethernet Interfaces"

    run_command \
        "ETH-001" \
        "Detect Ethernet Interfaces" \
        "eth_cmd_discover"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="One or more configured Ethernet interfaces were not detected."
        test_fail
        return
    fi

    TEST_MESSAGE="All configured Ethernet interfaces detected successfully."
    test_pass
}

eth_002()
{
    log_info "[ETH-002] Verify Ethernet Interface State"

    run_command \
        "ETH-002" \
        "Verify Ethernet Interface State" \
        "eth_cmd_verify_state"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Ethernet interface state verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="All Ethernet interfaces are UP."
    test_pass
}

eth_003()
{
    log_info "[ETH-003] Verify Ethernet Link"

    run_command \
        "ETH-003" \
        "Verify Ethernet Link" \
        "eth_cmd_verify_link"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Ethernet link verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Ethernet link verified successfully."
    test_pass
}

eth_004()
{
    log_info "[ETH-004] Verify Ethernet Speed & Duplex"

    run_command \
        "ETH-004" \
        "Verify Ethernet Speed & Duplex" \
        "eth_cmd_verify_speed_duplex"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Ethernet speed or duplex verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Ethernet speed and duplex verified successfully."
    test_pass
}

eth_005()
{
    log_info "[ETH-005] Verify Local IP Configuration"

    run_command \
        "ETH-005" \
        "Verify Local IP Configuration" \
        "eth_cmd_verify_local_ip"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Local IP configuration verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Local IP configuration verified successfully."
    test_pass
}

eth_006()
{
    log_info "[ETH-006] Verify Ethernet Connectivity"

    run_command \
        "ETH-006" \
        "Verify Ethernet Connectivity" \
        "eth_cmd_verify_connectivity"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Ethernet connectivity test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Ethernet connectivity verified successfully."
    test_pass
}

eth_007()
{
    log_info "[ETH-007] Verify Ethernet Packet Loss"

    run_command \
        "ETH-007" \
        "Verify Ethernet Packet Loss" \
        "eth_cmd_verify_packet_loss"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Ethernet packet loss detected."
        test_fail
        return
    fi

    TEST_MESSAGE="Ethernet packet loss verification completed successfully."
    test_pass
}

eth_008()
{
    log_info "[ETH-008] Verify Ethernet Throughput"

    run_command \
        "ETH-008" \
        "Verify Ethernet Throughput" \
        "eth_cmd_verify_throughput"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Ethernet throughput test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Ethernet throughput test completed successfully."
    test_pass
}

eth_009()
{
    log_info "[ETH-009] Verify Ethernet Interface Statistics"

    run_command \
        "ETH-009" \
        "Verify Ethernet Interface Statistics" \
        "eth_cmd_verify_statistics"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Ethernet statistics verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Ethernet interface statistics verified successfully."
    test_pass
}

eth_010()
{
    log_info "[ETH-010] Verify Ethernet TX/RX Data"

    run_command \
        "ETH-010" \
        "Verify Ethernet TX/RX Data" \
        "eth_cmd_verify_tx_rx"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Ethernet TX/RX data validation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Ethernet TX/RX data transfer verified successfully."
    test_pass
}

###############################################################################
# Register Ethernet Tests
###############################################################################

ethernet_register_tests()
{
    register_test \
        -i "ETH-001" \
        -f eth_001 \
        -n "Detect Ethernet Interfaces" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "ethernet,detect,interface" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect all configured Ethernet interfaces."

    register_test \
        -i "ETH-002" \
        -f eth_002 \
        -n "Verify Ethernet Interface State" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "ethernet,state,up" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify configured Ethernet interfaces are operational."

    register_test \
        -i "ETH-003" \
        -f eth_003 \
        -n "Verify Ethernet Link" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "ethernet,link,ethtool" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify Ethernet physical link is detected."

    register_test \
        -i "ETH-004" \
        -f eth_004 \
        -n "Verify Ethernet Speed & Duplex" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 40 \
        -g "ethernet,speed,duplex" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify Ethernet negotiated speed and duplex."

    register_test \
        -i "ETH-005" \
        -f eth_005 \
        -n "Verify Local IP Configuration" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 50 \
        -g "ethernet,ip,address" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify each configured Ethernet interface has a local IPv4 address."

    register_test \
        -i "ETH-006" \
        -f eth_006 \
        -n "Verify Ethernet Connectivity" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 60 \
        -g "ethernet,ping,connectivity" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Ping the configured remote server through each Ethernet interface."

    register_test \
        -i "ETH-007" \
        -f eth_007 \
        -n "Verify Ethernet Packet Loss" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 70 \
        -g "ethernet,ping,packet,loss" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify Ethernet connectivity has zero packet loss."

    register_test \
        -i "ETH-008" \
        -f eth_008 \
        -n "Verify Ethernet Throughput" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 80 \
        -g "ethernet,iperf3,throughput" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure Ethernet throughput using iperf3."

    register_test \
        -i "ETH-009" \
        -f eth_009 \
        -n "Verify Ethernet Interface Statistics" \
        -c "peripheral" \
        -t "auto" \
        -p "medium" \
        -o 90 \
        -g "ethernet,statistics,errors" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify Ethernet packet statistics and error counters."

    register_test \
        -i "ETH-010" \
        -f eth_010 \
        -n "Verify Ethernet TX/RX Data" \
        -c "peripheral" \
        -t "auto" \
        -p "high" \
        -o 100 \
        -g "ethernet,tx,rx,data" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify Ethernet TX and RX packet counters increase during traffic."
}

###############################################################################
# Module Initialization
###############################################################################

ethernet_init()
{
    log_info "========================================="
    log_info "Starting Ethernet Validation"
    log_info "========================================="

    log_info "Configured Ethernet Interfaces:"
    log_info "  $ETH_INTERFACES"

    for ENTRY in "${ETH_SERVER_MAP[@]}"
    do
        log_info "  Server Mapping : $ENTRY"
    done

    ethernet_register_tests

    return 0
}

###############################################################################
# Initialize Module
###############################################################################

ethernet_init

###############################################################################
# End Of File
###############################################################################

