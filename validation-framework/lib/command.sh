#!/bin/bash
###############################################################################
# File        : command.sh
# Description : Command Execution Library
###############################################################################

###############################################################################
# Global Variables
###############################################################################

COMMAND_OUTPUT=""
COMMAND_STATUS=0

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
    local RESULT

    START_TIME=$(date +%s)

    #
    # Console/Logger Information
    #
    #log_info "[$TEST_ID] $TEST_NAME"

    #
    # Test Header
    #
    write_test_log "
################################################################################
# TEST START : [$TEST_ID] $TEST_NAME
################################################################################

Test ID         : $TEST_ID
Test Name       : $TEST_NAME
Start Time      : $(date)
Command         : $CMD

--------------------------------------------------------------------------------
Command Output
--------------------------------------------------------------------------------
"

    #
    # Validate Command
    #
    if [ -z "$CMD" ]
    then
        write_test_log "ERROR : Empty Command"

        log_fail "$TEST_ID"

        write_test_log "

--------------------------------------------------------------------------------
Test Summary
--------------------------------------------------------------------------------

Result          : FAIL
Exit Status     : 1
Execution Time  : 0 sec
End Time        : $(date)

################################################################################
# TEST END : $TEST_ID
################################################################################
"

        return 1
    fi

    #
    # Execute Command
    #
    COMMAND_OUTPUT=$(eval "$CMD" 2>&1)
    COMMAND_STATUS=$?

    OUTPUT="$COMMAND_OUTPUT"
    STATUS="$COMMAND_STATUS"

    #
    # Print Command Output
    #
    write_test_log "$OUTPUT"

    #
    # Calculate Execution Time
    #
    END_TIME=$(date +%s)
    EXEC_TIME=$((END_TIME - START_TIME))

    #
    # Test Result
    #
    if [ "$STATUS" -eq 0 ]
    then
        RESULT="PASS"
        log_pass "$TEST_ID"
    else
        RESULT="FAIL"
        log_fail "$TEST_ID"
    fi

    #
    # Test Footer
    #
    write_test_log "

--------------------------------------------------------------------------------
Test Summary
--------------------------------------------------------------------------------

Result          : $RESULT
Exit Status     : $STATUS
Execution Time  : ${EXEC_TIME} sec
End Time        : $(date)

################################################################################
# TEST END : $TEST_ID
################################################################################

"

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
    local RESULT

    log_info "[$TEST_ID] $TEST_NAME"

    MANUAL_TEXT="
################################################################################
# MANUAL TEST
################################################################################

Test ID         : $TEST_ID
Test Name       : $TEST_NAME

Description
-----------
$DESCRIPTION

Expected Result
---------------
$EXPECTED

Press 'p' for PASS
Press 'f' for FAIL

################################################################################
"

    #
    # Display manual test instructions according to
    # TEST_LOG_OUTPUT_MODE (console/file/both)
    #
    write_test_log "$MANUAL_TEXT"

    while true
    do
        read -rp "Enter Result (p/f): " RESULT

        case "$RESULT" in

            p|P)

                log_pass "$TEST_ID"

                write_test_log "
--------------------------------------------------------------------------------
Manual Test Result
--------------------------------------------------------------------------------

Result          : PASS
Completion Time : $(date)

################################################################################
# TEST END : $TEST_ID
################################################################################

"

                return 0
                ;;

            f|F)

                log_fail "$TEST_ID"

                write_test_log "
--------------------------------------------------------------------------------
Manual Test Result
--------------------------------------------------------------------------------

Result          : FAIL
Completion Time : $(date)

################################################################################
# TEST END : $TEST_ID
################################################################################

"

                return 1
                ;;

            *)

                echo "Invalid input. Please enter p or f."
                ;;

        esac
    done
}
