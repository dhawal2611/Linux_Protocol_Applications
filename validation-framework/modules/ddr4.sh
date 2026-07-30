#!/bin/bash
###############################################################################
# File        : ddr.sh
# Description : DDR Memory Validation Module
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="DDR"
MODULE_DESCRIPTION="DDR Memory Validation"

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    cat
    free
    grep
    awk
    dmesg
    memtester
    stress-ng
)
###############################################################################
# Helper Functions
###############################################################################

ddr_get_meminfo_value()
{
    local KEY="$1"

    echo "$COMMAND_OUTPUT" | awk -F':' -v key="$KEY" '
    {
        gsub(/^[ \t]+|[ \t]+$/, "", $1)
        gsub(/^[ \t]+|[ \t]+$/, "", $2)

        if ($1 == key)
        {
            print $2
            exit
        }
    }'
}

ddr_is_positive_integer()
{
    local VALUE="$1"

    case "$VALUE" in
        ''|*[!0-9]*)
            return 1
            ;;
    esac

    [ "$VALUE" -gt 0 ]
}

ddr_read_proc()
{
    local FILE="$1"

    [ -f "$FILE" ] || return 1

    cat "$FILE"
}

###############################################################################
# DDR Test Functions
###############################################################################

###############################################################################
# DDR-001 : Verify Total Memory
###############################################################################

ddr_001()
{
    local MEM_TOTAL=""

    log_info "[DDR-001] Verify Total Memory"

    run_command \
        "DDR-001" \
        "Verify Total Memory" \
        "cat /proc/meminfo"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to read /proc/meminfo."
        test_fail
        return
    fi

    MEM_TOTAL=$(ddr_get_meminfo_value "MemTotal")
    MEM_TOTAL=$(echo "$MEM_TOTAL" | awk '{print $1}')

    if ! ddr_is_positive_integer "$MEM_TOTAL"
    then
        TEST_MESSAGE="Invalid Total Memory."
        test_fail
        return
    fi

    TEST_MESSAGE="Total Memory=${MEM_TOTAL} kB"
    test_pass
}

###############################################################################
# DDR-002 : Verify Available Memory
###############################################################################

ddr_002()
{
    local MEM_AVAILABLE=""

    log_info "[DDR-002] Verify Available Memory"

    run_command \
        "DDR-002" \
        "Verify Available Memory" \
        "cat /proc/meminfo"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to read /proc/meminfo."
        test_fail
        return
    fi

    MEM_AVAILABLE=$(ddr_get_meminfo_value "MemAvailable")
    MEM_AVAILABLE=$(echo "$MEM_AVAILABLE" | awk '{print $1}')

    if ! ddr_is_positive_integer "$MEM_AVAILABLE"
    then
        TEST_MESSAGE="Invalid Available Memory."
        test_fail
        return
    fi

    TEST_MESSAGE="Available Memory=${MEM_AVAILABLE} kB"
    test_pass
}

###############################################################################
# DDR-003 : Verify Memory Information
###############################################################################

ddr_003()
{
    log_info "[DDR-003] Verify Memory Information"

    run_command \
        "DDR-003" \
        "Verify Memory Information" \
        "cat /proc/meminfo"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to read /proc/meminfo."
        test_fail
        return
    fi

    if echo "$COMMAND_OUTPUT" | grep -q "^MemTotal:" &&
       echo "$COMMAND_OUTPUT" | grep -q "^MemFree:" &&
       echo "$COMMAND_OUTPUT" | grep -q "^MemAvailable:"
    then
        TEST_MESSAGE="Required memory information found."
        test_pass
    else
        TEST_MESSAGE="Required memory fields missing."
        test_fail
    fi
}

###############################################################################
# DDR-004 : Verify Memory Usage
###############################################################################

ddr_004()
{
    log_info "[DDR-004] Verify Memory Usage"

    run_command \
        "DDR-004" \
        "Verify Memory Usage" \
        "free -h"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to execute free."
        test_fail
        return
    fi

    if echo "$COMMAND_OUTPUT" | grep -q "^Mem:"
    then
        TEST_MESSAGE="Memory usage information retrieved successfully."
        test_pass
    else
        TEST_MESSAGE="Memory usage information not available."
        test_fail
    fi
}

###############################################################################
# DDR-005 : Verify Memtester Availability
###############################################################################

ddr_005()
{
    log_info "[DDR-005] Verify Memtester Availability"

    run_command \
        "DDR-005" \
        "Verify Memtester Availability" \
        "command -v memtester"

    if [ "$COMMAND_STATUS" -eq 0 ]
    then
        TEST_MESSAGE="memtester is installed."
        test_pass
    else
        TEST_MESSAGE="memtester is not installed."
        test_skip
    fi
}

###############################################################################
# DDR-006 : Perform DDR Stress Test
###############################################################################

ddr_006()
{
    log_info "[DDR-006] Perform DDR Stress Test"

    run_command \
        "DDR-006" \
        "Perform DDR Stress Test" \
        "
        if command -v memtester >/dev/null 2>&1
        then
            memtester ${DDR_TEST_SIZE} ${DDR_TEST_ITERATION}
        else
            test_skip
            return
        fi
        "

    if [ "$COMMAND_STATUS" -eq 0 ] &&
       echo "$COMMAND_OUTPUT" | grep -q "Done."
    then
        TEST_MESSAGE="DDR stress test completed successfully."
        test_pass
    else
        TEST_MESSAGE="DDR stress test failed."
        test_fail
    fi
}

###############################################################################
# DDR-007 : Verify Kernel OOM Status
###############################################################################

ddr_007()
{
    log_info "[DDR-007] Verify Kernel OOM Status"

    run_command \
        "DDR-007" \
        "Verify Kernel OOM Status" \
        "dmesg | grep -Ei 'Out of memory|Killed process|oom'"
        #"dmesg | grep -i 'Out of memory\\|oom'"

    if [ "$COMMAND_STATUS" -eq 0 ]
    then
        TEST_MESSAGE="Kernel reported OOM events."
        test_fail
    else
        TEST_MESSAGE="No OOM events detected."
        test_pass
    fi
}

###############################################################################
# DDR-008 : Run Memory Stress Test using stress-ng
###############################################################################

ddr_008()
{
    log_info "[DDR-008] Run Memory Stress Test"

    if ! command -v stress-ng >/dev/null 2>&1
    then
        TEST_MESSAGE="stress-ng utility is not installed."
        test_skip
        return
    fi

    run_command \
        "DDR-008" \
        "Run Memory Stress Test" \
        "stress-ng --vm ${DDR_STRESS_VM} \
                   --vm-bytes ${DDR_STRESS_VM_BYTES} \
                   --timeout ${DDR_STRESS_TIMEOUT}"

    if [ "$COMMAND_STATUS" -eq 0 ]
    then
        TEST_MESSAGE="Memory stress test completed successfully."
        test_pass
    else
        TEST_MESSAGE="Memory stress test failed."
        test_fail
    fi
}

###############################################################################
# DDR-009 : Verify Memory Bandwidth using mbw
###############################################################################

ddr_009()
{
    log_info "[DDR-009] Verify Memory Bandwidth"

    if ! command -v mbw >/dev/null 2>&1
    then
        TEST_MESSAGE="mbw utility is not installed."
        test_skip
        return
    fi

    run_command \
        "DDR-009" \
        "Verify Memory Bandwidth" \
        "mbw ${DDR_MBW_SIZE}"

    if [ "$COMMAND_STATUS" -eq 0 ]
    then
        TEST_MESSAGE="Memory bandwidth test completed successfully."
        test_pass
    else
        TEST_MESSAGE="Memory bandwidth test failed."
        test_fail
    fi
}

###############################################################################
# DDR-010 : Verify Memory Utilization
###############################################################################

ddr_010()
{
    log_info "[DDR-010] Verify Memory Utilization"

    run_command \
        "DDR-010" \
        "Verify Memory Utilization" \
        "free -m"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to execute free."
        test_fail
        return
    fi

    TOTAL=$(echo "$COMMAND_OUTPUT" | awk '/^Mem:/ {print $2}')
    USED=$(echo "$COMMAND_OUTPUT" | awk '/^Mem:/ {print $3}')
    FREE=$(echo "$COMMAND_OUTPUT" | awk '/^Mem:/ {print $4}')

    if [ -z "$TOTAL" ] || [ -z "$USED" ]
    then
        TEST_MESSAGE="Unable to parse memory utilization."
        test_fail
        return
    fi

    TEST_MESSAGE="Total=${TOTAL}MB Used=${USED}MB Free=${FREE}MB"
    test_pass
}

###############################################################################
# Register DDR Tests
###############################################################################

ddr_register_tests()
{
    register_test \
        -i "DDR-001" \
        -f ddr_001 \
        -n "Verify Total Memory" \
        -c "basic" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "ddr,memory,meminfo" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify total installed DDR memory from /proc/meminfo."

    register_test \
        -i "DDR-002" \
        -f ddr_002 \
        -n "Verify Available Memory" \
        -c "basic" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "ddr,memory,available" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify available system memory."

    register_test \
        -i "DDR-003" \
        -f ddr_003 \
        -n "Verify Memory Information" \
        -c "basic" \
        -t "auto" \
        -p "medium" \
        -o 10 \
        -g "ddr,meminfo,proc" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify required fields in /proc/meminfo."

    register_test \
        -i "DDR-004" \
        -f ddr_004 \
        -n "Verify Memory Usage" \
        -c "performance" \
        -t "auto" \
        -p "medium" \
        -o 10 \
        -g "ddr,free,memory" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify current memory usage."

    register_test \
        -i "DDR-005" \
        -f ddr_005 \
        -n "Verify Memtester Availability" \
        -c "diagnostic" \
        -t "auto" \
        -p "low" \
        -o 5 \
        -g "ddr,memtester" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify memtester utility availability."

    register_test \
        -i "DDR-006" \
        -f ddr_006 \
        -n "Perform DDR Stress Test" \
        -c "stress" \
        -t "auto" \
        -p "high" \
        -o 300 \
        -g "ddr,stress,memtester" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Execute configurable DDR stress test using memtester."

    register_test \
        -i "DDR-007" \
        -f ddr_007 \
        -n "Verify Kernel OOM Status" \
        -c "diagnostic" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "ddr,oom,dmesg" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify kernel Out-Of-Memory status after DDR validation."
    register_test \
        -i "DDR-008" \
        -f ddr_008 \
        -n "Run Memory Stress Test" \
        -c "stress" \
        -t "auto" \
        -p "high" \
        -o 320 \
        -g "ddr,stress,stress-ng" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Run stress-ng memory workload to validate DDR stability."

    register_test \
        -i "DDR-009" \
        -f ddr_009 \
        -n "Verify Memory Bandwidth" \
        -c "performance" \
        -t "auto" \
        -p "medium" \
        -o 120 \
        -g "ddr,bandwidth,mbw" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure DDR memory bandwidth using mbw."

    register_test \
        -i "DDR-010" \
        -f ddr_010 \
        -n "Verify Memory Utilization" \
        -c "performance" \
        -t "auto" \
        -p "low" \
        -o 10 \
        -g "ddr,memory,free" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify current DDR memory utilization."
}

###############################################################################
# Module Initialization / Execution Scope Hooks
###############################################################################

ddr_init()
{
    #
    # Clear previous test registry
    #
    clear_test_registry

    #
    # Register DDR Tests
    #
    ddr_register_tests
}

#
# Trigger initialization globally when framework sources the module file
#
ddr_init

###############################################################################
# End Of File
###############################################################################
