#!/bin/bash
###############################################################################
# Module      : systemd Validation
# Description : systemd service manager validation test cases
###############################################################################

#
# SYSTEMD-001
# Verify Init Process
#
systemd_001()
{
    run_command \
        "SYSTEMD-001" \
        "Verify Init Process" \
        "ps -p 1"
}

#
# SYSTEMD-002
# List Failed Units
#
systemd_002()
{
    run_command \
        "SYSTEMD-002" \
        "List Failed Units" \
        "systemctl --failed"
}

#
# SYSTEMD-003
# List Active Services
#
systemd_003()
{
    run_command \
        "SYSTEMD-003" \
        "List Active Services" \
        "systemctl list-units --type=service"
}

#
# SYSTEMD-004
# Start Service
#
systemd_004()
{
    run_command \
        "SYSTEMD-004" \
        "Start ${SYSTEMD_SERVICE} Service" \
        "systemctl start ${SYSTEMD_SERVICE}"
}

#
# SYSTEMD-005
# Stop Service
#
systemd_005()
{
    run_command \
        "SYSTEMD-005" \
        "Stop ${SYSTEMD_SERVICE} Service" \
        "systemctl stop ${SYSTEMD_SERVICE}"
}

#
# SYSTEMD-006
# Restart Service
#
systemd_006()
{
    run_command \
        "SYSTEMD-006" \
        "Restart ${SYSTEMD_SERVICE} Service" \
        "systemctl restart ${SYSTEMD_SERVICE}"
}

#
# SYSTEMD-007
# Enable Service
#
systemd_007()
{
    run_command \
        "SYSTEMD-007" \
        "Enable ${SYSTEMD_SERVICE} Service" \
        "systemctl enable ${SYSTEMD_SERVICE}"
}

#
# SYSTEMD-008
# Disable Service
#
systemd_008()
{
    run_command \
        "SYSTEMD-008" \
        "Disable ${SYSTEMD_SERVICE} Service" \
        "systemctl disable ${SYSTEMD_SERVICE}"
}

#
# SYSTEMD-009
# Analyze Boot Time
#
systemd_009()
{
    run_command \
        "SYSTEMD-009" \
        "Analyze Boot Time" \
        "systemd-analyze"
}

#
# SYSTEMD-010
# Show Critical Boot Chain
#
systemd_010()
{
    run_command \
        "SYSTEMD-010" \
        "Show Critical Boot Chain" \
        "systemd-analyze critical-chain"
}

###############################################################################
# Execute all systemd Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting systemd Validation"
    log_info "Service : ${SYSTEMD_SERVICE}"
    log_info "========================================="

    systemd_001
    systemd_002
    systemd_003
    systemd_004
    systemd_005
    systemd_006
    systemd_007
    systemd_008
    systemd_009
    systemd_010

    log_info "========================================="
    log_info "systemd Validation Completed"
    log_info "========================================="
}
