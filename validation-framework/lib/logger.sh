#!/bin/bash
###############################################################################
# File        : logger.sh
# Description : Logging Library
###############################################################################

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"

PASS_COUNT=0
FAIL_COUNT=0

###############################################################################
# Write Test Logs
###############################################################################

write_test_log()
{
    local DATA="$1"

    case "$TEST_LOG_OUTPUT_MODE" in

        console)
            printf "%s\n" "$DATA"
            ;;

        file)
            printf "%s\n" "$DATA" >> "$LOG_FILE"
            ;;

        both)
            printf "%s\n" "$DATA" | tee -a "$LOG_FILE" >/dev/null
            ;;

        none)
            ;;

    esac
}

###############################################################################
# Internal Logger
###############################################################################

write_log()
{
    local TYPE="$1"
    local MESSAGE="$2"

    case "$LOGGER_OUTPUT_MODE" in

        console)

            case "$TYPE" in
                INFO) echo -e "${BLUE}[INFO]${NC} $MESSAGE" ;;
                PASS) echo -e "${GREEN}[PASS]${NC} $MESSAGE" ;;
                FAIL) echo -e "${RED}[FAIL]${NC} $MESSAGE" ;;
                WARN) echo -e "${YELLOW}[WARN]${NC} $MESSAGE" ;;
            esac
            ;;

        file)

            echo "[$TYPE] $MESSAGE" >> "$LOG_FILE"
            ;;

        both)

            case "$TYPE" in
                INFO) echo -e "${BLUE}[INFO]${NC} $MESSAGE" ;;
                PASS) echo -e "${GREEN}[PASS]${NC} $MESSAGE" ;;
                FAIL) echo -e "${RED}[FAIL]${NC} $MESSAGE" ;;
                WARN) echo -e "${YELLOW}[WARN]${NC} $MESSAGE" ;;
            esac

            echo "[$TYPE] $MESSAGE" >> "$LOG_FILE"
            ;;
    esac
}
###############################################################################
# Public APIs
###############################################################################

log_info()
{
    write_log INFO "$1"
}

log_pass()
{
    write_log PASS "$1"
    PASS_COUNT=$((PASS_COUNT+1))
}

log_fail()
{
    write_log FAIL "$1"
    FAIL_COUNT=$((FAIL_COUNT+1))
}

log_warn()
{
    write_log WARN "$1"
}

###############################################################################
# Summary
###############################################################################

print_summary()
{
    echo
    echo "=========================="
    echo "PASS : $PASS_COUNT"
    echo "FAIL : $FAIL_COUNT"
    echo "Log  : $LOG_FILE"
    echo "=========================="
}
