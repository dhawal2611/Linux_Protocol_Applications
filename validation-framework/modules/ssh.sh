#!/bin/bash
###############################################################################
# Module      : SSH Validation
# Description : SSH server validation test cases
###############################################################################

#
# SSH-001
# Verify SSH Service Status
#
ssh_001()
{
    run_command \
        "SSH-001" \
        "Verify SSH Service Status" \
        "systemctl status sshd"
}

#
# SSH-002
# Verify Remote SSH Login
#
ssh_002()
{
    run_command \
        "SSH-002" \
        "Verify Remote SSH Login" \
        "ssh -o BatchMode=yes -o ConnectTimeout=10 ${SSH_USER}@${DUT_IP} exit"
}

#
# SSH-003
# Copy File Using SCP
#
ssh_003()
{
    run_command \
        "SSH-003" \
        "Copy File Using SCP" \
        "scp ${SCP_TEST_FILE} ${SSH_USER}@${DUT_IP}:${SCP_DEST}"
}

#
# SSH-004
# Open Multiple SSH Sessions
#
ssh_004()
{
    run_command \
        "SSH-004" \
        "Open Multiple SSH Sessions" \
        "for i in \$(seq 1 5); do ssh -o BatchMode=yes ${SSH_USER}@${DUT_IP} exit; done"
}

###############################################################################
# Execute all SSH Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting SSH Validation"
    log_info "Target : ${SSH_USER}@${DUT_IP}"
    log_info "========================================="

    ssh_001
    ssh_002
    ssh_003
    ssh_004

    log_info "========================================="
    log_info "SSH Validation Completed"
    log_info "========================================="
}
