#!/bin/bash

###############################################################################
# File        : emmc.sh
# Description : eMMC Storage Validation Module
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="EMMC"
MODULE_DESCRIPTION="eMMC Storage Validation"

###############################################################################
# Runtime Variables
###############################################################################

EMMC_MOUNTPOINT=""
EMMC_DEVICE_PARTITION=""
EMMC_MOUNTED_BY_TEST=0

EMMC_TEST_DIR=""
EMMC_TEST_FILE=""

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    lsblk
    blkid
    df
    findmnt
    mount
    umount
    mkdir
    touch
    cat
    rm
    dd
    sync
    grep
    awk
    sed
    tr
    mmc
)

###############################################################################
# Helper Functions
###############################################################################

#
# Check whether configured eMMC device exists
#
emmc_device_exists()
{
    [ -b "$EMMC_DEVICE" ]
}

###############################################################################

#
# Get eMMC device name
#
emmc_get_device_name()
{
    lsblk -dn -o NAME "$EMMC_DEVICE"
}

###############################################################################

#
# Get eMMC device size
#
emmc_get_size()
{
    lsblk -dn -o SIZE "$EMMC_DEVICE"
}

###############################################################################

#
# Get eMMC device type
#
emmc_get_type()
{
    lsblk -dn -o TYPE "$EMMC_DEVICE"
}

###############################################################################

#
# Get eMMC filesystem type
#
emmc_get_filesystem()
{
    blkid -o value -s TYPE "$EMMC_DEVICE" 2>/dev/null
}

###############################################################################

#
# Get eMMC model
#
emmc_get_model()
{
    lsblk -dn -o MODEL "$EMMC_DEVICE"
}

###############################################################################

#
# Find filesystem-bearing device.
#
# If the configured device itself contains a filesystem, use it.
# Otherwise find the first child partition containing a filesystem.
#
emmc_get_filesystem_device()
{
    local DEVICE="$EMMC_DEVICE"

    if blkid -o value -s TYPE "$DEVICE" 2>/dev/null | grep -q .
    then
        echo "$DEVICE"
        return 0
    fi

    lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICE" 2>/dev/null |
        awk '$3 != "" {print "/dev/" $1; exit}'
}

###############################################################################

#
# Get current eMMC mount point
#
emmc_get_mountpoint()
{
    if [ -n "$EMMC_MOUNTPOINT" ]
    then
        echo "$EMMC_MOUNTPOINT"
        return 0
    fi

    local DEVICE

    DEVICE=$(emmc_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    findmnt -n -S "$DEVICE" -o TARGET 2>/dev/null
}

###############################################################################

#
# Get mount options
#
emmc_get_mount_options()
{
    local MOUNTPOINT="$1"

    if [ -z "$MOUNTPOINT" ]
    then
        return 1
    fi

    findmnt -n -T "$MOUNTPOINT" -o OPTIONS 2>/dev/null
}

###############################################################################

#
# Check whether eMMC filesystem is mounted
#
emmc_is_mounted()
{
    local DEVICE

    DEVICE=$(emmc_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    findmnt -n -S "$DEVICE" >/dev/null 2>&1
}

###############################################################################

#
# Check whether filesystem is mounted read-write
#
emmc_is_rw()
{
    local MOUNTPOINT="$1"
    local OPTIONS

    if [ -z "$MOUNTPOINT" ]
    then
        return 1
    fi

    OPTIONS=$(emmc_get_mount_options "$MOUNTPOINT")

    echo "$OPTIONS" | grep -qw rw
}

###############################################################################

#
# Create eMMC test directory
#
emmc_create_test_directory()
{
    if [ -z "$EMMC_MOUNTPOINT" ]
    then
        return 1
    fi

    EMMC_TEST_DIR="${EMMC_MOUNTPOINT}/emmc_validation"

    mkdir -p "$EMMC_TEST_DIR"
}

###############################################################################

#
# Remove eMMC test directory
#
emmc_remove_test_directory()
{
    if [ -z "$EMMC_TEST_DIR" ]
    then
        return 0
    fi

    rm -rf "$EMMC_TEST_DIR"
}

###############################################################################

#
# Get standard eMMC test file
#
emmc_get_test_file()
{
    if [ -z "$EMMC_TEST_DIR" ]
    then
        return 1
    fi

    EMMC_TEST_FILE="${EMMC_TEST_DIR}/emmc_test.bin"

    echo "$EMMC_TEST_FILE"
}

###############################################################################

#
# Reset runtime state
#
emmc_reset_runtime()
{
    EMMC_MOUNTPOINT=""
    EMMC_DEVICE_PARTITION=""
    EMMC_MOUNTED_BY_TEST=0
    EMMC_TEST_DIR=""
    EMMC_TEST_FILE=""
}

###############################################################################

#
# Mount emmc
#
emmc_mount_for_test()
{
    local DEVICE
    local FS_TYPE
    local MOUNT_DEVICE
    local EXISTING_MOUNT
    local MOUNTPOINT

    DEVICE="$EMMC_DEVICE"

    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null || true)

    if [ -n "$FS_TYPE" ]
    then
        MOUNT_DEVICE="$DEVICE"
    else
        MOUNT_DEVICE=$(lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICE" 2>/dev/null |
            awk '$3 != "" {print "/dev/" $1; exit}')
    fi

    if [ -z "$MOUNT_DEVICE" ]
    then
        echo "ERROR=No filesystem-bearing eMMC device found."
        return 2
    fi

    EXISTING_MOUNT=$(findmnt -n -S "$MOUNT_DEVICE" -o TARGET 2>/dev/null || true)

    if [ -n "$EXISTING_MOUNT" ]
    then
        MOUNTPOINT="$EXISTING_MOUNT"

        echo "MOUNT_DEVICE=$MOUNT_DEVICE"
        echo "MOUNTPOINT=$MOUNTPOINT"
        echo "MOUNTED_BY_TEST=0"

        return 0
    fi

    MOUNTPOINT="${EMMC_MOUNTPOINT:-/mnt/emmc_validation}"

    mkdir -p "$MOUNTPOINT"

    if ! mount "$MOUNT_DEVICE" "$MOUNTPOINT"
    then
        echo "ERROR=Failed to mount $MOUNT_DEVICE on $MOUNTPOINT"
        return 1
    fi

    echo "MOUNT_DEVICE=$MOUNT_DEVICE"
    echo "MOUNTPOINT=$MOUNTPOINT"
    echo "MOUNTED_BY_TEST=1"
}


###############################################################################
# EMMC-001 : Detect & Verify eMMC Device
###############################################################################

emmc_001()
{
    local DEVICE_NAME=""
    local SIZE=""
    local TYPE=""
    local FSTYPE=""
    local MODEL=""

    log_info "[EMMC-001] Detect & Verify eMMC Device"

    run_command \
        "EMMC-001" \
        "Detect & Verify eMMC Device" \
        "lsblk -dn -o NAME,SIZE,TYPE,FSTYPE,MODEL \"$EMMC_DEVICE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to detect eMMC device ${EMMC_DEVICE}."
        test_fail
        return
    fi

    DEVICE_NAME=$(echo "$COMMAND_OUTPUT" | awk 'NR==1 {print $1}')
    SIZE=$(echo "$COMMAND_OUTPUT" | awk 'NR==1 {print $2}')
    TYPE=$(echo "$COMMAND_OUTPUT" | awk 'NR==1 {print $3}')
    FSTYPE=$(echo "$COMMAND_OUTPUT" | awk 'NR==1 {print $4}')
    MODEL=$(echo "$COMMAND_OUTPUT" | awk 'NR==1 {print $5}')

    if [ -z "$DEVICE_NAME" ]
    then
        TEST_MESSAGE="Unable to determine eMMC device name."
        test_fail
        return
    fi

    if [ -z "$SIZE" ]
    then
        TEST_MESSAGE="Unable to determine eMMC device size."
        test_fail
        return
    fi

    if [ -z "$TYPE" ]
    then
        TEST_MESSAGE="Unable to determine eMMC device type."
        test_fail
        return
    fi

    TEST_MESSAGE="Device=${DEVICE_NAME}, Size=${SIZE}, Type=${TYPE}, Filesystem=${FSTYPE:-N/A}, Model=${MODEL:-N/A}"

    test_pass
}

###############################################################################
# EMMC-002 : Verify EXT_CSD
###############################################################################

emmc_002()
{
    log_info "[EMMC-002] Verify eMMC EXT_CSD"

    if ! command -v mmc >/dev/null 2>&1
    then
        run_command \
            "EMMC-002" \
            "Verify eMMC EXT_CSD" \
            "command -v mmc"

        TEST_MESSAGE="mmc utility is not installed."
        test_skip
        return
    fi

    run_command \
        "EMMC-002" \
        "Verify eMMC EXT_CSD" \
        "mmc extcsd read \"$EMMC_DEVICE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to read eMMC EXT_CSD."
        test_fail
        return
    fi

    if [ -z "$COMMAND_OUTPUT" ]
    then
        TEST_MESSAGE="eMMC EXT_CSD output is empty."
        test_fail
        return
    fi

    TEST_MESSAGE="eMMC EXT_CSD information read successfully."

    test_pass
}

###############################################################################
# EMMC-003 : Verify Filesystem
###############################################################################

emmc_003()
{
    local FILESYSTEM=""

    log_info "[EMMC-003] Verify eMMC Filesystem"

    run_command \
        "EMMC-003" \
        "Verify eMMC Filesystem" \
        "blkid -o value -s TYPE \"$EMMC_DEVICE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine eMMC filesystem."
        test_fail
        return
    fi

    FILESYSTEM=$(echo "$COMMAND_OUTPUT" | tr -d '[:space:]')

    if [ -z "$FILESYSTEM" ]
    then
        TEST_MESSAGE="eMMC filesystem type is not available."
        test_fail
        return
    fi

    TEST_MESSAGE="Filesystem=${FILESYSTEM}"

    test_pass
}

###############################################################################
# EMMC-004 : Mount eMMC
###############################################################################

emmc_004()
{
    local COMMAND
    local MOUNT_DEVICE
    local MOUNTPOINT
    local MOUNTED_BY_TEST

    log_info "[EMMC-004] Mount eMMC"

    COMMAND="emmc_mount_for_test"

    run_command \
        "EMMC-004" \
        "Mount eMMC" \
        "$COMMAND"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to mount eMMC filesystem."
        test_fail
        return
    fi

    #
    # Parse helper-function output captured by run_command.
    #
    MOUNT_DEVICE=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNT_DEVICE=/{print $2}')

    MOUNTPOINT=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNTPOINT=/{print $2}')

    MOUNTED_BY_TEST=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNTED_BY_TEST=/{print $2}')

    #
    # Store the values for subsequent eMMC test cases.
    #
    EMMC_DEVICE_PARTITION="$MOUNT_DEVICE"
    EMMC_MOUNTPOINT="$MOUNTPOINT"
    EMMC_MOUNTED_BY_TEST="$MOUNTED_BY_TEST"

    #
    # Validate mount information.
    #
    if [ -z "$MOUNT_DEVICE" ]
    then
        TEST_MESSAGE="eMMC mount device could not be determined."
        test_fail
        return
    fi

    if [ -z "$MOUNTPOINT" ]
    then
        TEST_MESSAGE="eMMC mount point could not be determined."
        test_fail
        return
    fi

    TEST_MESSAGE="eMMC mounted at ${EMMC_MOUNTPOINT}; MountedByTest=${EMMC_MOUNTED_BY_TEST}"

    test_pass
}

###############################################################################
# EMMC-005 : Verify Mount & Read/Write Status
###############################################################################

emmc_005()
{
    local MOUNTPOINT=""
    local OPTIONS=""

    log_info "[EMMC-005] Verify eMMC Mount & Read/Write Status"

    run_command \
        "EMMC-005" \
        "Verify eMMC Mount & Read/Write Status" \
        "findmnt -n -T \"${EMMC_MOUNTPOINT:-/mnt/emmc_validation}\" -o TARGET,OPTIONS"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="eMMC filesystem is not mounted."
        test_fail
        return
    fi

    MOUNTPOINT=$(echo "$COMMAND_OUTPUT" | awk '{print $1}')
    OPTIONS=$(echo "$COMMAND_OUTPUT" | awk '{print $2}')

    if [ -z "$MOUNTPOINT" ]
    then
        TEST_MESSAGE="Unable to determine eMMC mount point."
        test_fail
        return
    fi

    EMMC_MOUNTPOINT="$MOUNTPOINT"

    if ! echo "$OPTIONS" | grep -qw rw
    then
        TEST_MESSAGE="eMMC filesystem is mounted read-only. Options=${OPTIONS}"
        test_fail
        return
    fi

    TEST_MESSAGE="Mount=${MOUNTPOINT}, Options=${OPTIONS}, Status=Read-Write"

    test_pass
}

###############################################################################
# EMMC-006 : Capacity & Usage
###############################################################################

emmc_006()
{
    local SIZE=""
    local USED=""
    local AVAILABLE=""
    local UTILIZATION=""
    local MOUNTPOINT=""

    log_info "[EMMC-006] Verify eMMC Capacity & Usage"

    MOUNTPOINT="${EMMC_MOUNTPOINT}"

    if [ -z "$MOUNTPOINT" ]
    then
        MOUNTPOINT="/mnt/emmc_validation"
    fi

    run_command \
        "EMMC-006" \
        "Verify eMMC Capacity & Usage" \
        "lsblk -dn -o SIZE \"$EMMC_DEVICE\" && df -h \"$MOUNTPOINT\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine eMMC capacity or filesystem usage."
        test_fail
        return
    fi

    SIZE=$(echo "$COMMAND_OUTPUT" |
        head -n 1 |
        tr -d '[:space:]')

    USED=$(echo "$COMMAND_OUTPUT" |
        awk 'NR==3 {print $3}')

    AVAILABLE=$(echo "$COMMAND_OUTPUT" |
        awk 'NR==3 {print $4}')

    UTILIZATION=$(echo "$COMMAND_OUTPUT" |
        awk 'NR==3 {print $5}')

    if [ -z "$SIZE" ]
    then
        TEST_MESSAGE="eMMC capacity is empty."
        test_fail
        return
    fi

    TEST_MESSAGE="Capacity=${SIZE}, Used=${USED:-N/A}, Available=${AVAILABLE:-N/A}, Usage=${UTILIZATION:-N/A}"

    test_pass
}

###############################################################################
# EMMC-007 : Read/Write Access
###############################################################################

emmc_007()
{
    local TEST_FILE=""

    log_info "[EMMC-007] Verify eMMC Read/Write Access"

    if [ -z "$EMMC_MOUNTPOINT" ]
    then
        run_command \
            "EMMC-007" \
            "Verify eMMC Read/Write Access" \
            "printf '%s\\n' 'ERROR: eMMC is not mounted'"

        TEST_MESSAGE="eMMC is not mounted. Run EMMC-004 first."
        test_fail
        return
    fi

    EMMC_TEST_DIR="${EMMC_MOUNTPOINT}/emmc_validation"
    TEST_FILE="${EMMC_TEST_DIR}/rw_test.txt"

    #
    # Create directory
    #
    run_command \
        "EMMC-007" \
        "Verify eMMC Read/Write Access - Create Directory" \
        "mkdir -p \"$EMMC_TEST_DIR\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to create eMMC test directory."
        test_fail
        return
    fi

    #
    # Create file
    #
    run_command \
        "EMMC-007" \
        "Verify eMMC Read/Write Access - Create File" \
        "touch \"$TEST_FILE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to create eMMC test file."
        test_fail
        return
    fi

    #
    # Write file
    #
    run_command \
        "EMMC-007" \
        "Verify eMMC Read/Write Access - Write File" \
        "echo 'eMMC Storage Validation Framework' > \"$TEST_FILE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to write eMMC test file."
        test_fail
        return
    fi

    #
    # Read file
    #
    run_command \
        "EMMC-007" \
        "Verify eMMC Read/Write Access - Read File" \
        "cat \"$TEST_FILE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to read eMMC test file."
        test_fail
        return
    fi

    #
    # Delete file
    #
    run_command \
        "EMMC-007" \
        "Verify eMMC Read/Write Access - Delete File" \
        "rm -f \"$TEST_FILE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to delete eMMC test file."
        test_fail
        return
    fi

    #
    # Final verification
    #
    run_command \
        "EMMC-007" \
        "Verify eMMC Read/Write Access - Verify Delete" \
        "[ ! -f \"$TEST_FILE\" ]"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="eMMC test file still exists after deletion."
        test_fail
        return
    fi

    TEST_MESSAGE="eMMC create, write, read and delete operations verified."

    test_pass
}

###############################################################################
# EMMC-008 : Sequential Write Performance
###############################################################################

emmc_008()
{
    local TEST_FILE=""

    log_info "[EMMC-008] Verify Sequential Write Performance"

    if [ -z "$EMMC_MOUNTPOINT" ]
    then
        run_command \
            "EMMC-008" \
            "Verify Sequential Write Performance" \
            "printf '%s\\n' 'ERROR: eMMC is not mounted'"

        TEST_MESSAGE="eMMC is not mounted."
        test_fail
        return
    fi

    EMMC_TEST_DIR="${EMMC_MOUNTPOINT}/emmc_validation"
    TEST_FILE="${EMMC_TEST_DIR}/emmc_write_test.bin"

    run_command \
        "EMMC-008" \
        "Verify Sequential Write Performance - Create Directory" \
        "mkdir -p \"$EMMC_TEST_DIR\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to create eMMC performance directory."
        test_fail
        return
    fi

    run_command \
        "EMMC-008" \
        "Verify Sequential Write Performance" \
        "dd if=/dev/zero of=\"$TEST_FILE\" bs=1M count=\"${EMMC_DD_COUNT:-100}\" conv=fsync status=progress"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="eMMC sequential write test failed."
        test_fail
        return
    fi

    EMMC_TEST_FILE="$TEST_FILE"

    TEST_MESSAGE="eMMC sequential write completed successfully."

    test_pass
}

###############################################################################
# EMMC-009 : Sequential Read Performance
###############################################################################

emmc_009()
{
    local TEST_FILE=""

    log_info "[EMMC-009] Verify Sequential Read Performance"

    TEST_FILE="$EMMC_TEST_FILE"

    if [ -z "$TEST_FILE" ]
    then
        TEST_FILE="${EMMC_MOUNTPOINT}/emmc_validation/emmc_write_test.bin"
    fi

    run_command \
        "EMMC-009" \
        "Verify Sequential Read Performance" \
        "dd if=\"$TEST_FILE\" of=/dev/null bs=1M status=progress"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="eMMC sequential read test failed or test file is missing."
        test_fail
        return
    fi

    TEST_MESSAGE="eMMC sequential read completed successfully."

    test_pass
}

###############################################################################
# EMMC-010 : Filesystem Synchronization
###############################################################################

emmc_010()
{
    log_info "[EMMC-010] Verify Filesystem Synchronization"

    run_command \
        "EMMC-010" \
        "Verify Filesystem Synchronization" \
        "sync"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="eMMC filesystem synchronization failed."
        test_fail
        return
    fi

    TEST_MESSAGE="eMMC filesystem synchronized successfully."

    test_pass
}

###############################################################################
# EMMC-011 : Filesystem Health
###############################################################################

emmc_011()
{
    local FILESYSTEM=""
    local CHECK_DEVICE=""
    local HEALTH_COMMAND=""

    log_info "[EMMC-011] Verify Filesystem Health"

    #
    # Get filesystem.
    #
    run_command \
        "EMMC-011" \
        "Verify Filesystem Health - Detect Filesystem" \
        "blkid -o value -s TYPE \"$EMMC_DEVICE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine eMMC filesystem for health check."
        test_fail
        return
    fi

    FILESYSTEM=$(echo "$COMMAND_OUTPUT" | tr -d '[:space:]')

    if [ -z "$FILESYSTEM" ]
    then
        TEST_MESSAGE="eMMC filesystem type is unavailable."
        test_fail
        return
    fi

    CHECK_DEVICE="$EMMC_DEVICE_PARTITION"

    if [ -z "$CHECK_DEVICE" ]
    then
        CHECK_DEVICE=$(emmc_get_filesystem_device)
    fi

    if [ -z "$CHECK_DEVICE" ]
    then
        TEST_MESSAGE="Unable to determine filesystem-bearing eMMC device."
        test_fail
        return
    fi

    case "$FILESYSTEM" in

        ext2|ext3|ext4)

            HEALTH_COMMAND="fsck -N \"$CHECK_DEVICE\""

            ;;

        xfs)

            if ! command -v xfs_repair >/dev/null 2>&1
            then
                run_command \
                    "EMMC-011" \
                    "Verify Filesystem Health - xfs_repair Availability" \
                    "command -v xfs_repair"

                TEST_MESSAGE="xfs_repair utility is not installed."
                test_skip
                return
            fi

            HEALTH_COMMAND="xfs_repair -n \"$CHECK_DEVICE\""

            ;;

        btrfs)

            if ! command -v btrfs >/dev/null 2>&1
            then
                run_command \
                    "EMMC-011" \
                    "Verify Filesystem Health - btrfs Availability" \
                    "command -v btrfs"

                TEST_MESSAGE="btrfs utility is not installed."
                test_skip
                return
            fi

            HEALTH_COMMAND="btrfs check --readonly \"$CHECK_DEVICE\""

            ;;

        *)

            run_command \
                "EMMC-011" \
                "Verify Filesystem Health - Unsupported Filesystem" \
                "printf '%s\\n' \"Unsupported filesystem: $FILESYSTEM\""

            TEST_MESSAGE="Filesystem ${FILESYSTEM} is not supported for health validation."
            test_skip
            return

            ;;

    esac

    run_command \
        "EMMC-011" \
        "Verify Filesystem Health" \
        "$HEALTH_COMMAND"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="eMMC filesystem health verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Filesystem health verification completed for ${FILESYSTEM}."

    test_pass
}

###############################################################################
# EMMC-012 : FIO Availability
###############################################################################

emmc_012()
{
    log_info "[EMMC-012] Verify FIO Availability"

    run_command \
        "EMMC-012" \
        "Verify FIO Availability" \
        "command -v fio"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="fio utility is not installed."
        test_skip
        return
    fi

    TEST_MESSAGE="fio utility is available."

    test_pass
}

###############################################################################
# EMMC-013 : FIO Performance Test
###############################################################################

emmc_013()
{
    local FIO_FILE=""

    log_info "[EMMC-013] Run FIO Performance Test"

    if [ -z "$EMMC_MOUNTPOINT" ]
    then
        run_command \
            "EMMC-013" \
            "Run FIO Performance Test" \
            "printf '%s\\n' 'ERROR: eMMC is not mounted'"

        TEST_MESSAGE="eMMC is not mounted."
        test_fail
        return
    fi

    if ! command -v fio >/dev/null 2>&1
    then
        run_command \
            "EMMC-013" \
            "Run FIO Performance Test - FIO Availability" \
            "command -v fio"

        TEST_MESSAGE="fio utility is not installed."
        test_skip
        return
    fi

    EMMC_TEST_DIR="${EMMC_MOUNTPOINT}/emmc_validation"
    FIO_FILE="${EMMC_TEST_DIR}/emmc_fio_test.bin"

    run_command \
        "EMMC-013" \
        "Run FIO Performance Test - Create Directory" \
        "mkdir -p \"$EMMC_TEST_DIR\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to create eMMC FIO test directory."
        test_fail
        return
    fi

    run_command \
        "EMMC-013" \
        "Run FIO Performance Test" \
        "fio --name=emmc_validation --filename=\"$FIO_FILE\" --size=\"${EMMC_FIO_SIZE:-256M}\" --rw=randrw --bs=4k --runtime=\"${EMMC_FIO_RUNTIME:-60}\" --time_based --group_reporting"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="eMMC FIO performance test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="eMMC FIO random read/write performance test completed."

    test_pass
}

###############################################################################
# EMMC-014 : Unmount eMMC
###############################################################################

emmc_014()
{
    local MOUNTPOINT=""

    log_info "[EMMC-014] Unmount eMMC"

    MOUNTPOINT="$EMMC_MOUNTPOINT"

    if [ -z "$MOUNTPOINT" ]
    then
        run_command \
            "EMMC-014" \
            "Unmount eMMC" \
            "printf '%s\\n' 'eMMC is already unmounted'"

        TEST_MESSAGE="eMMC is already unmounted."
        test_pass
        return
    fi

    #
    # Only unmount if this validation framework mounted it.
    #
    if [ "$EMMC_MOUNTED_BY_TEST" -ne 1 ]
    then
        run_command \
            "EMMC-014" \
            "Unmount eMMC" \
            "findmnt -n -T \"$MOUNTPOINT\" -o TARGET"

        TEST_MESSAGE="eMMC was mounted before validation; leaving existing mount unchanged."
        test_pass
        return
    fi

    run_command \
        "EMMC-014" \
        "Unmount eMMC" \
        "sync && umount \"$MOUNTPOINT\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to unmount eMMC at ${MOUNTPOINT}."
        test_fail
        return
    fi

    #
    # Verify that it is actually unmounted.
    #
    run_command \
        "EMMC-014" \
        "Verify eMMC Unmount" \
        "! findmnt -n -T \"$MOUNTPOINT\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="eMMC is still mounted at ${MOUNTPOINT}."
        test_fail
        return
    fi

    EMMC_MOUNTPOINT=""
    EMMC_DEVICE_PARTITION=""
    EMMC_MOUNTED_BY_TEST=0

    TEST_MESSAGE="eMMC unmounted successfully."

    test_pass
}

###############################################################################
# EMMC-015 : Cleanup eMMC Test Files
###############################################################################

emmc_015()
{
    local CLEANUP_DIR=""

    log_info "[EMMC-015] Cleanup eMMC Test Files"

    CLEANUP_DIR="$EMMC_TEST_DIR"

    if [ -z "$CLEANUP_DIR" ] && [ -n "$EMMC_MOUNTPOINT" ]
    then
        CLEANUP_DIR="${EMMC_MOUNTPOINT}/emmc_validation"
    fi

    if [ -z "$CLEANUP_DIR" ]
    then
        run_command \
            "EMMC-015" \
            "Cleanup eMMC Test Files" \
            "printf '%s\\n' 'No eMMC test directory to cleanup'"

        TEST_MESSAGE="No eMMC temporary test directory found. Cleanup not required."
        test_pass
        return
    fi

    run_command \
        "EMMC-015" \
        "Cleanup eMMC Test Files" \
        "rm -rf \"$CLEANUP_DIR\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to cleanup eMMC test directory ${CLEANUP_DIR}."
        test_fail
        return
    fi

    #
    # Verify cleanup.
    #
    run_command \
        "EMMC-015" \
        "Verify eMMC Test File Cleanup" \
        "[ ! -e \"$CLEANUP_DIR\" ]"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="eMMC test directory still exists after cleanup."
        test_fail
        return
    fi

    emmc_reset_runtime

    TEST_MESSAGE="eMMC temporary test files cleaned successfully."

    test_pass
}

###############################################################################
# Register eMMC Tests
###############################################################################

emmc_register_tests()
{
    register_test \
        -i "EMMC-001" \
        -f emmc_001 \
        -n "Detect & Verify eMMC Device" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "emmc,storage,lsblk,device" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect eMMC device and verify basic device information."

    register_test \
        -i "EMMC-002" \
        -f emmc_002 \
        -n "Verify eMMC EXT_CSD" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "emmc,extcsd,mmc" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Read eMMC EXT_CSD information."

    register_test \
        -i "EMMC-003" \
        -f emmc_003 \
        -n "Verify eMMC Filesystem" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "emmc,filesystem" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify eMMC filesystem type."

    register_test \
        -i "EMMC-004" \
        -f emmc_004 \
        -n "Mount eMMC" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "emmc,mount" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Mount eMMC filesystem when required and record mount state."

    register_test \
        -i "EMMC-005" \
        -f emmc_005 \
        -n "Verify eMMC Mount & Read/Write Status" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "emmc,mount,rw" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify eMMC mount point and read-write status."

    register_test \
        -i "EMMC-006" \
        -f emmc_006 \
        -n "Verify eMMC Capacity & Usage" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 10 \
        -g "emmc,capacity,usage,df" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify eMMC capacity and filesystem usage."

    register_test \
        -i "EMMC-007" \
        -f emmc_007 \
        -n "Verify eMMC Read/Write Access" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 30 \
        -g "emmc,read,write,file" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify eMMC file create, write, read and delete operations."

    register_test \
        -i "EMMC-008" \
        -f emmc_008 \
        -n "Verify Sequential Write Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 300 \
        -g "emmc,dd,write,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure eMMC sequential write performance."

    register_test \
        -i "EMMC-009" \
        -f emmc_009 \
        -n "Verify Sequential Read Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 300 \
        -g "emmc,dd,read,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure eMMC sequential read performance."

    register_test \
        -i "EMMC-010" \
        -f emmc_010 \
        -n "Verify Filesystem Synchronization" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "emmc,sync" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify filesystem buffer synchronization."

    register_test \
        -i "EMMC-011" \
        -f emmc_011 \
        -n "Verify Filesystem Health" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 120 \
        -g "emmc,filesystem,health,fsck" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify eMMC filesystem integrity using a read-only check."

    register_test \
        -i "EMMC-012" \
        -f emmc_012 \
        -n "Verify FIO Availability" \
        -c "performance" \
        -t "auto" \
        -p "low" \
        -o 10 \
        -g "emmc,fio" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify fio utility availability."

    register_test \
        -i "EMMC-013" \
        -f emmc_013 \
        -n "Run FIO Performance Test" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 600 \
        -g "emmc,fio,performance,stress" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Run eMMC random read/write fio performance test."

    register_test \
        -i "EMMC-014" \
        -f emmc_014 \
        -n "Unmount eMMC" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "emmc,unmount" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Safely unmount eMMC when the validation framework mounted it."

    register_test \
        -i "EMMC-015" \
        -f emmc_015 \
        -n "Cleanup eMMC Test Files" \
        -c "storage" \
        -t "auto" \
        -p "low" \
        -o 20 \
        -g "emmc,cleanup" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Remove temporary eMMC validation files and verify cleanup."
}

###############################################################################
# Module Initialization
###############################################################################

emmc_init()
{
    log_info "========================================="
    log_info "Starting eMMC Validation"
    log_info "========================================="

    #
    # Always establish a framework result before returning from initialization.
    #
    if [ -z "$EMMC_DEVICE" ]
    then
        TEST_MESSAGE="EMMC_DEVICE is not configured."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    #
    # Do not call test_fail() here because module initialization is not itself
    # a registered test case. EMMC-001 owns device detection and its logging.
    #
    log_info "Configured eMMC Device : $EMMC_DEVICE"

    emmc_register_tests

    return 0
}

###############################################################################
# Module Initialization When Sourced
###############################################################################

emmc_init

###############################################################################
# End Of File
###############################################################################
