#!/bin/bash
###############################################################################
# File        : validate.sh
# Description : Embedded Linux Validation Framework
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/config.sh"

source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/arguments.sh"
source "$SCRIPT_DIR/lib/command.sh"
source "$SCRIPT_DIR/lib/assertions.sh"
source "$SCRIPT_DIR/lib/test_registry.sh"
source "$SCRIPT_DIR/lib/framework_check.sh"

LOOP_MODE=0

###############################################################################
# Framework Self Check
###############################################################################

framework_self_check

###############################################################################
# Parse command-line arguments
###############################################################################
parse_arguments "$@"

###############################################################################
# Initialize Framework
###############################################################################

initialize_framework

# Handle Ctrl+C
#trap cleanup SIGINT

###############################################################################
# Generate Log File Name
###############################################################################

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

#
# Use first selected module/suite in log file name
#
LOG_TARGET="${MODULE_LIST[0]}"

#
# If multiple modules are selected, use "multi"
#
if [ "${#MODULE_LIST[@]}" -gt 1 ]
then
    LOG_TARGET="multi"
fi

###############################################################################
# Create Log File
###############################################################################
#if [ "$LOG_FILE_ENABLE" -eq 1 ]
#then
#    LOG_FILE="${LOG_DIR}/validation_${TIMESTAMP}_${LOG_TARGET}.log"
#
#    touch "$LOG_FILE"
#fi

###############################################################################
# Create CSV Report
###############################################################################
if [ "$CSV_REPORT_ENABLE" -eq 1 ]
then

    if [ -z "$CSV_FILE" ]
    then
        CSV_FILE="${LOG_DIR}/validation_${TIMESTAMP}_${LOG_TARGET}.csv"
    fi

    #echo "\"Module\",\"Test ID\",\"Test Name\",\"Command\",\"Result\",\"Exit Status\",\"Execution Time(s)\",\"Start Time\",\"End Time\",\"Output\"" > "$CSV_FILE"
    #printf '"Module","Test ID","Test Name","Command","Result","Exit Status","Execution Time(s)","Start Time","End Time","Output"\n' \> "$CSV_FILE"
    csv_create_header

fi

###############################################################################
# Execute a Single Module
###############################################################################

run_single_module()
{
    local MODULE="$1"

    if [ ! -f "$SCRIPT_DIR/modules/${MODULE}.sh" ]
    then
        log_error "Module '${MODULE}' not found."
        return 1
    fi

    log_info ""
    log_info "Running Module : ${MODULE}"

    #
    # Clear Previous Module Variables
    #
    unset REQUIRED_COMMANDS

    #
    # Load Module
    #
    clear_test_registry
    #source "$SCRIPT_DIR/modules/${MODULE}.sh"
    if ! source "$SCRIPT_DIR/modules/${MODULE}.sh"
    then
        log_error "Failed to load module ${MODULE}"
        return 1
    fi

    #
    # Verify Module Dependencies
    #
    if declare -p REQUIRED_COMMANDS >/dev/null 2>&1
    then
        check_dependencies "${REQUIRED_COMMANDS[@]}"
        if [ $? -ne 0 ]
        then
            log_error "Skipping Module : ${MODULE}"
            return 1
        fi
    fi

    #
    # Execute Module
    #
    run_registered_tests

}

###############################################################################
# Execute Selected Modules
###############################################################################

run_modules()
{
    local MODULE

    for MODULE in "${MODULE_LIST[@]}"
    do
        run_single_module "$MODULE"
    done
}

###############################################################################
# Execute Single Suite
###############################################################################

run_single_suite()
{
    local SUITE="$1"

    #
    # Verify Suite Exists
    #
    if [ ! -f "$SCRIPT_DIR/suites/${SUITE}.sh" ]
    then
        log_error "Suite '${SUITE}' not found."
        return 1
    fi

    ###########################################################################
    # Suite Start
    ###########################################################################

    log_info ""
    log_info "============================================================"
    log_info "Starting Suite : ${SUITE}"
    log_info "============================================================"

    #
    # Clear Module List
    #
    MODULE_LIST=()

    #
    # Load Suite
    #
    #source "$SCRIPT_DIR/suites/${SUITE}.sh"
    if ! source "$SCRIPT_DIR/suites/${SUITE}.sh"
    then
        return 1
    fi
    log_info "Modules in Suite : ${#MODULE_LIST[@]}"

    #
    # Execute Modules
    #
    run_modules

    ###########################################################################
    # Suite End
    ###########################################################################

    log_info "============================================================"
    log_info "Suite Completed : ${SUITE}"
    log_info "============================================================"
    log_info ""
}

###############################################################################
# Execute Selected Suites
###############################################################################

run_suites()
{
    local SUITE

    for SUITE in "${SUITE_LIST[@]}"
    do
        run_single_suite "$SUITE"
    done
}

###############################################################################
# Main Execution
###############################################################################

execute_validation()
{
    #
    # Run Modules
    #
    if [ ${#MODULE_LIST[@]} -gt 0 ]
    then
        run_modules
    fi

    #
    # Run Suites
    #
    if [ ${#SUITE_LIST[@]} -gt 0 ]
    then
        run_suites
    fi
}

while [ "$LOOP_MODE" -eq 1 ]
do
    execute_validation
    sleep 2
done

[ "$LOOP_MODE" -eq 0 ] && execute_validation


fi

###############################################################################
# Print Final Summary
###############################################################################
print_summary
