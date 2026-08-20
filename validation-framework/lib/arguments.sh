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
    # Optional CSV filename — if provided, honour it and lock it so that
    # run_single_module() does not overwrite it with the per-module path.
    #
    if [ -n "$1" ] && [[ "$1" != -* ]]
    then
        CSV_FILE="$1"
        CSV_FILE_OVERRIDE="$1"   # prevents per-module auto-naming
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
# Parse Loop Duration
#
# Converts minutes to seconds and stores in LOOP_DURATION_SECS.
# Called when --duration <minutes> is found after --loop.
###############################################################################

parse_duration()
{
    local MIN="$1"

    if ! [[ "$MIN" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
       awk "BEGIN {exit !($MIN <= 0)}" 2>/dev/null
    then
        echo ""
        echo "ERROR : Invalid duration '${MIN}'. Must be a positive number (minutes)."
        echo ""
        exit 1
    fi

    LOOP_DURATION_SECS=$(awk "BEGIN {printf \"%.0f\", $MIN * 60}")
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
    echo "    ./validate.sh                                  Interactive menu"
    echo "    ./validate.sh [OPTIONS] <MODULE(S)|SUITE(S)>   Direct CLI mode"
    echo

    echo "==============================================================================="
    echo "AVAILABLE MODULES"
    echo "==============================================================================="
    echo

    # Print modules in 3 columns (auto-sized)
    local MOD_TOTAL=${#AVAILABLE_MODULES[@]}
    local MOD_COLS=3
    local MOD_ROWS=$(( (MOD_TOTAL + MOD_COLS - 1) / MOD_COLS ))
    local MOD_MAX=0
    local _M
    for _M in "${AVAILABLE_MODULES[@]}"
    do
        (( ${#_M} > MOD_MAX )) && MOD_MAX=${#_M}
    done
    local MOD_CW=$(( MOD_MAX + 2 ))

    local _R _C _IDX
    for (( _R=0; _R<MOD_ROWS; _R++ ))
    do
        printf "    "
        for (( _C=0; _C<MOD_COLS; _C++ ))
        do
            _IDX=$(( _C * MOD_ROWS + _R ))
            (( _IDX < MOD_TOTAL )) && printf "%-*s" "$MOD_CW" "${AVAILABLE_MODULES[$_IDX]}"
        done
        echo
    done

    echo
    echo "==============================================================================="
    echo "AVAILABLE SUITES"
    echo "==============================================================================="
    echo
    for SUITE in "${AVAILABLE_SUITES[@]}"
    do
        printf "    %s\n" "$SUITE"
    done

    echo
    echo "==============================================================================="
    echo "OPTIONS"
    echo "==============================================================================="
    echo
    printf "    %-30s %s\n" "-h, --help"           "Show this help message"
    printf "    %-30s %s\n" "--version"            "Show framework version"
    echo
    printf "    %-30s %s\n" "-l, --loop"           "Run loop continuously until Ctrl+C (infinite)"
    printf "    %-30s %s\n" "--duration MINUTES"   "Run loop for N minutes then stop (requires --loop)"
    echo
    printf "    %-30s %s\n" "--logger MODE"        "Logger output mode  (default: console)"
    printf "    %-30s %s\n" "--testlog MODE"       "Test log output mode  (default: console)"
    echo
    printf "    %-30s %s\n" "--csv"                "Enable CSV report (auto-named csv/<module>.csv)"
    printf "    %-30s %s\n" "--csv <file>"         "Enable CSV report with custom filename"
    echo

    echo "==============================================================================="
    echo "LOGGER MODES  (--logger)"
    echo "==============================================================================="
    echo
    printf "    %-10s %s\n" "none"    "Suppress all logger output"
    printf "    %-10s %s\n" "console" "Print [INFO]/[PASS]/[FAIL]/[WARN] to console  (default)"
    printf "    %-10s %s\n" "file"    "Write logger messages to logs/<module>.log"
    printf "    %-10s %s\n" "both"    "Print to console and write to log file"
    echo

    echo "==============================================================================="
    echo "TEST LOG MODES  (--testlog)"
    echo "==============================================================================="
    echo
    printf "    %-10s %s\n" "none"    "Disable all test/command logs"
    printf "    %-10s %s\n" "console" "Print command output and test details to console  (default)"
    printf "    %-10s %s\n" "file"    "Write command output and test details to logs/<module>.log"
    printf "    %-10s %s\n" "both"    "Print to console and write to log file"
    echo

    echo "==============================================================================="
    echo "LOG & CSV FILES"
    echo "==============================================================================="
    echo
    echo "  Log files  : logs/<module>.log   — one file per module, appended across runs"
    echo "  CSV files  : csv/<module>.csv    — one file per module, appended across runs"
    echo
    echo "  Log file is created automatically when --logger or --testlog is set to"
    echo "  'file' or 'both'."
    echo
    echo "  CSV file is created only when --csv is specified."
    echo "  When --csv <file> is given, all modules write to that single custom file."
    echo
    echo "  Each run appends a timestamped separator to the log file:"
    echo "      # RUN START : 2026-08-20 18:00:00  |  Module: ethernet"
    echo

    echo "==============================================================================="
    echo "INTERACTIVE MENU"
    echo "==============================================================================="
    echo
    echo "  Run with no arguments to open the interactive menu:"
    echo "      ./validate.sh"
    echo
    echo "  Features:"
    echo "    • Dynamic 2 or 3-column layout (3 columns when ≥ 20 modules)"
    echo "    • Number-based selection — enter one or more numbers separated by spaces"
    echo "    • Run ALL modules with a single entry"
    echo "    • Single run or timed loop mode per selection"
    echo "    • Confirmation prompt before execution"
    echo "    • Ctrl+C during loop prints grand summary and returns to menu"
    echo

    echo "==============================================================================="
    echo "EXAMPLES"
    echo "==============================================================================="
    echo
    echo "  --- Interactive ---"
    echo
    echo "  Open interactive menu:"
    echo "      ./validate.sh"
    echo
    echo "  --- Single run ---"
    echo
    echo "  Run one module (console output only):"
    echo "      ./validate.sh cpu"
    echo
    echo "  Run multiple modules:"
    echo "      ./validate.sh cpu ethernet gpio"
    echo
    echo "  Run a suite:"
    echo "      ./validate.sh networking"
    echo
    echo "  Run all modules:"
    echo "      ./validate.sh all"
    echo
    echo "  --- Logging ---"
    echo
    echo "  Save logger and test logs to file:"
    echo "      ./validate.sh cpu --logger file --testlog file"
    echo "      # writes to logs/cpu.log"
    echo
    echo "  Log to both console and file:"
    echo "      ./validate.sh cpu --logger both --testlog both"
    echo
    echo "  Suppress all output (silent run):"
    echo "      ./validate.sh cpu --logger none --testlog none"
    echo
    echo "  --- CSV reports ---"
    echo
    echo "  Auto-named CSV per module:"
    echo "      ./validate.sh cpu --csv"
    echo "      # writes to csv/cpu.csv"
    echo
    echo "  Custom CSV filename (all modules share one file):"
    echo "      ./validate.sh cpu ethernet --csv my_report.csv"
    echo
    echo "  --- Loop mode ---"
    echo
    echo "  Infinite loop (stop with Ctrl+C):"
    echo "      ./validate.sh cpu --loop"
    echo
    echo "  Timed loop — run for 10 minutes then stop:"
    echo "      ./validate.sh cpu --loop --duration 10"
    echo
    echo "  Loop with CSV report:"
    echo "      ./validate.sh cpu --loop --duration 5 --csv"
    echo
    echo "  --- Combined ---"
    echo
    echo "  Multi-module, timed loop, full logging:"
    echo "      ./validate.sh cpu ethernet --loop --duration 30 --logger both --testlog file --csv"
    echo

    echo "==============================================================================="
    echo "NOTES"
    echo "==============================================================================="
    echo
    echo "  • Modules are loaded automatically from the modules/ directory."
    echo "  • Suites are loaded automatically from the suites/ directory."
    echo "  • Modules and Suites cannot be mixed in the same invocation."
    echo "  • --duration without --loop has no effect."
    echo "  • In loop mode, log files are not written (CSV only)."
    echo "  • Press Ctrl+C at any time during loop mode to stop and see the summary."
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
            # Loop Duration
            ###################################################################

            --duration)

                shift

                [ $# -eq 0 ] && \
                {
                    echo "ERROR : Missing duration value (minutes)."
                    exit 1
                }

                parse_duration "$1"
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
