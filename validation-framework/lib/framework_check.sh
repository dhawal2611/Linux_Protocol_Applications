#!/bin/bash
###############################################################################
#
# File        : framework_check.sh
#
# Description :
#     Embedded Linux Validation Framework Self Verification
#
# Responsibilities
#     • Verify Framework Environment
#     • Verify Directory Structure
#     • Verify Required Files
#     • Verify Required Linux Commands
#     • Verify Bash Version
#     • Verify File Permissions
#
###############################################################################

###############################################################################
# Framework Information
###############################################################################

FRAMEWORK_NAME="Embedded Linux Validation Framework"

FRAMEWORK_VERSION="1.0.0"

FRAMEWORK_AUTHOR="Dhawal Lad"

FRAMEWORK_RELEASE_DATE="2026-07-29"

MIN_BASH_VERSION=4

###############################################################################
# Framework Status
###############################################################################

FRAMEWORK_STATUS="READY"

FRAMEWORK_WARNING_COUNT=0

FRAMEWORK_ERROR_COUNT=0

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    awk
    basename
    cat
    cut
    date
    dirname
    find
    grep
    mkdir
    printf
    pwd
    realpath
    sed
    sort
    timeout
    touch
    tr
    uniq
)

###############################################################################
# Required Directories
###############################################################################

REQUIRED_DIRECTORIES=(
    "$LIB_DIR"
    "$MODULE_DIR"
    "$SUITE_DIR"
    "$LOG_DIR"
    "$CSV_DIR"
)

###############################################################################
# Required Library Files
###############################################################################

REQUIRED_FILES=(
    "$LIB_DIR/common.sh"
    "$LIB_DIR/logger.sh"
    "$LIB_DIR/assertions.sh"
    "$LIB_DIR/command.sh"
    "$LIB_DIR/arguments.sh"
    "$LIB_DIR/test_registry.sh"
)

###############################################################################
# Framework PASS
###############################################################################

framework_pass()
{
    printf "[PASS] %-45s\n" "$1"
}

###############################################################################
# Framework WARNING
###############################################################################

framework_warning()
{
    printf "[WARN] %-45s\n" "$1"

    FRAMEWORK_WARNING_COUNT=$((FRAMEWORK_WARNING_COUNT + 1))
}

###############################################################################
# Framework ERROR
###############################################################################

framework_error()
{
    printf "[FAIL] %-45s\n" "$1"

    FRAMEWORK_ERROR_COUNT=$((FRAMEWORK_ERROR_COUNT + 1))

    FRAMEWORK_STATUS="FAILED"
}

###############################################################################
# Framework Banner
###############################################################################

framework_banner()
{
    echo

    echo "======================================================================"
    echo "           $FRAMEWORK_NAME"
    echo "======================================================================"

    printf "%-20s : %s\n" "Version" "$FRAMEWORK_VERSION"
    printf "%-20s : %s\n" "Author" "$FRAMEWORK_AUTHOR"
    printf "%-20s : %s\n" "Release Date" "$FRAMEWORK_RELEASE_DATE"

    echo "======================================================================"

    echo
}

###############################################################################
# Verify Bash Version
###############################################################################

check_bash_version()
{
    local VERSION

    VERSION="${BASH_VERSINFO[0]}"

    if [ "$VERSION" -lt "$MIN_BASH_VERSION" ]
    then

        framework_fatal \
            "Bash Version >= ${MIN_BASH_VERSION} Required"

        echo

        echo "Detected Bash Version : $VERSION"

        exit 1

    fi

    framework_pass \
        "Bash Version ($VERSION)"
}

###############################################################################
# Verify Required Directories
###############################################################################

check_required_directories()
{
    local DIR

    for DIR in "${REQUIRED_DIRECTORIES[@]}"
    do

        if [ ! -d "$DIR" ]
        then

            mkdir -p "$DIR"

            if [ $? -ne 0 ]
            then
                framework_fatal \
                    "Create Directory : $DIR"
            fi

        fi

        framework_pass \
            "Directory : $(basename "$DIR")"

    done
}

###############################################################################
# Verify Required Files
###############################################################################

check_required_files()
{
    local FILE

    for FILE in "${REQUIRED_FILES[@]}"
    do

        if [ ! -f "$FILE" ]
        then
            framework_fatal \
                "Missing File : $(basename "$FILE")"
        fi

        framework_pass \
            "Library : $(basename "$FILE")"

    done
}

###############################################################################
# Verify Required Linux Commands
###############################################################################

check_required_commands()
{
    local COMMAND

    for COMMAND in "${REQUIRED_COMMANDS[@]}"
    do

        if ! command -v "$COMMAND" >/dev/null 2>&1
        then
            framework_fatal \
                "Command : $COMMAND"
        fi

        framework_pass \
            "Command : $COMMAND"

    done
}

###############################################################################
# Verify Directory Permissions
###############################################################################

check_directory_permissions()
{
    local DIR

    for DIR in "${REQUIRED_DIRECTORIES[@]}"
    do

        if [ ! -w "$DIR" ]
        then
            framework_fatal \
                "Directory Writable : $(basename "$DIR")"
        fi

        framework_pass \
            "Directory Writable : $(basename "$DIR")"

    done
}

###############################################################################
# Framework Fatal
###############################################################################

framework_fatal()
{
    framework_error "$1"
    echo
    echo "Framework initialization failed."
    exit 1
}

###############################################################################
# Verify Configuration
###############################################################################

check_configuration()
{
    #
    # Framework Directories
    #

    validate_required "ROOT_DIR" "$ROOT_DIR" || framework_fatal "ROOT_DIR not configured."

    validate_required "LIB_DIR" "$LIB_DIR" || framework_fatal "LIB_DIR not configured."

    validate_required "MODULE_DIR" "$MODULE_DIR" || framework_fatal "MODULE_DIR not configured."

    validate_required "SUITE_DIR" "$SUITE_DIR" || framework_fatal "SUITE_DIR not configured."

    validate_required "LOG_DIR" "$LOG_DIR" || framework_fatal "LOG_DIR not configured."

    validate_required "CSV_DIR" "$CSV_DIR" || framework_fatal "CSV_DIR not configured."

    framework_pass "Framework Configuration"
}

###############################################################################
# Verify Logger Configuration
###############################################################################

check_logger_configuration()
{
    case "$LOGGER_OUTPUT_MODE" in

        console|file|both)
            framework_pass "Logger Configuration"
            ;;

        *)
            framework_fatal \
                "Invalid LOGGER_OUTPUT_MODE : $LOGGER_OUTPUT_MODE"
            ;;

    esac

    #
    # Log file validation
    #

    if [ "$LOGGER_OUTPUT_MODE" != "console" ]
    then

        if [ "$LOG_ENABLE" != "yes" ]
        then
            framework_warning "Log File Disabled"
        else
            framework_pass "Log File Enabled"
        fi

    fi
}

###############################################################################
# Verify CSV Configuration
###############################################################################

check_csv_configuration()
{
    if [ "$CSV_ENABLE" = "yes" ]
    then

        framework_pass "CSV Logging Enabled"

    else

        framework_warning "CSV Logging Disabled"

    fi
}

###############################################################################
# Verify Module Directory
###############################################################################

check_module_directory()
{
    local COUNT

    COUNT=$(find "$MODULE_DIR" -maxdepth 1 -name "*.sh" | wc -l)

    if [ "$COUNT" -eq 0 ]
    then

        framework_warning "No Modules Found"

        return

    fi

    framework_pass "Modules Found ($COUNT)"
}

###############################################################################
# Verify Suite Directory
###############################################################################

check_suite_directory()
{
    local COUNT

    COUNT=$(find "$SUITE_DIR" -maxdepth 1 -name "*.sh" | wc -l)

    if [ "$COUNT" -eq 0 ]
    then

        framework_warning "No Suites Found"

        return

    fi

    framework_pass "Suites Found ($COUNT)"
}

###############################################################################
# Framework Summary
###############################################################################

framework_summary()
{
    echo

    echo "======================================================================"
    echo "Framework Summary"
    echo "======================================================================"

    printf "%-20s : %s\n" "Status" "$FRAMEWORK_STATUS"
    printf "%-20s : %d\n" "Warnings" "$FRAMEWORK_WARNING_COUNT"
    printf "%-20s : %d\n" "Errors" "$FRAMEWORK_ERROR_COUNT"

    echo "======================================================================"

    echo
}

###############################################################################
# Framework Self Check
###############################################################################

framework_self_check()
{
    framework_banner

    check_bash_version

    check_required_directories

    check_required_files

    check_required_commands

    check_directory_permissions

    check_configuration

    check_logger_configuration

    check_csv_configuration

    check_module_directory

    check_suite_directory

    framework_summary

    if [ "$FRAMEWORK_ERROR_COUNT" -gt 0 ]
    then

        framework_fatal "Framework Initialization Failed"

    fi
}

###############################################################################
# Framework Fatal Error
###############################################################################

framework_fatal()
{
    framework_error "$1"

    echo

    echo "======================================================================"
    echo "Framework initialization failed."
    echo "Please fix the above error(s) and try again."
    echo "======================================================================"

    exit 1
}

###############################################################################
# End Of File
###############################################################################
