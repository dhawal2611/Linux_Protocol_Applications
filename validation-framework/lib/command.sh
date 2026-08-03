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
# Test Result Variables
###############################################################################

TEST_RESULT=""
TEST_MESSAGE=""

###############################################################################
# Framework Variables
###############################################################################

#
# Current Test Information
#
TEST_ID=""
TEST_NAME=""

#
# Validation Result
#
TEST_RESULT=""
TEST_MESSAGE=""

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
    #
    # Initialize Test Variables
    #
    TEST_ID="$1"
    TEST_NAME="$2"

    local CMD="$3"

    echo "--------------###############################################################################"
    echo $TEST_ID $TEST_NAME $CMD
    echo "--------------###############################################################################"

    local START_TIME
    local END_TIME

    #
    # Reset Previous Test Data
    #
    COMMAND_OUTPUT=""
    COMMAND_STATUS=0
    COMMAND_EXEC_TIME=0
    COMMAND_START_TIME=""
    COMMAND_END_TIME=""

    TEST_RESULT=""
    TEST_MESSAGE=""

    #
    # Save Current Test Information
    #
    LAST_TEST_ID="$TEST_ID"
    LAST_TEST_NAME="$TEST_NAME"
    LAST_COMMAND="$CMD"

    #
    # Derive Module Name
    #
    LAST_MODULE="${TEST_ID%%-*}"

    #
    # Validate Command
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
    COMMAND_START_TIME=$(get_timestamp)

    #
    # Test Header
    #
    write_test_header

    #
    # Execute Command
    #
    COMMAND_OUTPUT="$(
        eval "$CMD" 2>&1
    )"
    COMMAND_STATUS=$?

    #
    # Save Command Output
    #
    write_command_output

    #
    # Capture End Time
    #
    END_TIME=$(date +%s)

    COMMAND_EXEC_TIME=$((END_TIME - START_TIME))
    COMMAND_END_TIME=$(get_timestamp)

    #
    # Test Footer
    #
    #write_test_footer

    #
    # Return Command Status
    #
    # NOTE:
    # This function ONLY executes the command.
    # PASS / FAIL is decided by the calling module after validating
    # COMMAND_OUTPUT and/or COMMAND_STATUS.
    #
    return "$COMMAND_STATUS"
}

###############################################################################
# Test Pass
###############################################################################

test_pass()
{
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
# Test Skip
###############################################################################

test_skip()
{
    TEST_RESULT="SKIPPED"
    log_skip "$TEST_ID"

    write_test_log "
--------------------------------------------------------------------------------
Test Summary
--------------------------------------------------------------------------------

Result          : SKIPPED
Reason          : ${TEST_MESSAGE}
Exit Status     : -
Execution Time  : ${COMMAND_EXEC_TIME} sec
End Time        : ${COMMAND_END_TIME}

################################################################################
# TEST END : ${TEST_ID}
################################################################################
"

    log_warn "${TEST_ID}"

    csv_write "SKIPPED"

    return 0
}


###############################################################################
# Manual Test
###############################################################################

manual_test()
{
    #
    # Initialize Test Variables
    #
    TEST_ID="$1"
    TEST_NAME="$2"

    local DESCRIPTION="$3"
    local EXPECTED="$4"

    TEST_RESULT=""
    TEST_MESSAGE=""

    COMMAND_OUTPUT="Manual Test"
    COMMAND_STATUS=0
    COMMAND_EXEC_TIME=0

    LAST_TEST_ID="$TEST_ID"
    LAST_TEST_NAME="$TEST_NAME"
    LAST_COMMAND="Manual Test"
    LAST_MODULE="${TEST_ID%%-*}"

    COMMAND_START_TIME=$(get_timestamp)

    #
    # Test Header
    #
    COMMAND_START_TIME=$(get_timestamp)

    LAST_COMMAND="Manual Test"

    write_test_header

    write_test_log "Description"
    write_test_log "--------------------------------------------------------------------------------"
    write_test_log "$DESCRIPTION"

    write_test_log ""

    write_test_log "Expected Result"
    write_test_log "--------------------------------------------------------------------------------"
    write_test_log "$EXPECTED"

    write_test_log ""

    #
    # Console Prompt
    #
    banner "MANUAL TEST REQUIRED"

    echo
    echo "$DESCRIPTION"
    echo
    echo "Expected Result:"
    echo "    $EXPECTED"
    echo
    echo "Press 'p' for PASS"
    echo "Press 'f' for FAIL"
    separator

    while true
    do
        read -rp "Enter Result (p/f): " RESULT

        case "$RESULT" in

            p|P)

                COMMAND_STATUS=0
                COMMAND_END_TIME=$(get_timestamp)

                TEST_RESULT="PASS"
                TEST_MESSAGE="Manual verification passed."

                finalize_test

                return 0
                ;;

            f|F)

                COMMAND_STATUS=1
                COMMAND_END_TIME=$(get_timestamp)

                TEST_RESULT="FAIL"
                TEST_MESSAGE="Manual verification failed."

                finalize_test

                return 1
                ;;

            *)

                echo "Invalid input. Please enter p or f."
                ;;

        esac

    done
}

###############################################################################
# Finalize Test
###############################################################################

finalize_test()
{
    #
    # Default Result
    #
    [ -z "$TEST_RESULT" ] && TEST_RESULT="FAIL"

    [ -z "$TEST_MESSAGE" ] && TEST_MESSAGE="-"

    COMMAND_END_TIME=$(get_timestamp)

    #
    # Validation Result
    #
    write_validation_result

    #
    # Footer
    #
    write_test_footer

    #
    # PASS / FAIL
    #
    if [ "$TEST_RESULT" = "PASS" ]
    then
        log_pass "$TEST_ID"
    else
        log_fail "$TEST_ID"
    fi

    #
    # CSV
    #
    csv_write "$TEST_RESULT"

    #
    # Reset Variables
    #
    TEST_RESULT=""
    TEST_MESSAGE=""
}
