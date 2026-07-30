#!/bin/bash
###############################################################################
# File : thermal.sh
# Description : Thermal Validation Module
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="THERMAL"
MODULE_DESCRIPTION="Thermal Sensor Validation"

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
 cat
 ls
 find
)

###############################################################################
# Helper Functions
###############################################################################

thermal_read_sysfs()
{
 local FILE="$1"

 if [ -f "$FILE" ]
 then
 cat "$FILE"
 return 0
 fi

 return 1
}

thermal_read_temperature()
{
 local FILE="$1"

 if [ -f "$FILE" ]
 then
 awk '{ printf "%.1f°C\n", $1/1000 }' "$FILE"
 return 0
 fi

 return 1
}

###############################################################################
# Get Primary Thermal Zone
###############################################################################

get_primary_thermal_zone()
{
 local ZONE

 for ZONE in /sys/class/thermal/thermal_zone*
 do
 if [ -d "$ZONE" ]
 then
 echo "$ZONE"
 return 0
 fi
 done

 return 1
}

###############################################################################
# Thermal Test Functions
###############################################################################

###############################################################################
# THERMAL-001 : Verify Thermal Zones
###############################################################################

thermal_001()
{
 run_command \
 "THERMAL-001" \
 "Verify Thermal Zones" \
 "find /sys/class/thermal -maxdepth 1 -type l -name 'thermal_zone*'"

 if [ "$COMMAND_STATUS" -eq 0 ] && [ -n "$COMMAND_OUTPUT" ]
 then
 TEST_RESULT="PASS"
 TEST_MESSAGE="Thermal zone(s) detected."
 test_pass "THERMAL-001"
 else
 TEST_RESULT="FAIL"
 TEST_MESSAGE="No thermal zones found."
 test_fail "THERMAL-001"
 fi
}

###############################################################################
# THERMAL-002 : Verify CPU Temperature
###############################################################################

thermal_002()
{
 run_command \
 "THERMAL-002" \
 "Verify CPU Temperature" \
 "thermal_read_temperature ${ZONE}/temp"

 if [ "$COMMAND_STATUS" -eq 0 ] && [[ "$COMMAND_OUTPUT" == *"°C"* ]]
 then
 TEST_RESULT="PASS"
 TEST_MESSAGE="CPU temperature read successfully."
 test_pass "THERMAL-002"
 else
 TEST_RESULT="FAIL"
 TEST_MESSAGE="Unable to read CPU temperature."
 test_fail "THERMAL-002"
 fi
}

###############################################################################
# THERMAL-003 : Verify Thermal Zone Type
###############################################################################

thermal_003()
{
 run_command \
 "THERMAL-003" \
 "Verify Thermal Zone Type" \
 "thermal_read_sysfs ${ZONE}/type"

 if [ "$COMMAND_STATUS" -eq 0 ] && [ -n "$COMMAND_OUTPUT" ]
 then
 TEST_RESULT="PASS"
 TEST_MESSAGE="Thermal zone type detected."
 test_pass "THERMAL-003"
 else
 TEST_RESULT="FAIL"
 TEST_MESSAGE="Thermal zone type not available."
 test_fail "THERMAL-003"
 fi
}

###############################################################################
# THERMAL-004 : Verify Thermal Trip Points
###############################################################################

thermal_004()
{
 local ZONE

 ZONE=$(get_primary_thermal_zone)

 run_command \
 "THERMAL-004" \
 "Verify Thermal Trip Points" \
 "find ${ZONE} -maxdepth 1 -name 'trip_point_*_temp' -exec cat {} \;"

 if [ "$COMMAND_STATUS" -eq 0 ] && [ -n "$COMMAND_OUTPUT" ]
 then
 TEST_RESULT="PASS"
 TEST_MESSAGE="Thermal trip points are available."
 test_pass "THERMAL-004"
 else
 TEST_RESULT="FAIL"
 TEST_MESSAGE="Thermal trip points not found."
 test_fail "THERMAL-004"
 fi
}

###############################################################################
# THERMAL-005 : Verify Cooling Devices
###############################################################################

thermal_005()
{
 run_command \
 "THERMAL-005" \
 "Verify Cooling Devices" \
 "find /sys/class/thermal -maxdepth 1 -type l -name 'cooling_device*'"

 if [ "$COMMAND_STATUS" -eq 0 ] && [ -n "$COMMAND_OUTPUT" ]
 then
 TEST_RESULT="PASS"
 TEST_MESSAGE="Cooling device(s) detected."
 test_pass "THERMAL-005"
 else
 TEST_RESULT="FAIL"
 TEST_MESSAGE="Cooling devices not found."
 test_fail "THERMAL-005"
 fi
}

###############################################################################
# THERMAL-006 : Verify Thermal Sensor Readability
###############################################################################

thermal_006()
{
 local ZONE

 ZONE=$(get_primary_thermal_zone)

 run_command \
 "THERMAL-006" \
 "Verify Thermal Sensor Readability" \
 "cat ${ZONE}/temp"

 if [ "$COMMAND_STATUS" -eq 0 ] && [[ "$COMMAND_OUTPUT" =~ ^[0-9]+$ ]]
 then
 TEST_RESULT="PASS"
 TEST_MESSAGE="Thermal sensor is readable."
 test_pass "THERMAL-006"
 else
 TEST_RESULT="FAIL"
 TEST_MESSAGE="Thermal sensor is not readable."
 test_fail "THERMAL-006"
 fi
}

###############################################################################
# THERMAL-007 : Verify Temperature During CPU Load
###############################################################################

thermal_007()
{
 local ZONE

 ZONE=$(get_primary_thermal_zone)

 run_command \
 "THERMAL-007" \
 "Verify Temperature During CPU Load" \
 "
 if command -v stress-ng >/dev/null 2>&1
 then
 BEFORE=\$(cat ${ZONE}/temp)
 stress-ng --cpu \"\$THERMAL_STRESS_CPU\" --timeout \"\$THERMAL_STRESS_DURATION\" >/dev/null 2>&1
 AFTER=\$(cat ${ZONE}/temp)
 echo \"Before=\${BEFORE}\"
 echo \"After=\${AFTER}\"
 else
 echo 'stress-ng not installed'
 exit 1
 fi
 "

 if [ "$COMMAND_STATUS" -eq 0 ] && \
 echo "$COMMAND_OUTPUT" | grep -q "Before="
 then
 TEST_RESULT="PASS"
 TEST_MESSAGE="Temperature monitored successfully during CPU load."
 test_pass "THERMAL-007"
 else
 TEST_RESULT="FAIL"
 TEST_MESSAGE="Unable to monitor temperature during CPU load."
 test_fail "THERMAL-007"
 fi
}

###############################################################################
# Register Thermal Tests
###############################################################################

thermal_register_tests()
{
 register_test \
 --id "THERMAL-001" \
 --function thermal_001 \
 --name "Verify Thermal Zones" \
 --category "hardware" \
 --type "auto" \
 --priority "high" \
 --timeout 10 \
 --tags "thermal,zone" \
 --owner "Embedded Team" \
 --board "Generic Linux" \
 --enabled "yes"

 register_test \
 --id "THERMAL-002" \
 --function thermal_002 \
 --name "Verify CPU Temperature" \
 --category "hardware" \
 --type "auto" \
 --priority "high" \
 --timeout 10 \
 --tags "thermal,cpu,temp" \
 --owner "Embedded Team" \
 --board "Generic Linux" \
 --enabled "yes"

 register_test \
 --id "THERMAL-003" \
 --function thermal_003 \
 --name "Verify Thermal Zone Type" \
 --category "hardware" \
 --type "auto" \
 --priority "medium" \
 --timeout 10 \
 --tags "thermal,type" \
 --owner "Embedded Team" \
 --board "Generic Linux" \
 --enabled "yes"

 register_test \
 --id "THERMAL-004" \
 --function thermal_004 \
 --name "Verify Thermal Trip Points" \
 --category "hardware" \
 --type "auto" \
 --priority "medium" \
 --timeout 10 \
 --tags "thermal,trip" \
 --owner "Embedded Team" \
 --board "Generic Linux" \
 --enabled "yes"

 register_test \
 --id "THERMAL-005" \
 --function thermal_005 \
 --name "Verify Cooling Devices" \
 --category "hardware" \
 --type "auto" \
 --priority "medium" \
 --timeout 10 \
 --tags "thermal,cooling" \
 --owner "Embedded Team" \
 --board "Generic Linux" \
 --enabled "yes"

 register_test \
 --id "THERMAL-006" \
 --function thermal_006 \
 --name "Verify Thermal Sensor Readability" \
 --category "hardware" \
 --type "auto" \
 --priority "medium" \
 --timeout 10 \
 --tags "thermal,sensor" \
 --owner "Embedded Team" \
 --board "Generic Linux" \
 --enabled "yes"

 register_test \
 --id "THERMAL-007" \
 --function thermal_007 \
 --name "Verify Temperature During CPU Load" \
 --category "hardware" \
 --type "auto" \
 --priority "low" \
 --timeout 120 \
 --tags "thermal,stress" \
 --owner "Embedded Team" \
 --board "Generic Linux" \
 --enabled "yes"
}

###############################################################################
# Module Initialization / Execution Scope Hooks
###############################################################################

thermal_init()
{
 # Register tests into core framework structure
 clear_test_registry
 thermal_register_tests
}

# Trigger module initialization safely when the core framework targets this file
thermal_init

###############################################################################
# End Of File
###############################################################################
