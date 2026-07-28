#!/bin/bash
###############################################################################
# File        : validate.sh
# Description : Embedded Linux Validation Framework
###############################################################################

SCRIPT_DIR=$(dirname "$(realpath "$0")")

source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/arguments.sh"
source "$SCRIPT_DIR/lib/command.sh"

LOOP_MODE=0

# Parse command-line arguments
parse_arguments "$@"

# Handle Ctrl+C
trap cleanup SIGINT

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
if [ "$LOG_FILE_ENABLE" -eq 1 ]
then
    LOG_FILE="${LOG_DIR}/validation_${TIMESTAMP}_${LOG_TARGET}.log"

    touch "$LOG_FILE"
fi

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
    printf '"Module","Test ID","Test Name","Command","Result","Exit Status","Execution Time(s)","Start Time","End Time","Output"\n' \
> "$CSV_FILE"

fi

###############################################################################
# Execute Modules / Suites
###############################################################################
run_modules()
{
    for module in "${MODULE_LIST[@]}"
    do

        #######################################################################
        # Execute Individual Module
        #######################################################################
        if [ -f "$SCRIPT_DIR/modules/${module}.sh" ]
        then
            echo
            log_info "Running Module : ${module}"

            source "$SCRIPT_DIR/modules/${module}.sh"

            run_test

        #######################################################################
        # Execute Test Suite
        #######################################################################
        elif [ -f "$SCRIPT_DIR/suites/${module}.sh" ]
        then
            source "$SCRIPT_DIR/suites/${module}.sh"

            for suite_module in "${MODULE_LIST[@]}"
            do
                echo
                log_info "Running Module : ${suite_module}"

                source "$SCRIPT_DIR/modules/${suite_module}.sh"

                run_test
            done

        #######################################################################
        # Invalid Module
        #######################################################################
        else
            log_error "Module '${module}' not found."

            return 1
        fi
    done
}

###############################################################################
# Main
###############################################################################

if [ "$LOOP_MODE" -eq 1 ]
then
    while true
    do
        run_modules
        sleep 2
    done
else
    run_modules
fi

###############################################################################
# Print Final Summary
###############################################################################
print_summary
