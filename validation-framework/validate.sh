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
