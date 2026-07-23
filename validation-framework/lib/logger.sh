#!/bin/bash

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"

PASS_COUNT=0
FAIL_COUNT=0

log_info()
{
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

log_pass()
{
    echo -e "${GREEN}[PASS]${NC} $1"
    echo "[PASS] $1" >> "$LOG_FILE"

    PASS_COUNT=$((PASS_COUNT+1))
}

log_fail()
{
    echo -e "${RED}[FAIL]${NC} $1"
    echo "[FAIL] $1" >> "$LOG_FILE"

    FAIL_COUNT=$((FAIL_COUNT+1))
}

print_summary()
{
    echo
    echo "=========================="
    echo "PASS : $PASS_COUNT"
    echo "FAIL : $FAIL_COUNT"
    echo "Log  : $LOG_FILE"
    echo "=========================="
}
