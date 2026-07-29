#!/bin/bash
###############################################################################
# File        : assertions.sh
# Description : Assertions Library
###############################################################################

###############################################################################
# Assert Command Success
###############################################################################

assert_command_success()
{
    local PASS_MSG="$1"
    local FAIL_MSG="$2"

    if [ "$COMMAND_STATUS" -eq 0 ]
    then
        TEST_RESULT="PASS"
        TEST_MESSAGE="$PASS_MSG"
    else
        TEST_RESULT="FAIL"
        TEST_MESSAGE="$FAIL_MSG"
    fi
}

###############################################################################
# Assert Output Contains String
###############################################################################

assert_contains()
{
    local OUTPUT="$1"
    local SEARCH="$2"
    local PASS_MSG="$3"
    local FAIL_MSG="$4"

    if echo "$OUTPUT" | grep -q "$SEARCH"
    then
        TEST_RESULT="PASS"
        TEST_MESSAGE="$PASS_MSG"
    else
        TEST_RESULT="FAIL"
        TEST_MESSAGE="$FAIL_MSG"
    fi
}

###############################################################################
# Assert Output Does Not Contain String
###############################################################################

assert_not_contains()
{
    local OUTPUT="$1"
    local SEARCH="$2"
    local PASS_MSG="$3"
    local FAIL_MSG="$4"

    if echo "$OUTPUT" | grep -q "$SEARCH"
    then
        TEST_RESULT="FAIL"
        TEST_MESSAGE="$FAIL_MSG"
    else
        TEST_RESULT="PASS"
        TEST_MESSAGE="$PASS_MSG"
    fi
}

###############################################################################
# Assert Regular Expression
###############################################################################

assert_regex()
{
    local OUTPUT="$1"
    local REGEX="$2"
    local PASS_MSG="$3"
    local FAIL_MSG="$4"

    if echo "$OUTPUT" | grep -Eq "$REGEX"
    then
        TEST_RESULT="PASS"
        TEST_MESSAGE="$PASS_MSG"
    else
        TEST_RESULT="FAIL"
        TEST_MESSAGE="$FAIL_MSG"
    fi
}

###############################################################################
# Assert Equal
###############################################################################

assert_equal()
{
    local ACTUAL="$1"
    local EXPECTED="$2"
    local PASS_MSG="$3"
    local FAIL_MSG="$4"

    if [ "$ACTUAL" = "$EXPECTED" ]
    then
        TEST_RESULT="PASS"
        TEST_MESSAGE="$PASS_MSG"
    else
        TEST_RESULT="FAIL"
        TEST_MESSAGE="$FAIL_MSG"
    fi
}

###############################################################################
# Assert Not Empty
###############################################################################

assert_not_empty()
{
    local VALUE="$1"
    local PASS_MSG="$2"
    local FAIL_MSG="$3"

    if [ -n "$VALUE" ]
    then
        TEST_RESULT="PASS"
        TEST_MESSAGE="$PASS_MSG"
    else
        TEST_RESULT="FAIL"
        TEST_MESSAGE="$FAIL_MSG"
    fi
}

###############################################################################
# Assert File Exists
###############################################################################

assert_file_exists()
{
    local FILE="$1"
    local PASS_MSG="$2"
    local FAIL_MSG="$3"

    if [ -f "$FILE" ]
    then
        TEST_RESULT="PASS"
        TEST_MESSAGE="$PASS_MSG"
    else
        TEST_RESULT="FAIL"
        TEST_MESSAGE="$FAIL_MSG"
    fi
}

###############################################################################
# Assert Directory Exists
###############################################################################

assert_directory_exists()
{
    local DIR="$1"
    local PASS_MSG="$2"
    local FAIL_MSG="$3"

    if [ -d "$DIR" ]
    then
        TEST_RESULT="PASS"
        TEST_MESSAGE="$PASS_MSG"
    else
        TEST_RESULT="FAIL"
        TEST_MESSAGE="$FAIL_MSG"
    fi
}

###############################################################################
# Assert Network Interface UP
###############################################################################

assert_interface_up()
{
    local IFACE="$1"

    if ip link show "$IFACE" | grep -q "state UP"
    then
        TEST_RESULT="PASS"
        TEST_MESSAGE="$IFACE is UP."
    else
        TEST_RESULT="FAIL"
        TEST_MESSAGE="$IFACE is DOWN."
    fi
}


