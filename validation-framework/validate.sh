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
# Displays the two-column module list.
# SELECTED_NUMS[] is an array of 1-based numbers already chosen in this
# session; chosen entries are marked with [*] so the user can track picks.
###############################################################################

print_main_menu()
{
    local TOTAL=${#MENU_MODULES[@]}
    local ALL_OPT=$(( TOTAL + 1 ))

    #clear
    echo "=========================================================================="
    echo "            EMBEDDED LINUX VALIDATION - TEST MENU"
    echo "=========================================================================="

    local HALF=$(( (TOTAL + 1) / 2 ))
    local i
    for (( i=0; i<HALF; i++ ))
    do
        local L=$i
        local R=$(( i + HALF ))
        local LN=$(( L + 1 ))
        local LV="${MENU_MODULES[$L]}"

        if (( R < TOTAL ))
        then
            local RN=$(( R + 1 ))
            local RV="${MENU_MODULES[$R]}"
            printf "  %2d. %-28s  %2d. %s\n" "$LN" "$LV" "$RN" "$RV"
        else
            printf "  %2d. %s\n" "$LN" "$LV"
        fi
    done

    echo "--------------------------------------------------------------------------"
    printf "  %2d. Run ALL modules  (runs individually, select alone)\n" "$ALL_OPT"
    echo "--------------------------------------------------------------------------"
    echo "   0. Exit"
    echo "=========================================================================="
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
    # csv_create_header() is called by setup_log_files inside the subprocess;
    # the [ -s ] guard ensures the header is written only once.
    declare -A MOD_CSV
    local MOD
    for MOD in "${MODS[@]}"
    do
        MOD_CSV["$MOD"]="${LOG_DIR}/validation_${SESSION_TS}_${MOD}_loop.csv"
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
    echo "  Ctrl+C to stop early"
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

    while (( $(date +%s) < END_TIME ))
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
                    # Read only the new rows (skip header + previously existing rows)
                    local SKIP_LINES=$(( ${PRE_COUNT[$MOD]} + 1 ))
                    local NEW_DATA
                    NEW_DATA=$(tail -n "$NEW_ROWS" "$CSV")
                    P=$(echo "$NEW_DATA" | grep -c ',"PASS",'  || true)
                    F=$(echo "$NEW_DATA" | grep -c ',"FAIL",'  || true)
                    S=$(echo "$NEW_DATA" | grep -c ',"SKIPPED",' || true)
                fi
            fi

            GRAND_PASS["$MOD"]=$(( ${GRAND_PASS["$MOD"]} + P ))
            GRAND_FAIL["$MOD"]=$(( ${GRAND_FAIL["$MOD"]} + F ))
            GRAND_SKIP["$MOD"]=$(( ${GRAND_SKIP["$MOD"]} + S ))

            printf "  %-25s  PASS: %d  FAIL: %d  SKIP: %d\n" \
                "$MOD" "$P" "$F" "$S"
        done

        # Delay before next iteration
        if (( $(date +%s) < END_TIME ))
        then
            printf "\n  Waiting %ds before next iteration...\n" "$DELAY"
            sleep "$DELAY"
        fi
    done

    # Final summary
    echo ""
    echo "=========================================================================="
    printf "  LOOP SUMMARY  (%d iteration(s), %d module(s))\n" "$ITER" "$MOD_COUNT"
    echo "=========================================================================="
    local TOTAL_P=0 TOTAL_F=0 TOTAL_S=0
    for MOD in "${MODS[@]}"
    do
        printf "  %-25s  PASS: %d  FAIL: %d  SKIP: %d\n" \
            "$MOD" "${GRAND_PASS[$MOD]}" "${GRAND_FAIL[$MOD]}" "${GRAND_SKIP[$MOD]}"
        (( TOTAL_P += GRAND_PASS[$MOD] ))
        (( TOTAL_F += GRAND_FAIL[$MOD] ))
        (( TOTAL_S += GRAND_SKIP[$MOD] ))
    done
    echo "  ----------------------------------------------------------"
    printf "  %-25s  PASS: %d  FAIL: %d  SKIP: %d\n" \
        "TOTAL" "$TOTAL_P" "$TOTAL_F" "$TOTAL_S"
    echo ""
    echo "  CSV report(s):"
    for MOD in "${MODS[@]}"
    do
        printf "  %-25s  %s\n" "$MOD" "${MOD_CSV[$MOD]}"
    done
    echo "=========================================================================="
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
        # Pass duration + all module names to the unified loop function
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
        while true
        do
            execute_validation
            sleep 2
        done
    else
        execute_validation
        print_summary
    fi

fi
