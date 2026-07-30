#!/bin/bash
###############################################################################
# File : cpu.sh
# Description : CPU Validation Module
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="CPU"
MODULE_DESCRIPTION="CPU Validation"

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
 lscpu
 cat
 grep
 awk
 tr
)

###############################################################################
# Helper Functions
###############################################################################

# Read a value from lscpu output.
cpu_get_lscpu_value()
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

# Read a value from /proc/cpuinfo.
cpu_get_cpuinfo_value()
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

# Check whether a value is a positive integer.
cpu_is_positive_integer()
{
 local VALUE="$1"

 case "$VALUE" in
 ''|*[!0-9]*)
 return 1
 ;;
 esac

 [ "$VALUE" -gt 0 ]
}

# Read cpu sysfs.
cpu_read_sysfs()
{
 local FILE="$1"

 if [ ! -f "$FILE" ]
 then
 return 1
 fi

 cat "$FILE"
}

###############################################################################
# CPU Test Functions
###############################################################################

# CPU-001: Verify CPU Architecture and Cores
cpu_001()
{
 local ARCHITECTURE=""
 local CPU_COUNT=""
 local CORE_COUNT=""

 log_info "[CPU-001] Verify CPU Architecture and Cores"

 run_command \
 "CPU-001" \
 "Verify CPU Architecture and Cores" \
 "lscpu"

 if [ "$COMMAND_STATUS" -ne 0 ]
 then
 TEST_MESSAGE="Failed to execute lscpu."
 test_fail
 return
 fi

 ARCHITECTURE=$(cpu_get_lscpu_value "Architecture")
 CPU_COUNT=$(cpu_get_lscpu_value "CPU(s)")
 CORE_COUNT=$(cpu_get_lscpu_value "Core(s) per socket")

 if [ -z "$ARCHITECTURE" ]
 then
 TEST_MESSAGE="CPU Architecture not found."
 test_fail
 return
 fi

 if ! cpu_is_positive_integer "$CPU_COUNT"
 then
 TEST_MESSAGE="Invalid CPU Count."
 test_fail
 return
 fi

 if ! cpu_is_positive_integer "$CORE_COUNT"
 then
 TEST_MESSAGE="Invalid Core Count."
 test_fail
 return
 fi

 TEST_MESSAGE="Architecture=${ARCHITECTURE}, CPUs=${CPU_COUNT}, Cores/Socket=${CORE_COUNT}"
 test_pass
}

# CPU-002: Verify CPU Information
cpu_002()
{
 local PROCESSOR_COUNT=""
 local CPU_MODEL=""
 local CPU_HARDWARE=""

 log_info "[CPU-002] Verify CPU Information"

 run_command \
 "CPU-002" \
 "Verify CPU Information" \
 "cat /proc/cpuinfo"

 if [ "$COMMAND_STATUS" -ne 0 ]
 then
 TEST_MESSAGE="Failed to read /proc/cpuinfo."
 test_fail
 return
 fi

 PROCESSOR_COUNT=$(echo "$COMMAND_OUTPUT" | grep -c "^processor")
 CPU_MODEL=$(cpu_get_cpuinfo_value "model name")
 CPU_HARDWARE=$(cpu_get_cpuinfo_value "Hardware")

 if ! cpu_is_positive_integer "$PROCESSOR_COUNT"
 then
 TEST_MESSAGE="Invalid Processor Count."
 test_fail
 return
 fi

 if [ -n "$CPU_MODEL" ]
 then
 TEST_MESSAGE="Processors=${PROCESSOR_COUNT}, Model=${CPU_MODEL}"
 test_pass
 return
 fi

 if [ -n "$CPU_HARDWARE" ]
 then
 TEST_MESSAGE="Processors=${PROCESSOR_COUNT}, Hardware=${CPU_HARDWARE}"
 test_pass
 return
 fi

 TEST_MESSAGE="CPU Model Information Not Found."
 test_fail
}

# CPU-003: Verify Online CPUs
cpu_003()
{
 local ONLINE_CPUS=""

 log_info "[CPU-003] Verify Online CPUs"

 run_command \
 "CPU-003" \
 "Verify Online CPUs" \
 "cpu_read_sysfs /sys/devices/system/cpu/online"

 if [ "$COMMAND_STATUS" -ne 0 ]
 then
 TEST_MESSAGE="Failed to read online CPU information."
 test_fail
 return
 fi

 ONLINE_CPUS=$(echo "$COMMAND_OUTPUT" | tr -d '[:space:]')

 if [ -z "$ONLINE_CPUS" ]
 then
 TEST_MESSAGE="Online CPU list is empty."
 test_fail
 return
 fi

 if ! echo "$ONLINE_CPUS" | grep -Eq '^[0-9]+([,-][0-9]+)*(-[0-9]+([,-][0-9]+)*)?$|^[0-9]+(-[0-9]+)?(,[0-9]+(-[0-9]+)?)*$'
 then
 TEST_MESSAGE="Invalid Online CPU Format : ${ONLINE_CPUS}"
 test_fail
 return
 fi

 TEST_MESSAGE="Online CPUs=${ONLINE_CPUS}"
 test_pass
}

# CPU-004: Verify CPU Governor
cpu_004()
{
 local GOVERNOR=""
 local GOVERNOR_FILE="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"

 log_info "[CPU-004] Verify CPU Governor"

 if ! [ -f "$GOVERNOR_FILE" ] 
 then
 TEST_MESSAGE="CPU Governor interface not available."
 test_fail
 return
 fi

 run_command \
 "CPU-004" \
 "Verify CPU Governor" \
 "cpu_read_sysfs ${GOVERNOR_FILE}"

 if [ "$COMMAND_STATUS" -ne 0 ]
 then
 TEST_MESSAGE="Failed to read CPU Governor."
 test_fail
 return
 fi

 GOVERNOR=$(echo "$COMMAND_OUTPUT" | tr -d '[:space:]')

 case "$GOVERNOR" in

 performance|powersave|ondemand|schedutil|userspace|conservative)
 TEST_MESSAGE="Governor=${GOVERNOR}"
 test_pass
 ;;
 *)
 TEST_MESSAGE="Unsupported Governor=${GOVERNOR}"
 test_fail
 ;;
 esac
}

###############################################################################
# Register CPU Tests
###############################################################################

cpu_register_tests()
{
 register_test \
 -i "CPU-001" \
 -f cpu_001 \
 -n "Verify CPU Architecture and Cores" \
 -c "basic" \
 -t "auto" \
 -p "high" \
 -o 10 \
 -g "cpu,lscpu,architecture" \
 -w "Embedded Team" \
 -b "All" \
 -e "yes" \
 -d "Verify CPU architecture, logical CPU count and core count using lscpu."

 register_test \
 -i "CPU-002" \
 -f cpu_002 \
 -n "Verify CPU Information" \
 -c "basic" \
 -t "auto" \
 -p "high" \
 -o 10 \
 -g "cpu,cpuinfo,proc" \
 -w "Embedded Team" \
 -b "All" \
 -e "yes" \
 -d "Verify CPU information using /proc/cpuinfo."

 register_test \
 -i "CPU-003" \
 -f cpu_003 \
 -n "Verify Online CPUs" \
 -c "basic" \
 -t "auto" \
 -p "medium" \
 -o 5 \
 -g "cpu,online" \
 -w "Embedded Team" \
 -b "Linux" \
 -e "yes" \
 -d "Verify online CPU list from Linux sysfs."

 register_test \
 -i "CPU-004" \
 -f cpu_004 \
 -n "Verify CPU Governor" \
 -c "performance" \
 -t "auto" \
 -p "medium" \
 -o 5 \
 -g "cpu,governor,cpufreq" \
 -w "Embedded Team" \
 -b "Linux cpufreq" \
 -e "yes" \
 -d "Verify CPU frequency scaling governor."
}

###############################################################################
# Module Initialization / Execution Scope Hooks
###############################################################################

cpu_init()
{
 clear_test_registry
 cpu_register_tests
}

# Trigger initialization globally when framework sources the module file
cpu_init

###############################################################################
# End Of File
###############################################################################
