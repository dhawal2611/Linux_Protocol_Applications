#!/bin/bash
###############################################################################
# File        : arguments.sh
# Description : Command Line Argument Parser
###############################################################################

###############################################################################
# Global Variables
###############################################################################

#
# Selected Modules
#
MODULE_LIST=()

#
# Selected Suites
#
SUITE_LIST=()

#
# Suite Selected Flag
#
SUITE_SELECTED=0

#
# Storage device list
#
STORAGE_DEVICE_LIST=(
    "/dev/mmcblk0"
    "/dev/nvme0n1"
)

###############################################################################
# Discover Available Modules and Suites
###############################################################################

discover_modules_and_suites()
{
    #
    # Discover Modules
    #
    AVAILABLE_MODULES=()

    for FILE in "$SCRIPT_DIR/modules"/*.sh
    do
        [ -e "$FILE" ] || continue

        AVAILABLE_MODULES+=("$(basename "$FILE" .sh)")
    done

    #
    # Sort Modules Alphabetically
    #
    IFS=$'\n' AVAILABLE_MODULES=($(printf "%s\n" "${AVAILABLE_MODULES[@]}" | sort))
    unset IFS

    #
    # Discover Suites
    #
    AVAILABLE_SUITES=()

    for FILE in "$SCRIPT_DIR/suites"/*.sh
    do
        [ -e "$FILE" ] || continue

        AVAILABLE_SUITES+=("$(basename "$FILE" .sh)")
    done

    #
    # Sort Suites Alphabetically
    #
    IFS=$'\n' AVAILABLE_SUITES=($(printf "%s\n" "${AVAILABLE_SUITES[@]}" | sort))
    unset IFS
}

###############################################################################
# Check Module
###############################################################################

is_module()
{
    local MODULE="$1"

    for ITEM in "${AVAILABLE_MODULES[@]}"
    do
        [ "$ITEM" = "$MODULE" ] && return 0
    done

    return 1
}

###############################################################################
# Check Suite
###############################################################################

is_suite()
{
    local SUITE="$1"

    if [ "$SUITE" = "all" ]; then
        return 0
    fi

    for ITEM in "${AVAILABLE_SUITES[@]}"
    do
        [ "$ITEM" = "$SUITE" ] && return 0
    done

    return 1
}

###############################################################################
# Add Module
###############################################################################

add_module()
{
    local MODULE="$1"

    #
    # Avoid duplicate modules
    #
    for ITEM in "${MODULE_LIST[@]}"
    do
        [ "$ITEM" = "$MODULE" ] && return
    done

    MODULE_LIST+=("$MODULE")
}

###############################################################################
# Add Suite
###############################################################################

add_suite()
{
    local SUITE="$1"

    if [ "$SUITE" = "all" ]
    then
        MODULE_LIST=("${AVAILABLE_MODULES[@]}")
        RUN_ALL_MODULES=1
        return
    fi
    #
    # Avoid duplicate suites
    #
    for ITEM in "${SUITE_LIST[@]}"
    do
        [ "$ITEM" = "$SUITE" ] && return
    done

    SUITE_SELECTED=1
    SUITE_LIST+=("$SUITE")
}

###############################################################################
# Parse Logger Mode
###############################################################################

parse_logger()
{
    case "$1" in

        console|file|both|none)

            LOGGER_OUTPUT_MODE="$1"
            ;;

        *)

            echo
            echo "ERROR : Invalid LOGGER_OUTPUT_MODE : $1"
            echo
            echo "Valid Values:"
            echo "    console"
            echo "    file"
            echo "    both"
            echo "    none"
            echo

            exit 1
            ;;

    esac
}

###############################################################################
# Parse Test Log Mode
###############################################################################

parse_testlog()
{
    case "$1" in

        console|file|both|none)

            TEST_LOG_OUTPUT_MODE="$1"
            ;;

        *)

            echo
            echo "ERROR : Invalid TEST_LOG_OUTPUT_MODE : $1"
            echo
            echo "Valid Values:"
            echo "    console"
            echo "    file"
            echo "    both"
            echo "    none"
            echo

            exit 1
            ;;

    esac
}

###############################################################################
# Parse CSV
###############################################################################

parse_csv()
{
    CSV_REPORT_ENABLE=1

    #
    # Optional CSV filename
    #
    if [ -n "$1" ] && [[ "$1" != -* ]]
    then
        CSV_FILE="$1"
        shift
    fi
}

###############################################################################
# Parse Loop
###############################################################################

parse_loop()
{
    LOOP_MODE=1
}

###############################################################################
# Generate Log Target
###############################################################################

generate_log_target()
{
    local TARGET=""

    if [ "$SUITE_SELECTED" -eq 1 ]
    then

        TARGET=$(IFS=_ ; echo "${SUITE_LIST[*]}")

    else

        TARGET=$(IFS=_ ; echo "${MODULE_LIST[*]}")

    fi

    [ -z "$TARGET" ] && TARGET="validation"

    LOG_TARGET="$TARGET"
}

###############################################################################
# Show Help
###############################################################################

show_help()
{
    #
    # Make sure latest modules/suites are discovered
    #
    discover_modules_and_suites

    echo
    echo "==============================================================================="
    echo "              Embedded Linux Validation Framework"
    echo "==============================================================================="
    echo
    echo "Usage:"
    echo
    echo "    ./validate.sh [OPTIONS] <MODULE(S)>"
    echo "    ./validate.sh [OPTIONS] <SUITE(S)>"
    echo
    echo "==============================================================================="
    echo "AVAILABLE MODULES"
    echo "==============================================================================="

    for MODULE in "${AVAILABLE_MODULES[@]}"
    do
        printf "    %-20s\n" "$MODULE"
    done

    echo
    echo "==============================================================================="
    echo "AVAILABLE SUITES"
    echo "==============================================================================="

    for SUITE in "${AVAILABLE_SUITES[@]}"
    do
        printf "    %-20s\n" "$SUITE"
    done

    echo
    echo "==============================================================================="
    echo "OPTIONS"
    echo "==============================================================================="
    echo
    printf "    %-28s %s\n" "-h, --help"          "Show this help message"
    printf "    %-28s %s\n" "-l, --loop"          "Run continuously until Ctrl+C"
    printf "    %-28s %s\n" "--logger MODE"       "Logger output mode"
    printf "    %-28s %s\n" "--testlog MODE"      "Test log output mode"
    printf "    %-28s %s\n" "--csv"               "Enable CSV report generation"
    printf "    %-28s %s\n" "--csv <file>"        "Custom CSV report filename"
    printf "    %-28s %s\n" "--version"           "Show framework version"
    echo

    echo "==============================================================================="
    echo "LOGGER MODES"
    echo "==============================================================================="
    echo
    printf "    %-15s %s\n" "console" "Print logger messages to console"
    printf "    %-15s %s\n" "file"    "Write logger messages to log file"
    printf "    %-15s %s\n" "both"    "Print to console and log file"
    echo

    echo "==============================================================================="
    echo "TEST LOG MODES"
    echo "==============================================================================="
    echo
    printf "    %-15s %s\n" "console" "Print command/test logs to console"
    printf "    %-15s %s\n" "file"    "Write command/test logs to log file"
    printf "    %-15s %s\n" "both"    "Print to console and log file"
    printf "    %-15s %s\n" "none"    "Disable command/test logs"
    echo

    echo "==============================================================================="
    echo "EXAMPLES"
    echo "==============================================================================="
    echo
    echo "Run a single module:"
    echo "    ./validate.sh cpu"
    echo
    echo "Run multiple modules:"
    echo "    ./validate.sh cpu ddr ethernet"
    echo
    echo "Run a suite:"
    echo "    ./validate.sh networking"
    echo
    echo "Run multiple suites:"
    echo "    ./validate.sh networking storage"
    echo
    echo "Enable continuous execution:"
    echo "    ./validate.sh cpu --loop"
    echo
    echo "Enable logger to console only:"
    echo "    ./validate.sh cpu --logger console"
    echo
    echo "Enable logger to file:"
    echo "    ./validate.sh cpu --logger file"
    echo
    echo "Enable logger to both:"
    echo "    ./validate.sh cpu --logger both"
    echo
    echo "Print test logs to console:"
    echo "    ./validate.sh cpu --testlog console"
    echo
    echo "Store test logs to file:"
    echo "    ./validate.sh cpu --testlog file"
    echo
    echo "Print and store test logs:"
    echo "    ./validate.sh cpu --testlog both"
    echo
    echo "Disable test logs:"
    echo "    ./validate.sh cpu --testlog none"
    echo
    echo "Generate CSV report:"
    echo "    ./validate.sh cpu --csv"
    echo
    echo "Generate custom CSV report:"
    echo "    ./validate.sh cpu --csv cpu_report.csv"
    echo
    echo "Run full validation:"
    echo "    ./validate.sh full_validation"
    echo
    echo "Combined example:"
    echo "    ./validate.sh cpu ddr --logger both --testlog file --csv --loop"
    echo
    echo "Run all modules:"
    echo "    ./validate.sh all"
    echo
    echo "==============================================================================="
    echo "NOTES"
    echo "==============================================================================="
    echo
    echo "  • Modules are loaded automatically from the modules/ directory."
    echo "  • Suites are loaded automatically from the suites/ directory."
    echo "  • Log file creation is automatically enabled when:"
    echo "        --logger file"
    echo "        --logger both"
    echo "        --testlog file"
    echo "        --testlog both"
    echo "  • CSV report generation is enabled only when '--csv' is specified."
    echo "  • Press Ctrl+C to stop loop mode."
    echo
    echo "==============================================================================="
    echo

    exit 0
}
###############################################################################
# Parse Arguments
###############################################################################

parse_arguments()
{
    RUN_ALL_MODULES=0
    MODULE_LIST=()
    SUITE_LIST=()

    #
    # Discover Modules and Suites
    #
    discover_modules_and_suites

    #log_debug "Available Modules : ${AVAILABLE_MODULES[*]}"
    #log_debug "Available Suites  : ${AVAILABLE_SUITES[*]}"

    while [ $# -gt 0 ]
    do

        case "$1" in

            ###################################################################
            # Help
            ###################################################################

            -h|--help)

                show_help
                ;;

            ###################################################################
            # Loop
            ###################################################################

            -l|--loop)

                parse_loop
                ;;

            ###################################################################
            # Logger
            ###################################################################

            --logger)

                shift

                [ $# -eq 0 ] && \
                {
                    echo "ERROR : Missing logger mode."
                    exit 1
                }

                parse_logger "$1"
                ;;

            ###################################################################
            # Test Log
            ###################################################################

            --testlog)

                shift

                [ $# -eq 0 ] && \
                {
                    echo "ERROR : Missing test log mode."
                    exit 1
                }

                parse_testlog "$1"
                ;;

            ###################################################################
            # CSV
            ###################################################################

            --csv)

		shift

                parse_csv "$1"

		if [ -n "$1" ] && [[ "$1" != -* ]]
    		then
    		    shift
    		fi

    		continue
                ;;

            ###################################################################
            # Version
            ###################################################################

	    --version)
	        echo "Embedded Linux Validation Framework v1.0.0"
	        exit 0
	        ;;

            ###################################################################
            # Unknown Option
            ###################################################################

            -*)

                echo
                echo "ERROR : Unknown option : $1"
                echo

                exit 1
                ;;

            ###################################################################
            # Module / Suite
            ###################################################################

            *)

                #
                # Run All Modules
                #
                #if [ "$1" = "all" ]
                #then
		#    RUN_ALL_MODULES=1
                #    MODULE_LIST=("${AVAILABLE_MODULES[@]}")

                #
                # Single Module
                #
                if is_module "$1"
                then

                    add_module "$1"

                #
                # Suite
                #
                elif is_suite "$1"
                then

                    add_suite "$1"

                #
                # Unknown Argument
                #
                else

                    echo
                    echo "ERROR : Unknown module/suite : $1"
                    echo

                    exit 1

                fi
                ;;

        esac

        shift

    done

    if [ "$RUN_ALL_MODULES" -eq 1 ]
    then
        log_info "Executing Complete Validation"
    fi

    ###########################################################################
    # Validate Mixed Selection
    ###########################################################################

    if [ ${#MODULE_LIST[@]} -gt 0 ] &&
       [ ${#SUITE_LIST[@]} -gt 0 ]
    then

        echo
        echo "ERROR : Modules and Suites cannot be used together."
        echo "Please select either:"
        echo "  • One or more modules"
        echo "  • One suite"
        echo

        exit 1

    fi

    ###########################################################################
    # Validate Selection
    ###########################################################################

    if [ ${#MODULE_LIST[@]} -eq 0 ] &&
       [ ${#SUITE_LIST[@]} -eq 0 ]
    then

        echo
        echo "ERROR : No Module/Suite Selected."
        echo

        exit 1

    fi

    ###########################################################################
    # Generate Log Target
    ###########################################################################

    generate_log_target

    ###########################################################################
    # Enable Log File Automatically
    ###########################################################################

    if [ "$LOGGER_OUTPUT_MODE" = "file" ] ||
       [ "$LOGGER_OUTPUT_MODE" = "both" ] ||
       [ "$TEST_LOG_OUTPUT_MODE" = "file" ] ||
       [ "$TEST_LOG_OUTPUT_MODE" = "both" ]
    then

        LOG_FILE_ENABLE=1

    fi
}
