#!/bin/bash
###############################################################################
#
# File        : test_registry.sh
#
# Description :
#   Test Registration Framework
#
# Features :
#   - Test Registration
#   - Metadata Management
#   - Validation
#   - Duplicate Detection
#   - Registry Management
#
###############################################################################

###############################################################################
# Framework Information
###############################################################################

TEST_REGISTRY_VERSION="1.0.0"

#
# Internal field separator.
#
# Using ASCII Unit Separator avoids parsing issues if descriptions contain
# commas, pipes or spaces.
#
FIELD_SEPARATOR=$'\x1F'

###############################################################################
# Registered Tests
###############################################################################

REGISTERED_TESTS=()

###############################################################################
# Parsed Test Record Variables
###############################################################################

REG_TEST_ID=""
REG_TEST_FUNCTION=""
REG_TEST_NAME=""
REG_TEST_CATEGORY=""
REG_TEST_TYPE=""
REG_TEST_PRIORITY=""
REG_TEST_TIMEOUT=0
REG_TEST_TAGS=""
REG_TEST_OWNER=""
REG_TEST_BOARD=""
REG_TEST_ENABLED=""
REG_TEST_DESCRIPTION=""
REG_TEST_DEPENDENCY=""

###############################################################################
# Supported Values
###############################################################################

SUPPORTED_TEST_TYPES=(
    auto
    manual
)

SUPPORTED_PRIORITIES=(
    high
    medium
    low
)

SUPPORTED_CATEGORIES=(
    basic
    interface
    network
    storage
    security
    performance
    stress
    power
    system
    diagnostic
    hardware
)

SUPPORTED_ENABLED_VALUES=(
    yes
    no
)

###############################################################################
# Clear Test Registry
###############################################################################

clear_test_registry()
{
    REGISTERED_TESTS=()
}

###############################################################################
# Validate Required Field
###############################################################################

validate_required()
{
    local FIELD="$1"
    local VALUE="$2"

    if [ -z "$VALUE" ]
    then
        echo "ERROR : register_test() : Missing required field '$FIELD'"
        return 1
    fi

    return 0
}

###############################################################################
# Validate Integer
###############################################################################

validate_integer()
{
    local FIELD="$1"
    local VALUE="$2"

    case "$VALUE" in

        ''|*[!0-9]*)

            echo "ERROR : register_test() : '$FIELD' must be integer."

            return 1
            ;;

    esac

    return 0
}

###############################################################################
# Validate Enum
###############################################################################

validate_enum()
{
    local FIELD="$1"
    local VALUE="$2"

    shift 2

    local ITEM

    for ITEM in "$@"
    do

        if [ "$ITEM" = "$VALUE" ]
        then
            return 0
        fi

    done

    echo "ERROR : register_test() : Invalid value '$VALUE' for '$FIELD'."

    echo "Supported Values : $*"

    return 1
}

###############################################################################
# Parse Test Record
###############################################################################

parse_test_record()
{
    local RECORD="$1"

    IFS="$FIELD_SEPARATOR" read \
        REG_TEST_ID \
        REG_TEST_FUNCTION \
        REG_TEST_NAME \
        REG_TEST_CATEGORY \
        REG_TEST_TYPE \
        REG_TEST_PRIORITY \
        REG_TEST_TIMEOUT \
        REG_TEST_TAGS \
        REG_TEST_OWNER \
        REG_TEST_BOARD \
        REG_TEST_ENABLED \
        REG_TEST_DESCRIPTION \
        REG_TEST_DEPENDENCY \
        <<< "$RECORD"
}

###############################################################################
# Validate Duplicate Test ID
###############################################################################

validate_unique_test_id()
{
    local RECORD

    for RECORD in "${REGISTERED_TESTS[@]}"
    do

        parse_test_record "$RECORD"

        if [ "$REG_TEST_ID" = "$1" ]
        then

            echo "ERROR : Duplicate Test ID : $1"

            return 1

        fi

    done

    return 0
}

###############################################################################
# Validate Function Exists
###############################################################################

validate_function()
{
    local FUNCTION="$1"

    if ! declare -F "$FUNCTION" >/dev/null
    then

        echo "ERROR : Function '$FUNCTION' not found."

        return 1

    fi

    return 0
}

###############################################################################
# Register Test
#
# Example:
#
# register_test \
#     --id          "CPU-001" \
#     --function    cpu_001 \
#     --name        "Verify CPU Architecture" \
#     --category    basic \
#     --type        auto \
#     --priority    high \
#     --timeout     30 \
#     --tags        "cpu,lscpu" \
#     --owner       "Embedded Team" \
#     --board       "RPi4,IMX6ULL" \
#     --enabled     yes \
#     --description "Verify CPU architecture." \
#     --depends     ""
#
###############################################################################

register_test()
{
    local ID=""
    local FUNCTION=""
    local NAME=""
    local CATEGORY=""
    local TYPE="auto"
    local PRIORITY="medium"
    local TIMEOUT=0
    local TAGS=""
    local OWNER=""
    local BOARD=""
    local ENABLED="yes"
    local DESCRIPTION=""
    local DEPENDENCY=""

    while [ $# -gt 0 ]
    do

        case "$1" in

            --id|-i)

                ID="$2"

                shift 2

                ;;

            --function|-f)

                FUNCTION="$2"

                shift 2

                ;;

            --name|-n)

                NAME="$2"

                shift 2

                ;;

            --category|-c)

                CATEGORY="$2"

                shift 2

                ;;

            --type|-t)

                TYPE="$2"

                shift 2

                ;;

            --priority|-p)

                PRIORITY="$2"

                shift 2

                ;;

            --timeout|-o)

                TIMEOUT="$2"

                shift 2

                ;;

            --tags|-g)

                TAGS="$2"

                shift 2

                ;;

            --owner|-w)

                OWNER="$2"

                shift 2

                ;;

            --board|-b)

                BOARD="$2"

                shift 2

                ;;

            --enabled|-e)

                ENABLED="$2"

                shift 2

                ;;

            --description|-d)

                DESCRIPTION="$2"

                shift 2

                ;;

            --depends|-r)

                DEPENDENCY="$2"

                shift 2

                ;;

            *)

                echo "ERROR : Unknown register_test option '$1'"

                return 1

                ;;

        esac

    done

    echo "***************************************************************************************************"
    echo $ID $FUNCTION $NAME $CATEGORY $TYPE $PRIORITY $TIMEOUT $TAGS $OWNER $BOARD $ENABLED $DESCRIPTION $DEPENDENCY
    echo "***************************************************************************************************"

    #
    # Mandatory Validation
    #

    validate_required "id" "$ID" || return 1

    validate_required "function" "$FUNCTION" || return 1

    validate_required "name" "$NAME" || return 1

    validate_required "category" "$CATEGORY" || return 1

    #
    # Enumeration Validation
    #

    validate_enum \
        "category" \
        "$CATEGORY" \
        "${SUPPORTED_CATEGORIES[@]}" \
        || return 1

    validate_enum \
        "type" \
        "$TYPE" \
        "${SUPPORTED_TEST_TYPES[@]}" \
        || return 1

    validate_enum \
        "priority" \
        "$PRIORITY" \
        "${SUPPORTED_PRIORITIES[@]}" \
        || return 1

    validate_enum \
        "enabled" \
        "$ENABLED" \
        "${SUPPORTED_ENABLED_VALUES[@]}" \
        || return 1

    #
    # Timeout Validation
    #

    validate_integer \
        "timeout" \
        "$TIMEOUT" \
        || return 1

    #
    # Duplicate Test ID
    #

    validate_unique_test_id \
        "$ID" \
        || return 1

    #
    # Function Validation
    #

    validate_function \
        "$FUNCTION" \
        || return 1

    #
    # Register Test
    #

    REGISTERED_TESTS+=(
"${ID}${FIELD_SEPARATOR}${FUNCTION}${FIELD_SEPARATOR}${NAME}${FIELD_SEPARATOR}${CATEGORY}${FIELD_SEPARATOR}${TYPE}${FIELD_SEPARATOR}${PRIORITY}${FIELD_SEPARATOR}${TIMEOUT}${FIELD_SEPARATOR}${TAGS}${FIELD_SEPARATOR}${OWNER}${FIELD_SEPARATOR}${BOARD}${FIELD_SEPARATOR}${ENABLED}${FIELD_SEPARATOR}${DESCRIPTION}${FIELD_SEPARATOR}${DEPENDENCY}"
    )

    return 0
}

###############################################################################
# Execute Registered Tests
###############################################################################

run_registered_tests()
{
    local RECORD

    banner "Starting ${MODULE_NAME} Validation"

    for RECORD in "${REGISTERED_TESTS[@]}"
    do

        parse_test_record "$RECORD"

        #
        # Skip Disabled Tests
        #

        [ "$REG_TEST_ENABLED" != "yes" ] && continue

        #
        # Category Filter
        #

        if [ -n "$FILTER_CATEGORY" ]
        then
            [ "$REG_TEST_CATEGORY" != "$FILTER_CATEGORY" ] && continue
        fi

        #
        # Type Filter
        #

        if [ -n "$FILTER_TYPE" ]
        then
            [ "$REG_TEST_TYPE" != "$FILTER_TYPE" ] && continue
        fi

        #
        # Priority Filter
        #

        if [ -n "$FILTER_PRIORITY" ]
        then
            [ "$REG_TEST_PRIORITY" != "$FILTER_PRIORITY" ] && continue
        fi

        #
        # Test ID Filter
        #

        if [ -n "$FILTER_TEST_ID" ]
        then
            [ "$REG_TEST_ID" != "$FILTER_TEST_ID" ] && continue
        fi

        #
        # Board Filter
        #

        if [ -n "$TARGET_BOARD" ]
        then
            echo "$REG_TEST_BOARD" | grep -qw "$TARGET_BOARD" || continue
        fi

        #
        # Make timeout available globally.
        #

        CURRENT_TEST_TIMEOUT="$REG_TEST_TIMEOUT"

        #
        # Execute Test
        #

        "${REG_TEST_FUNCTION}"

    done

    banner "${MODULE_NAME} Validation Completed"
}

###############################################################################
# Find Test
###############################################################################

find_registered_test()
{
    local SEARCH_ID="$1"
    local RECORD

    for RECORD in "${REGISTERED_TESTS[@]}"
    do

        parse_test_record "$RECORD"

        if [ "$REG_TEST_ID" = "$SEARCH_ID" ]
        then
            return 0
        fi

    done

    return 1
}

###############################################################################
# Print Test Information
###############################################################################

print_registered_test()
{
    printf "\n"

    printf "Test ID          : %s\n" "$REG_TEST_ID"
    printf "Function         : %s\n" "$REG_TEST_FUNCTION"
    printf "Name             : %s\n" "$REG_TEST_NAME"
    printf "Category         : %s\n" "$REG_TEST_CATEGORY"
    printf "Type             : %s\n" "$REG_TEST_TYPE"
    printf "Priority         : %s\n" "$REG_TEST_PRIORITY"
    printf "Timeout          : %s sec\n" "$REG_TEST_TIMEOUT"
    printf "Tags             : %s\n" "$REG_TEST_TAGS"
    printf "Owner            : %s\n" "$REG_TEST_OWNER"
    printf "Board            : %s\n" "$REG_TEST_BOARD"
    printf "Enabled          : %s\n" "$REG_TEST_ENABLED"
    printf "Dependency       : %s\n" "$REG_TEST_DEPENDENCY"

    printf "\nDescription\n"
    printf "-----------\n"
    printf "%s\n" "$REG_TEST_DESCRIPTION"

    printf "\n"
}

###############################################################################
# List Registered Tests
###############################################################################

list_registered_tests()
{
    local RECORD

    printf "\n"

    printf "%-10s %-35s %-12s %-8s %-8s %-8s\n" \
        "ID" \
        "NAME" \
        "CATEGORY" \
        "TYPE" \
        "PRIORITY" \
        "ENABLE"

    separator

    for RECORD in "${REGISTERED_TESTS[@]}"
    do

        parse_test_record "$RECORD"

        printf "%-10s %-35s %-12s %-8s %-8s %-8s\n" \
            "$REG_TEST_ID" \
            "$REG_TEST_NAME" \
            "$REG_TEST_CATEGORY" \
            "$REG_TEST_TYPE" \
            "$REG_TEST_PRIORITY" \
            "$REG_TEST_ENABLED"

    done

    printf "\n"
}

###############################################################################
# Get Test Count
###############################################################################

get_registered_test_count()
{
    echo "${#REGISTERED_TESTS[@]}"
}

###############################################################################
# Show Registry Information
###############################################################################

show_test_registry_info()
{
    echo "=============================================================="
    echo "Test Registry Information"
    echo "=============================================================="

    echo "Registry Version : $TEST_REGISTRY_VERSION"
    echo "Registered Tests : $(get_registered_test_count)"

    echo
}

###############################################################################
# End Of File
###############################################################################
