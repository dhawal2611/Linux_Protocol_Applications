#!/bin/bash
###############################################################################
# Module      : journald Validation
# Description : systemd-journald validation test cases
###############################################################################

#
# JOURNALD-001
# Verify Journald Service
#
journald_001()
{
    run_command \
        "JOURNALD-001" \
        "Verify systemd-journald Service" \
        "systemctl status systemd-journald"
}

#
# JOURNALD-002
# View Current Boot Logs
#
journald_002()
{
    run_command \
        "JOURNALD-002" \
        "View Current Boot Logs" \
        "journalctl -b"
}

#
# JOURNALD-003
# View Kernel Logs
#
journald_003()
{
    run_command \
        "JOURNALD-003" \
        "View Kernel Logs" \
        "journalctl -k"
}

#
# JOURNALD-004
# Check Journal Disk Usage
#
journald_004()
{
    run_command \
        "JOURNALD-004" \
        "Check Journal Disk Usage" \
        "journalctl --disk-usage"
}

#
# JOURNALD-005
# Rotate Journal Logs
#
journald_005()
{
    run_command \
        "JOURNALD-005" \
        "Rotate Journal Logs" \
        "journalctl --rotate"
}

#
# JOURNALD-006
# Vacuum Old Journal Logs
#
journald_006()
{
    run_command \
        "JOURNALD-006" \
        "Vacuum Journal Logs Older Than ${JOURNAL_VACUUM_TIME}" \
        "journalctl --vacuum-time=${JOURNAL_VACUUM_TIME}"
}

#
# JOURNALD-007
# Verify Persistent Journal
#
journald_007()
{
    run_command \
        "JOURNALD-007" \
        "Verify Persistent Journal Directory" \
        "ls -l ${JOURNAL_DIR}"
}

#
# JOURNALD-008
# Export Journal Logs
#
journald_008()
{
    run_command \
        "JOURNALD-008" \
        "Export Journal Logs" \
        "journalctl > ${JOURNAL_EXPORT}"
}

#
# JOURNALD-009
# Reboot System
#
journald_009()
{
    log_info "[JOURNALD-009] Manual Reboot Test"

    echo ""
    echo "==========================================================="
    echo "               MANUAL TEST REQUIRED"
    echo "==========================================================="
    echo "The system will reboot."
    echo ""
    echo "After reboot execute:"
    echo ""
    echo "    ./validate.sh journald_post"
    echo ""
    read -p "Press ENTER to reboot..."

    run_command \
        "JOURNALD-009" \
        "Reboot System" \
        "reboot"
}

###############################################################################
# Execute all Journald Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Journald Validation"
    log_info "========================================="

    journald_001
    journald_002
    journald_003
    journald_004
    journald_005
    journald_006
    journald_007
    journald_008
    journald_009

    log_info "========================================="
    log_info "Journald Validation Completed"
    log_info "========================================="
}
