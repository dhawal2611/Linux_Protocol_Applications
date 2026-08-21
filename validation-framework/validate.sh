#!/bin/bash
###############################################################################
# File        : validate.sh
# Description : Embedded Linux Validation Framework - unified entry point
#
# Modes
# -----
#   Interactive  : run with no arguments -> numbered menu, loop/single choice
#   Direct       : run with module/suite names and flags (original CLI style)
#
# Log options are driven by conf/log_options.conf.
# Each module row sets TEXT_FILE / CSV_FILE / ON_LOG (y/n).
# Command-line flags --logger / --testlog / --csv always override the file.
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###############################################################################
# Source Framework Libraries
###############################################################################

source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/arguments.sh"
source "$SCRIPT_DIR/lib/command.sh"
source "$SCRIPT_DIR/lib/assertions.sh"
source "$SCRIPT_DIR/lib/test_registry.sh"
source "$SCRIPT_DIR/lib/framework_check.sh"

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

    # ------------------------------------------------------------------ #
    # Per-module log/CSV paths.
    # Each module appends to its own file across runs:
    #   logs/<module>.log
    #   csv/<module>.csv
    # Directories already exist (created by initialize_framework).
    # ------------------------------------------------------------------ #
    if [ "$LOG_FILE_ENABLE" -eq 1 ]
    then
        LOG_FILE="${LOG_DIR}/${MODULE}.log"
        touch "$LOG_FILE"
    fi

    if [ "$CSV_REPORT_ENABLE" -eq 1 ]
    then
        if [ -z "${CSV_FILE_OVERRIDE:-}" ]
        then
            CSV_FILE="${CSV_DIR}/${MODULE}.csv"
            touch "$CSV_FILE"
        fi
        csv_create_header
    fi

    # ------------------------------------------------------------------ #
    # Run-start separator in the log file — makes it easy to identify
    # individual runs when the file accumulates across multiple executions.
    # ------------------------------------------------------------------ #
    if [ "$LOG_FILE_ENABLE" -eq 1 ] && [ -n "$LOG_FILE" ]
    then
        printf '\n################################################################################\n' >> "$LOG_FILE"
        printf '# RUN START : %s  |  Module: %s\n' \
            "$(date '+%Y-%m-%d %H:%M:%S')" "$MODULE"          >> "$LOG_FILE"
        printf '################################################################################\n\n' >> "$LOG_FILE"
    fi

    log_info ""
    log_info "Running Module : ${MODULE}"

    unset REQUIRED_COMMANDS

    clear_test_registry

    if ! source "$SCRIPT_DIR/modules/${MODULE}.sh"
    then
        log_error "Failed to load module ${MODULE}"
        return 1
    fi

    if declare -p REQUIRED_COMMANDS >/dev/null 2>&1
    then
        check_dependencies "${REQUIRED_COMMANDS[@]}"
        if [ $? -ne 0 ]
        then
            log_error "Skipping Module : ${MODULE}"
            return 1
        fi
    fi

    run_registered_tests
}

###############################################################################
# Execute Selected Modules (non-interactive path)
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

    if [ ! -f "$SCRIPT_DIR/suites/${SUITE}.sh" ]
    then
        log_error "Suite '${SUITE}' not found."
        return 1
    fi

    log_info ""
    log_info "============================================================"
    log_info "Starting Suite : ${SUITE}"
    log_info "============================================================"

    MODULE_LIST=()

    if ! source "$SCRIPT_DIR/suites/${SUITE}.sh"
    then
        return 1
    fi

    log_info "Modules in Suite : ${#MODULE_LIST[@]}"

    run_modules

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
# execute_validation - run whatever is in MODULE_LIST / SUITE_LIST
###############################################################################

execute_validation()
{
    if [ ${#MODULE_LIST[@]} -gt 0 ]
    then
        run_modules
    fi

    if [ ${#SUITE_LIST[@]} -gt 0 ]
    then
        run_suites
    fi
}

###############################################################################
# -------------------------------------- #
#  INTERACTIVE MENU
# -------------------------------------- #
###############################################################################

###############################################################################
# Build the sorted module list from the modules/ directory (same as
# arguments.sh discover_modules_and_suites but self-contained here).
###############################################################################

discover_menu_modules()
{
    MENU_MODULES=()
    local FILE
    for FILE in "$SCRIPT_DIR/modules"/*.sh
    do
        [ -e "$FILE" ] || continue
        MENU_MODULES+=("$(basename "$FILE" .sh)")
    done
    IFS=$'\n' MENU_MODULES=($(printf "%s\n" "${MENU_MODULES[@]}" | sort))
    unset IFS
}

###############################################################################
# print_main_menu
#
# Displays a dynamic 2- or 3-column module list.
#
# Layout rules:
#   < 20 modules  ->  2 columns
#   >= 20 modules ->  3 columns
#
# Column width is auto-sized to the longest module name + 2 padding chars,
# so names never overlap regardless of how many modules are present.
###############################################################################

print_main_menu()
{
    local TOTAL=${#MENU_MODULES[@]}
    local ALL_OPT=$(( TOTAL + 1 ))

    # ------------------------------------------------------------------ #
    # Determine number of columns and rows
    # ------------------------------------------------------------------ #
    local COLS
    if (( TOTAL >= 20 ))
    then
        COLS=3
    else
        COLS=2
    fi

    local ROWS=$(( (TOTAL + COLS - 1) / COLS ))   # ceiling division

    # ------------------------------------------------------------------ #
    # Auto-size column width: longest module name + 2 chars padding
    # ------------------------------------------------------------------ #
    local MAX_LEN=0
    local M
    for M in "${MENU_MODULES[@]}"
    do
        (( ${#M} > MAX_LEN )) && MAX_LEN=${#M}
    done
    local COL_WIDTH=$(( MAX_LEN + 2 ))

    # Number prefix width: "  XX. " = 6 chars for up to 99 modules
    # Total width per column = 6 + COL_WIDTH + 2 (gap between columns)
    local ENTRY_WIDTH=$(( 6 + COL_WIDTH ))

    # Calculate total line width for the border
    local BORDER_WIDTH=$(( ENTRY_WIDTH * COLS + 2 ))
    (( BORDER_WIDTH < 74 )) && BORDER_WIDTH=74   # minimum width

    local BORDER
    BORDER=$(printf '%*s' "$BORDER_WIDTH" '' | tr ' ' '=')
    local DIVIDER
    DIVIDER=$(printf '%*s' "$BORDER_WIDTH" '' | tr ' ' '-')

    # ------------------------------------------------------------------ #
    # Print header
    # ------------------------------------------------------------------ #
    echo "$BORDER"
    printf "%*s\n" "$(( (BORDER_WIDTH + 44) / 2 ))" \
        "EMBEDDED LINUX VALIDATION - TEST MENU"
    echo "$BORDER"

    # ------------------------------------------------------------------ #
    # Print module rows
    # ------------------------------------------------------------------ #
    local ROW COL IDX
    for (( ROW=0; ROW<ROWS; ROW++ ))
    do
        printf "  "
        for (( COL=0; COL<COLS; COL++ ))
        do
            # Column-major order: index = COL*ROWS + ROW
            IDX=$(( COL * ROWS + ROW ))
            if (( IDX < TOTAL ))
            then
                local NUM=$(( IDX + 1 ))
                local NAME="${MENU_MODULES[$IDX]}"
                printf "%2d. %-*s  " "$NUM" "$COL_WIDTH" "$NAME"
            fi
        done
        echo
    done

    # ------------------------------------------------------------------ #
    # Footer
    # ------------------------------------------------------------------ #
    echo "$DIVIDER"
    printf "  %2d. Run ALL modules  (runs individually, select alone)\n" "$ALL_OPT"
    echo "$DIVIDER"
    echo "   0. Exit"
    echo "$BORDER"
    echo "  Enter one or more numbers separated by spaces (e.g. 1 3 7)."
    printf "  Select [0-%d]: " "$ALL_OPT"
}

###############################################################################
# parse_selection <raw_input>
#
# Tokenises the input string (spaces or commas as delimiters) and populates:
#   PARSED_NUMS[]   - unique valid numbers entered
#   HAS_ALL         - 1 if ALL_OPT was among the numbers
#   HAS_INVALID     - 1 if any token was out of range or non-numeric
#   INVALID_TOKENS  - space-separated list of bad tokens
###############################################################################

parse_selection()
{
    local RAW="$1"
    local TOTAL=${#MENU_MODULES[@]}
    local ALL_OPT=$(( TOTAL + 1 ))

    PARSED_NUMS=()
    HAS_ALL=0
    HAS_INVALID=0
    INVALID_TOKENS=""

    # Replace commas with spaces, then iterate tokens
    local TOKEN
    for TOKEN in ${RAW//,/ }
    do
        # Must be a non-negative integer
        if ! [[ "$TOKEN" =~ ^[0-9]+$ ]]
        then
            HAS_INVALID=1
            INVALID_TOKENS="$INVALID_TOKENS $TOKEN"
            continue
        fi

        # Zero means exit - handled by caller
        if [ "$TOKEN" -eq 0 ]
        then
            PARSED_NUMS+=("0")
            continue
        fi

        # Out of range
        if (( TOKEN > ALL_OPT ))
        then
            HAS_INVALID=1
            INVALID_TOKENS="$INVALID_TOKENS $TOKEN"
            continue
        fi

        # ALL_OPT
        if [ "$TOKEN" -eq "$ALL_OPT" ]
        then
            HAS_ALL=1
        fi

        # Deduplicate
        local DUP=0
        local N
        for N in "${PARSED_NUMS[@]}"
        do
            [ "$N" -eq "$TOKEN" ] && DUP=1 && break
        done
        [ "$DUP" -eq 0 ] && PARSED_NUMS+=("$TOKEN")
    done
}

###############################################################################
# ask_exec_mode <label>  ->  sets EXEC_MODE ("loop"|"single")
###############################################################################

ask_exec_mode()
{
    local LABEL="$1"
    echo ""
    echo "  Selected  : $LABEL"
    echo "  -------------------------------------------------------"
    echo "  Execution mode:"
    echo "    1. Loop   - run repeatedly for a set duration"
    echo "    2. Single - run once and show result"
    echo "  -------------------------------------------------------"
    printf "  Choose [1-2]: "
    read -r _MODE

    case "$_MODE" in
        1) EXEC_MODE="loop"   ;;
        2) EXEC_MODE="single" ;;
        *) EXEC_MODE="single"
           echo "  [!] Invalid choice - defaulting to single run."
           ;;
    esac
}

###############################################################################
# ask_duration
#
# Asks the user for:
#   - Total loop duration in minutes  -> sets DURATION_SECS
#   - Delay between iterations in sec -> sets ITER_DELAY_SECS (default 2)
###############################################################################

ask_duration()
{
    echo ""
    printf "  Enter loop duration in minutes: "
    read -r _MIN

    # if ! [[ "$_MIN" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
    #    (( $(echo "$_MIN <= 0" | bc -l 2>/dev/null || echo 0) ))
    # then
    #     echo "  [!] Invalid duration - defaulting to 1 minute."
    #     _MIN=1
    # fi

    # DURATION_SECS=$(printf "%.0f" "$(echo "$_MIN * 60" | bc)")
    # echo "  -> Will loop for ${_MIN} minute(s) (${DURATION_SECS}s)."

    # Used a 'awk' commad in place of 'bc'.
    # As we not expect default 'bc' command is in the default yocto system
    if ! [[ "$_MIN" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
    awk "BEGIN {exit !($_MIN <= 0)}" 2>/dev/null
    then
        echo "  [!] Invalid duration - defaulting to 1 minute."
        _MIN=1
    fi

    # Multiplies by 60 and rounds to the nearest whole integer natively
    DURATION_SECS=$(awk "BEGIN {printf \"%.0f\", $_MIN * 60}")
    echo "  -> Will loop for ${_MIN} minute(s) (${DURATION_SECS}s)."
    # FYI: also we can use 'dc' command

    echo ""
    printf "  Enter delay between iterations in seconds [default: 2]: "
    read -r _DELAY

    # Empty input or invalid -> use default 2 seconds
    if [[ -z "$_DELAY" ]]
    then
        _DELAY=2
    elif ! [[ "$_DELAY" =~ ^[0-9]+$ ]]
    then
        echo "  [!] Invalid delay - defaulting to 2 seconds."
        _DELAY=2
    fi

    ITER_DELAY_SECS="$_DELAY"
    echo "  -> Delay between iterations: ${ITER_DELAY_SECS}s."
}

###############################################################################
# ask_output_options <module1> [module2] ...
#
# Interactively asks the user how they want logger output, test log output,
# and whether to generate a CSV report.
# Then checks for any existing log/CSV files for the selected modules and
# asks whether to delete them or continue appending.
#
# Sets:
#   LOGGER_OUTPUT_MODE     - console | file | both | none
#   TEST_LOG_OUTPUT_MODE   - console | file | both | none
#   LOG_FILE_ENABLE        - 0 | 1
#   CSV_REPORT_ENABLE      - 0 | 1
###############################################################################

ask_output_options()
{
    local _OMODS=("$@")

    echo ""
    echo "  -------------------------------------------------------"
    echo "  Output Options"
    echo "  -------------------------------------------------------"

    # ---- Logger output mode ------------------------------------------ #
    echo "  Logger output  (INFO/PASS/FAIL messages):"
    echo "    1. console  - terminal only"
    echo "    2. file     - log file only"
    echo "    3. both     - terminal and log file"
    echo "    4. none     - no file, console only (same as console)"
    printf "  Choose [1-4, default: 1]: "
    read -r _LOPT
    case "$_LOPT" in
        2) LOGGER_OUTPUT_MODE="file"    ; LOG_FILE_ENABLE=1 ;;
        3) LOGGER_OUTPUT_MODE="both"    ; LOG_FILE_ENABLE=1 ;;
        4) LOGGER_OUTPUT_MODE="none"    ; LOG_FILE_ENABLE=0 ;;
        *) LOGGER_OUTPUT_MODE="console" ; LOG_FILE_ENABLE=0 ;;
    esac
    echo "  -> Logger output : ${LOGGER_OUTPUT_MODE}"

    # ---- Test log output mode ---------------------------------------- #
    echo ""
    echo "  Test log output  (command output / test detail):"
    echo "    1. console  - terminal only"
    echo "    2. file     - log file only"
    echo "    3. both     - terminal and log file"
    echo "    4. none     - suppress test logs"
    printf "  Choose [1-4, default: 1]: "
    read -r _TOPT
    case "$_TOPT" in
        2) TEST_LOG_OUTPUT_MODE="file"    ; LOG_FILE_ENABLE=1 ;;
        3) TEST_LOG_OUTPUT_MODE="both"    ; LOG_FILE_ENABLE=1 ;;
        4) TEST_LOG_OUTPUT_MODE="none"                        ;;
        *) TEST_LOG_OUTPUT_MODE="console"                     ;;
    esac
    echo "  -> Test log output : ${TEST_LOG_OUTPUT_MODE}"

    # ---- CSV report -------------------------------------------------- #
    echo ""
    printf "  Save results to CSV report? [y/N]: "
    read -r _CSVOPT
    case "$_CSVOPT" in
        y|Y|yes|YES) CSV_REPORT_ENABLE=1 ;;
        *)           CSV_REPORT_ENABLE=0 ;;
    esac
    echo "  -> CSV report : $([ "$CSV_REPORT_ENABLE" -eq 1 ] && echo "enabled" || echo "disabled")"

    # ------------------------------------------------------------------ #
    # Existing file handling
    #
    # For each module, check if a log/CSV file already exists.
    # Collect all existing files into two lists (log and csv), then ask
    # once for each type: delete (fresh start) or append (keep history).
    # ------------------------------------------------------------------ #
    echo ""
    echo "  -------------------------------------------------------"
    echo "  Existing File Handling"
    echo "  -------------------------------------------------------"

    # Collect existing log files
    local _EXIST_LOGS=()
    if [ "$LOG_FILE_ENABLE" -eq 1 ]
    then
        local _M
        for _M in "${_OMODS[@]}"
        do
            local _LF="${LOG_DIR}/${_M}.log"
            [ -s "$_LF" ] && _EXIST_LOGS+=("$_LF")
        done
    fi

    # Collect existing CSV files
    local _EXIST_CSVS=()
    if [ "$CSV_REPORT_ENABLE" -eq 1 ]
    then
        local _M
        for _M in "${_OMODS[@]}"
        do
            local _CF="${CSV_DIR}/${_M}.csv"
            [ -s "$_CF" ] && _EXIST_CSVS+=("$_CF")
        done
    fi

    # Ask about log files
    if [ "${#_EXIST_LOGS[@]}" -gt 0 ]
    then
        echo "  Existing log file(s) found:"
        local _F
        for _F in "${_EXIST_LOGS[@]}"
        do
            printf "    %s\n" "$_F"
        done
        echo "    1. Delete  - start fresh (remove existing log files)"
        echo "    2. Append  - continue into existing log files (default)"
        printf "  Choose [1-2, default: 2]: "
        read -r _LFILE_OPT
        if [ "$_LFILE_OPT" = "1" ]
        then
            for _F in "${_EXIST_LOGS[@]}"
            do
                rm -f "$_F"
                echo "  -> Deleted : $_F"
            done
        else
            echo "  -> Appending to existing log file(s)."
        fi
    else
        if [ "$LOG_FILE_ENABLE" -eq 1 ]
        then
            echo "  No existing log files found — new files will be created."
        else
            echo "  Log file output disabled — no file action needed."
        fi
    fi

    # Ask about CSV files
    if [ "${#_EXIST_CSVS[@]}" -gt 0 ]
    then
        echo ""
        echo "  Existing CSV file(s) found:"
        local _F
        for _F in "${_EXIST_CSVS[@]}"
        do
            printf "    %s\n" "$_F"
        done
        echo "    1. Delete  - start fresh (remove existing CSV files)"
        echo "    2. Append  - continue into existing CSV files (default)"
        printf "  Choose [1-2, default: 2]: "
        read -r _CSVFILE_OPT
        if [ "$_CSVFILE_OPT" = "1" ]
        then
            for _F in "${_EXIST_CSVS[@]}"
            do
                rm -f "$_F"
                echo "  -> Deleted : $_F"
            done
        else
            echo "  -> Appending to existing CSV file(s)."
        fi
    else
        if [ "$CSV_REPORT_ENABLE" -eq 1 ]
        then
            echo ""
            echo "  No existing CSV files found — new files will be created."
        else
            echo ""
            echo "  CSV report disabled — no file action needed."
        fi
    fi

    echo "  -------------------------------------------------------"
}

###############################################################################
# interactive_run_module <module>
#
# Runs one module once and prints a per-module summary.
###############################################################################

interactive_run_module()
{
    local MODULE="$1"
    echo ""
    echo "=========================================================================="
    echo "  Running : $MODULE"
    echo "=========================================================================="

    PASS_COUNT=0
    FAIL_COUNT=0
    SKIP_COUNT=0

    run_single_module "$MODULE"

    echo ""
    echo "  ---- Run Summary ----------------------------------------"
    printf "  PASS: %d   FAIL: %d   SKIP: %d\n" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
    if [ "$LOG_FILE_ENABLE" -eq 1 ] && [ -n "$LOG_FILE" ]
    then
        printf "  Log : %s\n" "$LOG_FILE"
    fi
    if [ "$CSV_REPORT_ENABLE" -eq 1 ] && [ -n "$CSV_FILE" ]
    then
        printf "  CSV : %s\n" "$CSV_FILE"
        
    fi
    echo "  ---------------------------------------------------------"
}

###############################################################################
# interactive_run_loop <duration_secs> <module1> [module2] ...
#
# Runs all supplied modules IN PARALLEL each iteration until duration expires.
#
# Logging strategy (loop mode):
#   - No text log files are created.
#   - No console output from subprocesses.
#   - All test results go to a single shared CSV per module
#     (validation_<ts>_<module>_loop.csv), accumulating across all iterations.
#   - csv_create_header() / csv_write() are the only logging functions used.
#
# PASS/FAIL/SKIP counts per iteration are derived by:
#   1. Record CSV row count before launching subprocess.
#   2. After subprocess finishes, count new rows and grep the Result column.
#
# Console output during loop is minimal:
#   - Iteration number + time remaining
#   - Per-module PASS / FAIL / SKIP counts
#
# Final summary shows grand totals per module and the shared CSV path.
###############################################################################

interactive_run_loop()
{
    local SECS="$1"
    shift
    local MODS=("$@")
    local MOD_COUNT=${#MODS[@]}

    local END_TIME=$(( $(date +%s) + SECS ))
    local ITER=0
    local DELAY="${ITER_DELAY_SECS:-2}"
    local SESSION_TS
    SESSION_TS=$(date +%Y%m%d_%H%M%S)

    mkdir -p "$LOG_DIR"

    # One shared CSV per module for the entire loop session.
    # csv_create_header() guards the header — written only once per file.
    declare -A MOD_CSV
    local MOD
    for MOD in "${MODS[@]}"
    do
        MOD_CSV["$MOD"]="${CSV_DIR}/${MOD}.csv"
    done

    echo ""
    echo "=========================================================================="
    printf "  Loop run   : %s\n" "${MODS[*]}"
    printf "  Duration   : %ds\n" "$SECS"
    printf "  Delay      : %ds between iterations\n" "$DELAY"
    printf "  Modules    : %d (all launched in parallel each iteration)\n" "$MOD_COUNT"
    echo "  Log        : CSV only"
    for MOD in "${MODS[@]}"
    do
        printf "  CSV        : %s\n" "${MOD_CSV[$MOD]}"
    done
    echo "  Ctrl+C to stop early and print summary"
    echo "=========================================================================="

    # Grand totals across all iterations
    declare -A GRAND_PASS
    declare -A GRAND_FAIL
    declare -A GRAND_SKIP
    for MOD in "${MODS[@]}"
    do
        GRAND_PASS["$MOD"]=0
        GRAND_FAIL["$MOD"]=0
        GRAND_SKIP["$MOD"]=0
    done

    # ------------------------------------------------------------------ #
    # _loop_summary — prints the grand totals table.
    # Defined as a nested function so both the normal exit path and the
    # SIGINT handler can call it without duplicating code.
    # ------------------------------------------------------------------ #
    _loop_summary()
    {
        echo ""
        echo "=========================================================================="
        printf "  LOOP SUMMARY  (%d iteration(s), %d module(s))\n" "$ITER" "$MOD_COUNT"
        echo "=========================================================================="
        local _TOTAL_P=0 _TOTAL_F=0 _TOTAL_S=0
        local _M
        for _M in "${MODS[@]}"
        do
            printf "  %-25s  PASS: %d  FAIL: %d  SKIP: %d\n" \
                "$_M" "${GRAND_PASS[$_M]}" "${GRAND_FAIL[$_M]}" "${GRAND_SKIP[$_M]}"
            (( _TOTAL_P += GRAND_PASS[$_M] ))
            (( _TOTAL_F += GRAND_FAIL[$_M] ))
            (( _TOTAL_S += GRAND_SKIP[$_M] ))
        done
        echo "  ----------------------------------------------------------"
        printf "  %-25s  PASS: %d  FAIL: %d  SKIP: %d\n" \
            "TOTAL" "$_TOTAL_P" "$_TOTAL_F" "$_TOTAL_S"
        echo ""
        echo "  CSV report(s):"
        for _M in "${MODS[@]}"
        do
            printf "  %-25s  %s\n" "$_M" "${MOD_CSV[$_M]}"
        done
        echo "=========================================================================="
    }

    # ------------------------------------------------------------------ #
    # SIGINT handler — Ctrl+C during the loop prints the grand summary
    # and returns cleanly to the interactive menu (does not exit the
    # whole framework process).
    # ------------------------------------------------------------------ #
    _loop_sigint()
    {
        echo ""
        echo ""
        echo "  [!] Interrupted after iteration ${ITER}."
        _loop_summary
        # Restore default SIGINT so the menu is not also trapped
        trap - SIGINT
        # Use a flag to break the while loop instead of exit
        _LOOP_INTERRUPTED=1
    }

    _LOOP_INTERRUPTED=0
    trap '_loop_sigint' SIGINT

    while (( $(date +%s) < END_TIME )) && [ "$_LOOP_INTERRUPTED" -eq 0 ]
    do
        (( ITER++ ))
        local REM=$(( END_TIME - $(date +%s) ))

        echo ""
        printf "  [Iteration %d]  Time remaining: %ds\n" "$ITER" "$REM"
        echo "  ----------------------------------------------------------"

        # Snapshot CSV row count before launching (subtract 1 for header)
        declare -A PRE_COUNT
        for MOD in "${MODS[@]}"
        do
            local CSV="${MOD_CSV[$MOD]}"
            if [ -f "$CSV" ]
            then
                PRE_COUNT["$MOD"]=$(( $(wc -l < "$CSV") - 1 ))
                [ "${PRE_COUNT[$MOD]}" -lt 0 ] && PRE_COUNT["$MOD"]=0
            else
                PRE_COUNT["$MOD"]=0
            fi
        done

        # Launch one subprocess per module — CSV only, no console/log noise
        local PIDS=()
        local ITER_MODS=()
        for MOD in "${MODS[@]}"
        do
            "$SCRIPT_DIR/validate.sh" "$MOD" \
                --logger none --testlog none \
                --csv "${MOD_CSV[$MOD]}" \
                > /dev/null 2>&1 &

            PIDS+=("$!")
            ITER_MODS+=("$MOD")
        done

        # Wait for all subprocesses
        local i
        for i in "${!PIDS[@]}"
        do
            wait "${PIDS[$i]}"
        done

        # Derive PASS/FAIL/SKIP by examining only the new CSV rows
        echo ""
        printf "  [Iteration %d]  Results:\n" "$ITER"
        echo "  ----------------------------------------------------------"

        for i in "${!ITER_MODS[@]}"
        do
            MOD="${ITER_MODS[$i]}"
            local CSV="${MOD_CSV[$MOD]}"

            local P=0 F=0 S=0

            if [ -f "$CSV" ]
            then
                local TOTAL_ROWS=$(( $(wc -l < "$CSV") - 1 ))
                [ "$TOTAL_ROWS" -lt 0 ] && TOTAL_ROWS=0
                local NEW_ROWS=$(( TOTAL_ROWS - ${PRE_COUNT[$MOD]} ))
                [ "$NEW_ROWS" -lt 0 ] && NEW_ROWS=0

                if [ "$NEW_ROWS" -gt 0 ]
                then
                    local NEW_DATA
                    NEW_DATA=$(tail -n "$NEW_ROWS" "$CSV")
                    P=$(echo "$NEW_DATA" | grep -c ',"PASS",'    || true)
                    F=$(echo "$NEW_DATA" | grep -c ',"FAIL",'    || true)
                    S=$(echo "$NEW_DATA" | grep -c ',"SKIPPED",' || true)
                fi
            fi

            GRAND_PASS["$MOD"]=$(( ${GRAND_PASS["$MOD"]} + P ))
            GRAND_FAIL["$MOD"]=$(( ${GRAND_FAIL["$MOD"]} + F ))
            GRAND_SKIP["$MOD"]=$(( ${GRAND_SKIP["$MOD"]} + S ))

            printf "  %-25s  PASS: %d  FAIL: %d  SKIP: %d\n" \
                "$MOD" "$P" "$F" "$S"
        done

        # Delay before next iteration (interruptible)
        if (( $(date +%s) < END_TIME )) && [ "$_LOOP_INTERRUPTED" -eq 0 ]
        then
            printf "\n  Waiting %ds before next iteration...\n" "$DELAY"
            sleep "$DELAY" &
            wait $! 2>/dev/null || true
        fi
    done

    # Restore SIGINT to default before returning to the menu
    trap - SIGINT

    # Print summary only on clean (non-interrupted) exit
    [ "$_LOOP_INTERRUPTED" -eq 0 ] && _loop_summary
}

###############################################################################
# run_selection <module_list_array_name>
#
# Asks exec mode once for the whole selection, then:
#   Single mode -> runs modules sequentially, one by one
#   Loop mode   -> runs all modules in parallel each iteration
###############################################################################

run_selection()
{
    local -n _MODS="$1"
    local COUNT=${#_MODS[@]}

    local LABEL
    if [ "$COUNT" -eq 1 ]
    then
        LABEL="${_MODS[0]}"
    else
        LABEL="${COUNT} modules: ${_MODS[*]}"
    fi

    ask_exec_mode "$LABEL"

    if [ "$EXEC_MODE" = "loop" ]
    then
        ask_duration
    fi

    ask_output_options "${_MODS[@]}"

    # ------------------------------------------------------------------ #
    # Confirmation prompt — show exactly what will run before committing.
    # ------------------------------------------------------------------ #
    echo ""
    echo "  =========================================================="
    echo "  Confirm Execution"
    echo "  =========================================================="
    if [ "$COUNT" -eq 1 ]
    then
        printf "  Module    : %s\n" "${_MODS[0]}"
    else
        printf "  Modules   : %s\n" "${_MODS[*]}"
        printf "  Count     : %d\n" "$COUNT"
    fi
    if [ "$EXEC_MODE" = "loop" ]
    then
        printf "  Mode      : Loop (%ds / %d iterations est.)\n" \
            "$DURATION_SECS" "$(( DURATION_SECS / (ITER_DELAY_SECS + 1) ))"
        printf "  Delay     : %ds between iterations\n" "$ITER_DELAY_SECS"
    else
        printf "  Mode      : Single run\n"
    fi
    printf "  Logger    : %s\n" "$LOGGER_OUTPUT_MODE"
    printf "  Test log  : %s\n" "$TEST_LOG_OUTPUT_MODE"
    printf "  CSV       : %s\n" "$([ "$CSV_REPORT_ENABLE" -eq 1 ] && echo "enabled" || echo "disabled")"
    echo "  =========================================================="
    printf "  Proceed? [y/N]: "
    read -r _CONFIRM

    case "$_CONFIRM" in
        y|Y|yes|YES)
            ;;
        *)
            echo ""
            echo "  Cancelled. Returning to menu."
            echo ""
            printf "  Press [Enter] to return to the menu..."
            read -r
            return
            ;;
    esac

    # ------------------------------------------------------------------ #
    # Execute
    # ------------------------------------------------------------------ #
    if [ "$EXEC_MODE" = "loop" ]
    then
        interactive_run_loop "$DURATION_SECS" "${_MODS[@]}"
    else
        # Single mode - sequential, one module at a time
        local GRAND_PASS=0
        local GRAND_FAIL=0
        local GRAND_SKIP=0

        local MOD
        for MOD in "${_MODS[@]}"
        do
            PASS_COUNT=0
            FAIL_COUNT=0
            SKIP_COUNT=0

            interactive_run_module "$MOD"

            (( GRAND_PASS += PASS_COUNT ))
            (( GRAND_FAIL += FAIL_COUNT ))
            (( GRAND_SKIP += SKIP_COUNT ))
        done

        if [ "$COUNT" -gt 1 ]
        then
            echo ""
            echo "=========================================================================="
            printf "  COMBINED SUMMARY  (%d modules)\n" "$COUNT"
            echo "=========================================================================="
            printf "  Total PASS : %d\n" "$GRAND_PASS"
            printf "  Total FAIL : %d\n" "$GRAND_FAIL"
            printf "  Total SKIP : %d\n" "$GRAND_SKIP"
            echo "=========================================================================="
        fi
    fi

    echo ""
    printf "  Press [Enter] to return to the menu..."
    read -r
}

###############################################################################
# run_interactive_menu - main interactive loop
###############################################################################

run_interactive_menu()
{
    discover_menu_modules

    local TOTAL=${#MENU_MODULES[@]}
    local ALL_OPT=$(( TOTAL + 1 ))

    while true
    do
        print_main_menu
        read -r RAW_INPUT

        # ------------------------------------------------------------------ #
        # Parse the raw input into PARSED_NUMS[], HAS_ALL, HAS_INVALID
        # ------------------------------------------------------------------ #
        parse_selection "$RAW_INPUT"

        # Nothing entered
        if [ ${#PARSED_NUMS[@]} -eq 0 ]
        then
            echo ""
            echo "  [!] No selection entered. Please try again."
            sleep 1
            continue
        fi

        # Exit (0 anywhere in the input exits)
        local N
        for N in "${PARSED_NUMS[@]}"
        do
            if [ "$N" -eq 0 ]
            then
                echo ""
                echo "  Exiting. Goodbye!"
                echo ""
                exit 0
            fi
        done

        # Warn about invalid tokens but do not abort - just skip them
        if [ "$HAS_INVALID" -eq 1 ]
        then
            echo ""
            echo "  [!] Ignored invalid token(s):${INVALID_TOKENS}."
            # Remove invalid tokens - PARSED_NUMS already excludes them
        fi

        # Re-check: after stripping invalid tokens, is anything left?
        if [ ${#PARSED_NUMS[@]} -eq 0 ]
        then
            sleep 1
            continue
        fi

        # ------------------------------------------------------------------ #
        # Rule: "Run ALL" must be used alone.
        # If ALL_OPT is combined with other numbers, show a note.
        # ------------------------------------------------------------------ #
        if [ "$HAS_ALL" -eq 1 ] && [ ${#PARSED_NUMS[@]} -gt 1 ]
        then
            echo ""
            echo "  =========================================================="
            echo "  NOTE: 'Run ALL' is designed to run every module on its"
            echo "        own. Combining it with individual module numbers"
            echo "        does not make sense - it would run all modules"
            echo "        anyway, making the individual selections redundant."
            echo ""
            echo "  Please either:"
            echo "    - Enter  ${ALL_OPT}  alone  to run ALL modules, or"
            echo "    - Enter individual module numbers only."
            echo "  =========================================================="
            echo ""
            printf "  Press [Enter] to go back to the menu..."
            read -r
            continue
        fi

        # ------------------------------------------------------------------ #
        # "Run ALL" selected alone
        # ------------------------------------------------------------------ #
        if [ "$HAS_ALL" -eq 1 ]
        then
            run_selection MENU_MODULES
            continue
        fi

        # ------------------------------------------------------------------ #
        # One or more individual modules selected
        # ------------------------------------------------------------------ #
        local SELECTED_MODS=()
        for N in "${PARSED_NUMS[@]}"
        do
            local IDX=$(( N - 1 ))
            SELECTED_MODS+=("${MENU_MODULES[$IDX]}")
        done

        run_selection SELECTED_MODS

    done
}

###############################################################################
# - Framework Self-Check -------------------------- #
###############################################################################

framework_self_check

###############################################################################
# - Dispatch -------------------------------- #
#
# No arguments  ->  interactive menu
# Arguments     ->  original CLI path (parse -> initialize -> loop/single run)
###############################################################################

if [ $# -eq 0 ]
then
    # - Interactive mode -------------------------- #
    run_interactive_menu

else
    # - Direct CLI mode -------------------------- #

    parse_arguments "$@"

    initialize_framework

    # Determine loop mode (set by parse_arguments via parse_loop)
    if [ "$LOOP_MODE" -eq 1 ]
    then
        # ------------------------------------------------------------------ #
        # Loop mode — timed or infinite.
        #
        # LOOP_DURATION_SECS == 0  : infinite, stop on Ctrl+C
        # LOOP_DURATION_SECS  > 0  : timed, stop when duration expires
        #
        # Ctrl+C always prints a final summary before exiting.
        # ------------------------------------------------------------------ #

        local _CLI_ITER=0
        local _CLI_INTERRUPTED=0
        local _CLI_END_TIME=0

        if [ "$LOOP_DURATION_SECS" -gt 0 ]
        then
            _CLI_END_TIME=$(( $(date +%s) + LOOP_DURATION_SECS ))
            log_info "Loop mode : timed (${LOOP_DURATION_SECS}s)"
        else
            log_info "Loop mode : infinite (Ctrl+C to stop)"
        fi

        # Ctrl+C handler — print summary and exit
        _cli_loop_sigint()
        {
            echo ""
            echo ""
            log_info "Loop interrupted after ${_CLI_ITER} iteration(s)."
            print_summary
            trap - SIGINT
            _CLI_INTERRUPTED=1
        }
        trap '_cli_loop_sigint' SIGINT

        while [ "$_CLI_INTERRUPTED" -eq 0 ]
        do
            # Timed mode: check if duration has expired
            if [ "$LOOP_DURATION_SECS" -gt 0 ] && \
               (( $(date +%s) >= _CLI_END_TIME ))
            then
                break
            fi

            (( _CLI_ITER++ ))
            execute_validation
            sleep 2 & wait $! 2>/dev/null || true
        done

        trap - SIGINT

        # Print summary on clean (timed) exit; handler already printed on Ctrl+C
        if [ "$_CLI_INTERRUPTED" -eq 0 ]
        then
            log_info "Loop completed after ${_CLI_ITER} iteration(s)."
            print_summary
        fi
    else
        execute_validation
        print_summary
    fi

fi
