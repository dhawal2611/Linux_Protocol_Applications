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

LAST_TEST_ID=""
LAST_TEST_NAME=""

###############################################################################
# Escape CSV Field
###############################################################################
csv_escape()
{
    local DATA="$1"

    #
    # Remove CR
    #
    DATA="${DATA//$'\r'/}"

    #
    # Replace newline with " | "
    #
    DATA="${DATA//$'\n'/ | }"

    #
    # Escape quotes
    #
    DATA="${DATA//\"/\"\"}"

    printf "%s" "$DATA"
}

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
    local START_TIME_STR
    local END_TIME_STR
    local RESULT
    local MODULE_NAME
    local CSV_OUTPUT

    START_TIME_STR=$(date "+%Y-%m-%d %H:%M:%S")
    START_TIME=$(date +%s)

    LAST_TEST_ID="$TEST_ID"
    LAST_TEST_NAME="$TEST_NAME"

    #
    # Test Information
    #
    log_info "[$TEST_ID] $TEST_NAME"

    write_test_log "
################################################################################
# TEST START
################################################################################

Test ID         : $TEST_ID
Test Name       : $TEST_NAME
Start Time      : $START_TIME_STR
Command         : $CMD

--------------------------------------------------------------------------------
Command Output
--------------------------------------------------------------------------------
"

    #
    # Empty Command Check
    #
    if [ -z "$CMD" ]
    then
        write_test_log "ERROR : Empty Command"

        COMMAND_OUTPUT=""
        COMMAND_STATUS=1

        log_fail "$TEST_ID"

        write_test_log "
--------------------------------------------------------------------------------
Test Summary
--------------------------------------------------------------------------------

Result          : FAIL
Exit Status     : 1
Execution Time  : 0 sec
End Time        : $(date "+%Y-%m-%d %H:%M:%S")

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

    #
    # Write Command Output
    #
    write_test_log "$COMMAND_OUTPUT"

    #
    # Execution Time
    #
    END_TIME=$(date +%s)
    END_TIME_STR=$(date "+%Y-%m-%d %H:%M:%S")

    EXEC_TIME=$((END_TIME - START_TIME))

    #
    # Test Result
    #
    if [ "$COMMAND_STATUS" -eq 0 ]
    then
        RESULT="PASS"
        log_pass "$TEST_ID"
    else
        RESULT="FAIL"
        log_fail "$TEST_ID"
    fi

    #
    # Test Summary
    #
    write_test_log "
--------------------------------------------------------------------------------
Test Summary
--------------------------------------------------------------------------------

Result          : $RESULT
Exit Status     : $COMMAND_STATUS
Execution Time  : ${EXEC_TIME} sec
End Time        : $END_TIME_STR

################################################################################
# TEST END : $TEST_ID
################################################################################
"

    #
    # CSV Report
    #
    if [ "$CSV_REPORT_ENABLE" -eq 1 ] && [ -n "$CSV_FILE" ]
    then
        MODULE_NAME="${TEST_ID%%-*}"
        MODULE_NAME=$(csv_escape "$MODULE_NAME")
	TEST_ID=$(csv_escape "$TEST_ID")
	TEST_NAME=$(csv_escape "$TEST_NAME")
	CMD=$(csv_escape "$CMD")
	RESULT=$(csv_escape "$RESULT")
	CSV_OUTPUT=$(csv_escape "$COMMAND_OUTPUT")

	printf '"%s","%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
	    "$MODULE_NAME" \
	    "$TEST_ID" \
	    "$TEST_NAME" \
	    "$CMD" \
	    "$RESULT" \
	    "$COMMAND_STATUS" \
	    "$EXEC_TIME" \
	    "$START_TIME_STR" \
	    "$END_TIME_STR" \
	    "$CSV_OUTPUT" \
	>> "$CSV_FILE"
    fi

    return "$COMMAND_STATUS"
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
    local START_TIME_STR
    local END_TIME_STR
    local MODULE_NAME

    START_TIME_STR=$(date "+%Y-%m-%d %H:%M:%S")

    LAST_TEST_ID="$TEST_ID"
    LAST_TEST_NAME="$TEST_NAME"

    log_info "[$TEST_ID] $TEST_NAME"

    write_test_log "
################################################################################
# MANUAL TEST
################################################################################

Test ID         : $TEST_ID
Test Name       : $TEST_NAME
Start Time      : $START_TIME_STR

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

    while true
    do
        read -rp "Enter Result (p/f): " RESULT

        case "$RESULT" in

            p|P)
                RESULT="PASS"
                COMMAND_STATUS=0
                COMMAND_OUTPUT="Manual Test : PASS"
                log_pass "$TEST_ID"
                break
                ;;

            f|F)
                RESULT="FAIL"
                COMMAND_STATUS=1
                COMMAND_OUTPUT="Manual Test : FAIL"
                log_fail "$TEST_ID"
                break
                ;;

            *)
                echo "Invalid input. Please enter p or f."
                ;;
        esac
    done

    END_TIME_STR=$(date "+%Y-%m-%d %H:%M:%S")

    write_test_log "
--------------------------------------------------------------------------------
Manual Test Result
--------------------------------------------------------------------------------

Result          : $RESULT
Completion Time : $END_TIME_STR

################################################################################
# TEST END : $TEST_ID
################################################################################
"

    if [ "$CSV_REPORT_ENABLE" -eq 1 ] && [ -n "$CSV_FILE" ]
    then
        MODULE_NAME="${TEST_ID%%-*}"
        MODULE_NAME=$(csv_escape "$MODULE_NAME")
	TEST_ID=$(csv_escape "$TEST_ID")
	TEST_NAME=$(csv_escape "$TEST_NAME")
	RESULT=$(csv_escape "$RESULT")
	COMMAND_OUTPUT=$(csv_escape "$COMMAND_OUTPUT")

	printf '"%s","%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
	"$MODULE_NAME" \
	"$TEST_ID" \
	"$TEST_NAME" \
	"Manual Test" \
	"$RESULT" \
	"$COMMAND_STATUS" \
	"0" \
	"$START_TIME_STR" \
	"$END_TIME_STR" \
	"$COMMAND_OUTPUT" \
	>> "$CSV_FILE"
    fi

    if [ "$COMMAND_STATUS" -eq 0 ]
    then
        return 0
    else
        return 1
    fi
}

