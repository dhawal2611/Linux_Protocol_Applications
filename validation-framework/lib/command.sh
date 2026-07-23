#!/bin/bash
###############################################################################
# File        : command.sh
# Description : Command Execution Library
###############################################################################

###############################################################################
# Execute Command
###############################################################################
run_command()
{
    local TEST_ID="$1"
    local TEST_NAME="$2"
    local CMD="$3"

    local START_TIME
    local END_TIME
    local EXEC_TIME
    local OUTPUT
    local STATUS

    START_TIME=$(date +%s)

    #
    # Console Output
    #
    log_info "[$TEST_ID] $TEST_NAME"

    #
    # Log Header
    #
    {
        echo "======================================================================="
        echo "Test ID        : $TEST_ID"
        echo "Test Name      : $TEST_NAME"
        echo "Start Time     : $(date)"
        echo "Command        : $CMD"
        echo "======================================================================="
    } >> "$LOG_FILE"

    #
    # Empty Command Check
    #
    if [ -z "$CMD" ]
    then
        echo "ERROR : Empty Command" >> "$LOG_FILE"

        log_fail "$TEST_ID"

        echo "" >> "$LOG_FILE"

        return 1
    fi

    #
    # Execute Command
    #
    OUTPUT=$(eval "$CMD" 2>&1)
    STATUS=$?

    #
    # Save Command Output ONLY to Log File
    #
    echo "$OUTPUT" >> "$LOG_FILE"

    END_TIME=$(date +%s)
    EXEC_TIME=$((END_TIME - START_TIME))

    {
        echo ""
        echo "Exit Status    : $STATUS"
        echo "Execution Time : ${EXEC_TIME} sec"
        echo "======================================================================="
        echo ""
    } >> "$LOG_FILE"

    #
    # Console Status
    #
    if [ "$STATUS" -eq 0 ]
    then
        log_pass "$TEST_ID"
    else
        log_fail "$TEST_ID"
    fi

    return "$STATUS"
}

###############################################################################
# Manual Test
###############################################################################
manual_test()
{
    local TEST_ID="$1"
    local TEST_NAME="$2"
    local DESCRIPTION="$3"
    local EXPECTED="$4"

    log_info "[$TEST_ID] $TEST_NAME"

    echo ""
    echo "=================================================================="
    echo "MANUAL TEST REQUIRED"
    echo "=================================================================="
    echo "$DESCRIPTION"
    echo ""
    echo "Expected Result:"
    echo "  $EXPECTED"
    echo ""
    echo "Press 'p' for PASS"
    echo "Press 'f' for FAIL"
    echo "=================================================================="

    while true
    do
        read -rp "Enter Result (p/f): " RESULT

        case "$RESULT" in

            p|P)

                log_pass "$TEST_ID"

                {
                    echo "======================================================================="
                    echo "Test ID        : $TEST_ID"
                    echo "Test Name      : $TEST_NAME"
                    echo "Result         : PASS"
                    echo "Date           : $(date)"
                    echo "======================================================================="
                    echo ""
                } >> "$LOG_FILE"

                return 0
                ;;

            f|F)

                log_fail "$TEST_ID"

                {
                    echo "======================================================================="
                    echo "Test ID        : $TEST_ID"
                    echo "Test Name      : $TEST_NAME"
                    echo "Result         : FAIL"
                    echo "Date           : $(date)"
                    echo "======================================================================="
                    echo ""
                } >> "$LOG_FILE"

                return 1
                ;;

            *)

                echo "Invalid input. Please enter p or f."
                ;;

        esac
    done
}
