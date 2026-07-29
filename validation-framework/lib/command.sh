#!/bin/bash
###############################################################################
# File        : command.sh
# Description : Command Execution Library
###############################################################################

###############################################################################
# Global Variables
###############################################################################

#
# Last Executed Command Information
#
COMMAND_OUTPUT=""
COMMAND_STATUS=0
COMMAND_EXEC_TIME=0

COMMAND_START_TIME=""
COMMAND_END_TIME=""

LAST_TEST_ID=""
LAST_TEST_NAME=""
LAST_COMMAND=""
LAST_MODULE=""

###############################################################################
# Escape CSV Field
###############################################################################

csv_escape()
{
    local DATA="$1"

    #
    # Remove Carriage Return
    #
    DATA="${DATA//$'\r'/}"

    #
    # Replace newline with separator
    #
    DATA="${DATA//$'\n'/ | }"

    #
    # Escape Quotes
    #
    DATA="${DATA//\"/\"\"}"

    printf "%s" "$DATA"
}

###############################################################################
# Validate Command Output
#
# Usage:
#   validate_output "Architecture"
#
###############################################################################

validate_output()
{
    local PATTERN="$1"

    echo "$COMMAND_OUTPUT" | grep -q "$PATTERN"
}


###############################################################################
# Create CSV Header
###############################################################################

csv_create_header()
{
    #
    # CSV Disabled
    #
    [ "$CSV_REPORT_ENABLE" -eq 0 ] && return

    printf '"Module","Test ID","Test Name","Command","Result","Exit Status","Execution Time(s)","Start Time","End Time","Output"\n' \
    > "$CSV_FILE"
}

###############################################################################
# Write CSV Entry
###############################################################################

csv_write()
{
    local RESULT="$1"

    #
    # CSV Disabled
    #
    [ "$CSV_REPORT_ENABLE" -eq 0 ] && return

    local MODULE
    local TESTID
    local TESTNAME
    local CMD
    local OUTPUT

    MODULE=$(csv_escape "$LAST_MODULE")
    TESTID=$(csv_escape "$LAST_TEST_ID")
    TESTNAME=$(csv_escape "$LAST_TEST_NAME")
    CMD=$(csv_escape "$LAST_COMMAND")
    OUTPUT=$(csv_escape "$COMMAND_OUTPUT")

    printf '"%s","%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
        "$MODULE" \
        "$TESTID" \
        "$TESTNAME" \
        "$CMD" \
        "$RESULT" \
        "$COMMAND_STATUS" \
        "$COMMAND_EXEC_TIME" \
        "$COMMAND_START_TIME" \
        "$COMMAND_END_TIME" \
        "$OUTPUT" \
        >> "$CSV_FILE"
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

    #
    # Save Test Information
    #
    LAST_TEST_ID="$TEST_ID"
    LAST_TEST_NAME="$TEST_NAME"
    LAST_COMMAND="$CMD"

    #
    # Derive Module Name from Test ID
    #
    LAST_MODULE="${TEST_ID%%-*}"

    #
    # Empty Command Check
    #
    if [ -z "$CMD" ]
    then
        COMMAND_OUTPUT="ERROR : Empty Command"
        COMMAND_STATUS=1

        return 1
    fi

    #
    # Capture Start Time
    #
    START_TIME=$(date +%s)
    COMMAND_START_TIME=$(date "+%Y-%m-%d %H:%M:%S")

    #
    # Print Test Header
    #
    write_test_log "
################################################################################
# TEST START
################################################################################

Test ID         : $TEST_ID
Test Name       : $TEST_NAME
Start Time      : $COMMAND_START_TIME
Command         : $CMD

--------------------------------------------------------------------------------
Command Output
--------------------------------------------------------------------------------
"

    #
    # Execute Command
    #
    COMMAND_OUTPUT=$(eval "$CMD" 2>&1)
    COMMAND_STATUS=$?

    #
    # Print Command Output
    #
    write_test_log "$COMMAND_OUTPUT"

    #
    # Capture End Time
    #
    END_TIME=$(date +%s)

    COMMAND_EXEC_TIME=$((END_TIME - START_TIME))
    COMMAND_END_TIME=$(date "+%Y-%m-%d %H:%M:%S")

    #
    # Return command execution status.
    #
    # NOTE:
    # PASS / FAIL is NOT decided here.
    # The calling module validates COMMAND_OUTPUT
    # and invokes test_pass() or test_fail().
    #
    return "$COMMAND_STATUS"
}

###############################################################################
# Test Pass
###############################################################################

test_pass()
{
    local TEST_ID="$1"

    #
    # Console/File PASS message
    #
    log_pass "$TEST_ID"

    #
    # Test Summary
    #
    write_test_log "
--------------------------------------------------------------------------------
Test Summary
--------------------------------------------------------------------------------

Result          : PASS
Exit Status     : $COMMAND_STATUS
Execution Time  : ${COMMAND_EXEC_TIME} sec
End Time        : $COMMAND_END_TIME

################################################################################
# TEST END : $TEST_ID
################################################################################
"

    #
    # Update CSV Report
    #
    csv_write "PASS"

    return 0
}

###############################################################################
# Test Fail
###############################################################################

test_fail()
{
    local TEST_ID="$1"

    #
    # Console/File FAIL message
    #
    log_fail "$TEST_ID"

    #
    # Test Summary
    #
    write_test_log "
--------------------------------------------------------------------------------
Test Summary
--------------------------------------------------------------------------------

Result          : FAIL
Exit Status     : $COMMAND_STATUS
Execution Time  : ${COMMAND_EXEC_TIME} sec
End Time        : $COMMAND_END_TIME

################################################################################
# TEST END : $TEST_ID
################################################################################
"

    #
    # Update CSV Report
    #
    csv_write "FAIL"

    return 1
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

    LAST_TEST_ID="$TEST_ID"
    LAST_TEST_NAME="$TEST_NAME"
    LAST_COMMAND="Manual Test"
    LAST_MODULE="${TEST_ID%%-*}"

    COMMAND_OUTPUT=""
    COMMAND_STATUS=0
    COMMAND_EXEC_TIME=0

    COMMAND_START_TIME=$(date "+%Y-%m-%d %H:%M:%S")

    log_info "[$TEST_ID] $TEST_NAME"

    echo
    echo "======================================================================="
    echo "MANUAL TEST REQUIRED"
    echo "======================================================================="
    echo
    echo "$DESCRIPTION"
    echo
    echo "Expected Result:"
    echo "    $EXPECTED"
    echo
    echo "Press 'p' for PASS"
    echo "Press 'f' for FAIL"
    echo "======================================================================="

    while true
    do
        read -rp "Enter Result (p/f): " RESULT

        case "$RESULT" in

            p|P)

                COMMAND_STATUS=0
                COMMAND_END_TIME=$(date "+%Y-%m-%d %H:%M:%S")

                test_pass "$TEST_ID"

                return 0
                ;;

            f|F)

                COMMAND_STATUS=1
                COMMAND_END_TIME=$(date "+%Y-%m-%d %H:%M:%S")

                test_fail "$TEST_ID"

                return 1
                ;;

            *)

                echo "Invalid input. Please enter p or f."
                ;;

        esac

    done
}
