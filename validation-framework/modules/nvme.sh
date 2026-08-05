#!/bin/bash
###############################################################################
# File        : nvme.sh
# Description : NVMe Storage Validation Module
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="NVME"
MODULE_DESCRIPTION="NVMe Storage Validation"

###############################################################################
# NVMe Runtime Variables
###############################################################################

NVME_MOUNTPOINT=""
NVME_DEVICE_PARTITION=""
NVME_CONTROLLER=""
NVME_MOUNTED_BY_TEST=0

NVME_TEST_DIR=""
NVME_TEST_FILE=""

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
)

###############################################################################
# Helper Functions
###############################################################################

###############################################################################
# Check whether NVMe device exists
###############################################################################

nvme_device_exists()
{
    [ -b "$NVME_DEVICE" ]
}

###############################################################################
# Get NVMe device name
###############################################################################

nvme_get_device_name()
{
    lsblk -dn -o NAME "$NVME_DEVICE"
}

###############################################################################
# Get NVMe device size
###############################################################################

nvme_get_size()
{
    lsblk -dn -o SIZE "$NVME_DEVICE"
}

###############################################################################
# Get NVMe device type
###############################################################################

nvme_get_type()
{
    lsblk -dn -o TYPE "$NVME_DEVICE"
}

###############################################################################
# Get NVMe model
###############################################################################

nvme_get_model()
{
    lsblk -dn -o MODEL "$NVME_DEVICE"
}

###############################################################################
# Get NVMe filesystem device
###############################################################################

nvme_get_filesystem_device()
{
    local DEVICE="$NVME_DEVICE"

    #
    # Check whether filesystem exists directly on device.
    #
    if blkid -o value -s TYPE "$DEVICE" 2>/dev/null | grep -q .
    then
        echo "$DEVICE"
        return 0
    fi

    #
    # Find filesystem-bearing partition.
    #
    lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICE" 2>/dev/null |
        awk '$3 != "" {print "/dev/" $1; exit}'
}

###############################################################################
# Get NVMe filesystem type
###############################################################################

nvme_get_filesystem()
{
    local DEVICE="$1"
    local FS_TYPE=""

    if [ -z "$DEVICE" ]
    then
        DEVICE=$(nvme_get_filesystem_device)
    fi

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    FS_TYPE=$(lsblk -ln -o FSTYPE "$DEVICE" 2>/dev/null |
        awk 'NF {print $1; exit}')

    if [ -z "$FS_TYPE" ]
    then
        FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)
    fi

    echo "$FS_TYPE"
}

###############################################################################
# Get NVMe mount point
###############################################################################

nvme_get_mountpoint()
{
    local MOUNT_DEVICE

    if [ -n "$NVME_MOUNTPOINT" ]
    then
        echo "$NVME_MOUNTPOINT"
        return 0
    fi

    MOUNT_DEVICE=$(nvme_get_filesystem_device)

    if [ -z "$MOUNT_DEVICE" ]
    then
        return 1
    fi

    findmnt -n -S "$MOUNT_DEVICE" -o TARGET 2>/dev/null
}

###############################################################################
# Get NVMe mount options
###############################################################################

nvme_get_mount_options()
{
    local MOUNTPOINT="$1"

    if [ -z "$MOUNTPOINT" ]
    then
        return 1
    fi

    findmnt -n -T "$MOUNTPOINT" -o OPTIONS
}

###############################################################################
# Check whether NVMe filesystem is mounted
###############################################################################

nvme_is_mounted()
{
    local MOUNT_DEVICE

    MOUNT_DEVICE=$(nvme_get_filesystem_device)

    if [ -z "$MOUNT_DEVICE" ]
    then
        return 1
    fi

    findmnt -n -S "$MOUNT_DEVICE" >/dev/null 2>&1
}

###############################################################################
# Check whether NVMe filesystem is mounted read-write
###############################################################################

nvme_is_rw()
{
    local MOUNTPOINT="$1"

    if [ -z "$MOUNTPOINT" ]
    then
        return 1
    fi

    findmnt -n -T "$MOUNTPOINT" -o OPTIONS |
        grep -qw rw
}

###############################################################################
# Get NVMe controller
###############################################################################

nvme_get_controller()
{
    local DEVICE_NAME
    local CONTROLLER=""

    DEVICE_NAME=$(basename "$NVME_DEVICE")

    #
    # nvme0n1 -> nvme0
    # nvme1n1 -> nvme1
    #
    CONTROLLER=$(echo "$DEVICE_NAME" |
        sed -E 's/(nvme[0-9]+)n[0-9]+/\1/')

    if [ -n "$CONTROLLER" ] &&
       [ "$CONTROLLER" != "$DEVICE_NAME" ]
    then
        echo "/dev/$CONTROLLER"
        return 0
    fi

    return 1
}

###############################################################################
# Create NVMe test directory
###############################################################################

nvme_create_test_directory()
{
    if [ -z "$NVME_MOUNTPOINT" ]
    then
        return 1
    fi

    NVME_TEST_DIR="${NVME_MOUNTPOINT}/nvme_validation"

    mkdir -p "$NVME_TEST_DIR"
}

###############################################################################
# Remove NVMe test directory
###############################################################################

nvme_remove_test_directory()
{
    if [ -n "$NVME_TEST_DIR" ]
    then
        rm -rf "$NVME_TEST_DIR" 2>/dev/null
    elif [ -n "$NVME_MOUNTPOINT" ]
    then
        rm -rf "${NVME_MOUNTPOINT}/nvme_validation" 2>/dev/null
    fi
}

###############################################################################
# Mount NVMe filesystem
###############################################################################

nvme_mount_for_test()
{
    local DEVICE
    local MOUNT_DEVICE
    local EXISTING_MOUNT
    local MOUNTPOINT

    DEVICE="$NVME_DEVICE"

    if [ ! -b "$DEVICE" ]
    then
        echo "ERROR: NVMe device $DEVICE does not exist."
        return 1
    fi

    MOUNT_DEVICE=$(nvme_get_filesystem_device)

    if [ -z "$MOUNT_DEVICE" ]
    then
        echo "ERROR: No filesystem-bearing NVMe device found."
        return 1
    fi

    EXISTING_MOUNT=$(findmnt -n -S "$MOUNT_DEVICE" -o TARGET 2>/dev/null || true)

    if [ -n "$EXISTING_MOUNT" ]
    then
        NVME_DEVICE_PARTITION="$MOUNT_DEVICE"
        NVME_MOUNTPOINT="$EXISTING_MOUNT"
        NVME_MOUNTED_BY_TEST=0

        echo "MOUNT_DEVICE=$NVME_DEVICE_PARTITION"
        echo "MOUNTPOINT=$NVME_MOUNTPOINT"
        echo "MOUNTED_BY_TEST=0"

        return 0
    fi

    if [ -n "$NVME_MOUNTPOINT_PATH" ]
    then
        MOUNTPOINT="$NVME_MOUNTPOINT_PATH"
    else
        MOUNTPOINT="/mnt/nvme_validation"
    fi

    mkdir -p "$MOUNTPOINT"

    if ! mount "$MOUNT_DEVICE" "$MOUNTPOINT"
    then
        echo "ERROR: Failed to mount $MOUNT_DEVICE on $MOUNTPOINT."
        return 1
    fi

    NVME_DEVICE_PARTITION="$MOUNT_DEVICE"
    NVME_MOUNTPOINT="$MOUNTPOINT"
    NVME_MOUNTED_BY_TEST=1

    echo "MOUNT_DEVICE=$NVME_DEVICE_PARTITION"
    echo "MOUNTPOINT=$NVME_MOUNTPOINT"
    echo "MOUNTED_BY_TEST=1"

    return 0
}

###############################################################################
# Ensure NVMe is mounted
###############################################################################

nvme_ensure_mounted()
{
    if [ -n "$NVME_MOUNTPOINT" ] &&
       findmnt -n -T "$NVME_MOUNTPOINT" >/dev/null 2>&1
    then
        return 0
    fi

    nvme_mount_for_test
}

###############################################################################
# Filesystem Health Check
###############################################################################

nvme_filesystem_health_check()
{
    local DEVICE="$NVME_DEVICE"
    local CHECK_DEVICE=""
    local FS_TYPE=""

    ###########################################################################
    # Check filesystem directly on configured NVMe device.
    ###########################################################################

    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)

    if [ -n "$FS_TYPE" ]
    then
        CHECK_DEVICE="$DEVICE"
    fi

    ###########################################################################
    # Find filesystem-bearing partition.
    ###########################################################################

    if [ -z "$CHECK_DEVICE" ]
    then
        CHECK_DEVICE=$(lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICE" 2>/dev/null |
            awk '$3 != "" {print "/dev/" $1; exit}')
    fi

    ###########################################################################
    # Verify filesystem device.
    ###########################################################################

    if [ -z "$CHECK_DEVICE" ]
    then
        echo "ERROR: Unable to determine filesystem-bearing device."
        return 2
    fi

    ###########################################################################
    # Get filesystem type.
    ###########################################################################

    FS_TYPE=$(lsblk -ln -o FSTYPE "$CHECK_DEVICE" 2>/dev/null |
        awk 'NF {print $1; exit}')

    if [ -z "$FS_TYPE" ]
    then
        FS_TYPE=$(blkid -o value -s TYPE "$CHECK_DEVICE" 2>/dev/null)
    fi

    if [ -z "$FS_TYPE" ]
    then
        echo "ERROR: Unable to determine filesystem type."
        echo "CHECK_DEVICE=$CHECK_DEVICE"
        return 2
    fi

    echo "FILESYSTEM=$FS_TYPE"
    echo "CHECK_DEVICE=$CHECK_DEVICE"

    ###########################################################################
    # Filesystem-specific health check.
    ###########################################################################

    case "$FS_TYPE" in

        ext2|ext3|ext4)

            fsck -N "$CHECK_DEVICE"

            ;;

        xfs)

            if ! command -v xfs_repair >/dev/null 2>&1
            then
                echo "SKIP: xfs_repair utility is not installed."
                return 3
            fi

            xfs_repair -n "$CHECK_DEVICE"

            ;;

        btrfs)

            if ! command -v btrfs >/dev/null 2>&1
            then
                echo "SKIP: btrfs utility is not installed."
                return 3
            fi

            btrfs check --readonly "$CHECK_DEVICE"

            ;;

        vfat|fat|fat16|fat32)

            if ! command -v fsck.fat >/dev/null 2>&1
            then
                echo "SKIP: fsck.fat utility is not installed."
                return 3
            fi

            fsck.fat -n "$CHECK_DEVICE"

            ;;

        exfat)

            if command -v fsck.exfat >/dev/null 2>&1
            then
                fsck.exfat -n "$CHECK_DEVICE"

            elif command -v exfatfsck >/dev/null 2>&1
            then
                exfatfsck -n "$CHECK_DEVICE"

            else
                echo "SKIP: exFAT filesystem check utility is not installed."
                return 3
            fi

            ;;

        ntfs|ntfs3)

            if command -v ntfsfix >/dev/null 2>&1
            then
                ntfsfix -n "$CHECK_DEVICE"
            else
                echo "SKIP: ntfsfix utility is not installed."
                return 3
            fi

            ;;

        *)

            echo "SKIP: Filesystem $FS_TYPE is not supported."
            return 3

            ;;

    esac

    return $?
}

###############################################################################
# Command Helpers
###############################################################################

###############################################################################
# NVME-001 Command Helper
###############################################################################

nvme_cmd_detect()
{
    lsblk -dn -o NAME,SIZE,TYPE,FSTYPE,MODEL "$NVME_DEVICE"

    if [ $? -ne 0 ]
    then
        return 1
    fi

    if ! command -v nvme >/dev/null 2>&1
    then
        echo "SKIP: nvme utility is not installed."
        return 3
    fi

    nvme list

    return $?
}

###############################################################################
# NVME-002 Command Helper
###############################################################################

nvme_cmd_device_info()
{
    local CONTROLLER="$NVME_CONTROLLER"

    if [ -z "$CONTROLLER" ]
    then
        CONTROLLER=$(nvme_get_controller)
    fi

    if [ -z "$CONTROLLER" ]
    then
        echo "ERROR: Unable to determine NVMe controller."
        return 1
    fi

    echo "NVME_DEVICE=$NVME_DEVICE"
    echo "NVME_CONTROLLER=$CONTROLLER"

    lsblk -dn -o NAME,SIZE,TYPE,MODEL,SERIAL "$NVME_DEVICE"

    if [ $? -ne 0 ]
    then
        return 1
    fi

    if ! command -v nvme >/dev/null 2>&1
    then
        echo "SKIP: nvme utility is not installed."
        return 3
    fi

    nvme id-ctrl "$CONTROLLER"

    return $?
}

###############################################################################
# NVME-003 Command Helper
###############################################################################

nvme_cmd_smart()
{
    local CONTROLLER="$NVME_CONTROLLER"

    if [ -z "$CONTROLLER" ]
    then
        CONTROLLER=$(nvme_get_controller)
    fi

    if [ -z "$CONTROLLER" ]
    then
        echo "ERROR: Unable to determine NVMe controller."
        return 1
    fi

    if ! command -v nvme >/dev/null 2>&1
    then
        echo "SKIP: nvme utility is not installed."
        return 3
    fi

    nvme smart-log "$CONTROLLER"

    return $?
}

###############################################################################
# NVME-004 Command Helper
###############################################################################

nvme_cmd_temperature()
{
    local CONTROLLER="$NVME_CONTROLLER"

    if [ -z "$CONTROLLER" ]
    then
        CONTROLLER=$(nvme_get_controller)
    fi

    if [ -z "$CONTROLLER" ]
    then
        echo "ERROR: Unable to determine NVMe controller."
        return 1
    fi

    if ! command -v nvme >/dev/null 2>&1
    then
        echo "SKIP: nvme utility is not installed."
        return 3
    fi

    nvme smart-log "$CONTROLLER" |
        grep -i "temperature"

    return $?
}

###############################################################################
# NVME-005 Command Helper
###############################################################################

nvme_cmd_mount()
{
    nvme_mount_for_test
}

###############################################################################
# NVME-006 Command Helper
###############################################################################

nvme_cmd_rw_access()
{
    local TEST_FILE

    if ! nvme_ensure_mounted
    then
        return 1
    fi

    if ! nvme_create_test_directory
    then
        return 1
    fi

    TEST_FILE="${NVME_TEST_DIR}/nvme_rw_test.txt"

    touch "$TEST_FILE" || return 1

    echo "NVMe Storage Validation Framework" > "$TEST_FILE" || return 1

    cat "$TEST_FILE" || return 1

    grep -q "NVMe Storage Validation Framework" "$TEST_FILE" || return 1

    rm -f "$TEST_FILE" || return 1

    [ ! -f "$TEST_FILE" ]
}

###############################################################################
# NVME-007 Command Helper
###############################################################################

nvme_cmd_capacity()
{
    local MOUNTPOINT="$NVME_MOUNTPOINT"

    if ! nvme_ensure_mounted
    then
        return 1
    fi

    lsblk -dn -o NAME,SIZE,TYPE "$NVME_DEVICE" || return 1

    df -h "$MOUNTPOINT"

    return $?
}

###############################################################################
# NVME-008 Command Helper
###############################################################################

nvme_cmd_sequential_write()
{
    local TEST_FILE

    if ! nvme_ensure_mounted
    then
        return 1
    fi

    if ! nvme_create_test_directory
    then
        return 1
    fi

    TEST_FILE="${NVME_TEST_DIR}/nvme_performance_test.bin"

    NVME_TEST_FILE="$TEST_FILE"

    dd \
        if=/dev/zero \
        of="$TEST_FILE" \
        bs=1M \
        count="${NVME_DD_COUNT:-100}" \
        conv=fsync \
        status=progress

    return $?
}

###############################################################################
# NVME-009 Command Helper
###############################################################################

nvme_cmd_sequential_read()
{
    local TEST_FILE="$NVME_TEST_FILE"

    if ! nvme_ensure_mounted
    then
        return 1
    fi

    if [ -z "$TEST_FILE" ]
    then
        TEST_FILE="${NVME_MOUNTPOINT}/nvme_validation/nvme_performance_test.bin"
    fi

    if [ ! -f "$TEST_FILE" ]
    then
        echo "ERROR: Sequential write test file not found."
        return 1
    fi

    dd \
        if="$TEST_FILE" \
        of=/dev/null \
        bs=1M \
        status=progress

    return $?
}

###############################################################################
# NVME-010 Command Helper
###############################################################################

nvme_cmd_sync()
{
    sync
}

###############################################################################
# NVME-011 Command Helper
###############################################################################

nvme_cmd_filesystem_health()
{
    nvme_filesystem_health_check
}

###############################################################################
# NVME-012 Command Helper
###############################################################################

nvme_cmd_fio_available()
{
    command -v fio
}

###############################################################################
# NVME-013 Command Helper
###############################################################################

nvme_cmd_fio()
{
    local FIO_FILE

    if ! nvme_ensure_mounted
    then
        return 1
    fi

    if ! nvme_create_test_directory
    then
        return 1
    fi

    if ! command -v fio >/dev/null 2>&1
    then
        echo "SKIP: fio utility is not installed."
        return 3
    fi

    FIO_FILE="${NVME_TEST_DIR}/nvme_fio_test.bin"


    fio \
        --name=nvme_validation \
        --filename="$FIO_FILE" \
        --size="${NVME_FIO_SIZE:-256M}" \
        --rw=randrw \
        --bs=4k \
        --runtime="${NVME_FIO_RUNTIME:-60}" \
        --time_based \
        --group_reporting

    return $?
}

###############################################################################
# NVME-014 Command Helper
###############################################################################

nvme_cmd_cleanup()
{
    local STATUS=0

    #
    # Reconstruct validation directory from mount point.
    #
    if [ -n "$NVME_MOUNTPOINT" ]
    then
        NVME_TEST_DIR="${NVME_MOUNTPOINT}/nvme_validation"
    else
        NVME_TEST_DIR=""
    fi

    #
    # Flush filesystem buffers.
    #
    sync || STATUS=1

    #
    # Remove validation directory.
    #
    if [ -n "$NVME_TEST_DIR" ] &&
       [ -d "$NVME_TEST_DIR" ]
    then
        rm -rf "$NVME_TEST_DIR" || STATUS=1
    fi

    #
    # Final unmount.
    #
    # Only unmount when validation mounted the filesystem.
    #
    if [ "$NVME_MOUNTED_BY_TEST" -eq 1 ] &&
       [ -n "$NVME_MOUNTPOINT" ]
    then
        umount "$NVME_MOUNTPOINT" || STATUS=1
    fi

    #
    # Verify final unmount only when validation performed it.
    #
    if [ "$STATUS" -eq 0 ] &&
       [ "$NVME_MOUNTED_BY_TEST" -eq 1 ] &&
       [ -n "$NVME_DEVICE_PARTITION" ]
    then
        if findmnt -n -S "$NVME_DEVICE_PARTITION" >/dev/null 2>&1
        then
            STATUS=1
        fi
    fi

    return "$STATUS"
}

###############################################################################
# Test Cases
###############################################################################

###############################################################################
# NVME-001 : Detect & Verify NVMe Device
###############################################################################

nvme_001()
{
    log_info "[NVME-001] Detect & Verify NVMe Device"

    run_command \
        "NVME-001" \
        "Detect & Verify NVMe Device" \
        "nvme_cmd_detect"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="NVMe utility is not installed."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to detect NVMe device ${NVME_DEVICE}."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe device ${NVME_DEVICE} detected successfully."

    test_pass
}

###############################################################################
# NVME-002 : Verify NVMe Device Information
###############################################################################

nvme_002()
{
    log_info "[NVME-002] Verify NVMe Device Information"

    run_command \
        "NVME-002" \
        "Verify NVMe Device Information" \
        "nvme_cmd_device_info"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="nvme utility is not installed."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to retrieve NVMe device information."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe device information retrieved successfully."

    test_pass
}

###############################################################################
# NVME-003 : Read NVMe SMART / Health
###############################################################################

nvme_003()
{
    log_info "[NVME-003] Read NVMe SMART / Health"

    run_command \
        "NVME-003" \
        "Read NVMe SMART / Health" \
        "nvme_cmd_smart"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="nvme utility is not installed."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to read NVMe SMART / health information."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe SMART / health information read successfully."

    test_pass
}

###############################################################################
# NVME-004 : Verify NVMe Temperature
###############################################################################

nvme_004()
{
    log_info "[NVME-004] Verify NVMe Temperature"

    run_command \
        "NVME-004" \
        "Verify NVMe Temperature" \
        "nvme_cmd_temperature"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="nvme utility is not installed."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to read NVMe temperature."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe temperature information verified."

    test_pass
}

###############################################################################
# NVME-005 : Mount NVMe
###############################################################################

nvme_005()
{
    local MOUNT_DEVICE
    local MOUNTPOINT
    local MOUNTED_BY_TEST

    log_info "[NVME-005] Mount NVMe"

    run_command \
        "NVME-005" \
        "Mount NVMe" \
        "nvme_cmd_mount"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to mount NVMe filesystem."
        test_fail
        return
    fi

    MOUNT_DEVICE=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNT_DEVICE=/{print $2}')

    MOUNTPOINT=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNTPOINT=/{print $2}')

    MOUNTED_BY_TEST=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNTED_BY_TEST=/{print $2}')

    NVME_DEVICE_PARTITION="$MOUNT_DEVICE"
    NVME_MOUNTPOINT="$MOUNTPOINT"
    NVME_MOUNTED_BY_TEST="$MOUNTED_BY_TEST"

    if [ -z "$NVME_MOUNTPOINT" ]
    then
        TEST_MESSAGE="NVMe mount point could not be determined."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe mounted at ${NVME_MOUNTPOINT}; MountedByTest=${NVME_MOUNTED_BY_TEST}"

    test_pass
}

###############################################################################
# NVME-006 : Read / Write Access
###############################################################################

nvme_006()
{
    log_info "[NVME-006] Verify NVMe Read / Write Access"

    run_command \
        "NVME-006" \
        "Verify NVMe Read / Write Access" \
        "nvme_cmd_rw_access"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="NVMe create/write/read/delete operation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe file create, write, read and delete operations verified."

    test_pass
}

###############################################################################
# NVME-007 : Capacity / Usage
###############################################################################

nvme_007()
{
    log_info "[NVME-007] Verify NVMe Capacity / Usage"

    run_command \
        "NVME-007" \
        "Verify NVMe Capacity / Usage" \
        "nvme_cmd_capacity"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine NVMe capacity or usage."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe capacity and filesystem usage verified."

    test_pass
}

###############################################################################
# NVME-008 : Sequential Write
###############################################################################

nvme_008()
{
    log_info "[NVME-008] Verify NVMe Sequential Write Performance"

    run_command \
        "NVME-008" \
        "Verify NVMe Sequential Write Performance" \
        "nvme_cmd_sequential_write"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="NVMe sequential write test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe sequential write completed successfully."

    test_pass
}

###############################################################################
# NVME-009 : Sequential Read
###############################################################################

nvme_009()
{
    log_info "[NVME-009] Verify NVMe Sequential Read Performance"

    run_command \
        "NVME-009" \
        "Verify NVMe Sequential Read Performance" \
        "nvme_cmd_sequential_read"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="NVMe sequential read test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe sequential read completed successfully."

    test_pass
}

###############################################################################
# NVME-010 : Filesystem Synchronization
###############################################################################

nvme_010()
{
    log_info "[NVME-010] Verify NVMe Filesystem Synchronization"

    run_command \
        "NVME-010" \
        "Verify NVMe Filesystem Synchronization" \
        "nvme_cmd_sync"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="NVMe filesystem synchronization failed."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe filesystem synchronized successfully."

    test_pass
}

###############################################################################
# NVME-011 : Filesystem Health
###############################################################################

nvme_011()
{
    log_info "[NVME-011] Verify NVMe Filesystem Health"

    run_command \
        "NVME-011" \
        "Verify NVMe Filesystem Health" \
        "nvme_cmd_filesystem_health"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="Filesystem health check utility is unavailable or filesystem is unsupported."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="NVMe filesystem health verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe filesystem health verification completed successfully."

    test_pass
}

###############################################################################
# NVME-012 : FIO Availability
###############################################################################

nvme_012()
{
    log_info "[NVME-012] Verify FIO Availability"

    run_command \
        "NVME-012" \
        "Verify FIO Availability" \
        "nvme_cmd_fio_available"

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
# NVME-013 : FIO Performance
###############################################################################

nvme_013()
{
    log_info "[NVME-013] Run NVMe FIO Performance Test"

    run_command \
        "NVME-013" \
        "Run NVMe FIO Performance Test" \
        "nvme_cmd_fio"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="fio utility is not installed."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="NVMe fio random read/write performance test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="NVMe fio random read/write performance test completed."

    test_pass
}

###############################################################################
# NVME-014 : Cleanup + Final Unmount
###############################################################################

nvme_014()
{
    log_info "[NVME-014] Cleanup + Final Unmount"

    run_command \
        "NVME-014" \
        "Cleanup + Final Unmount" \
        "nvme_cmd_cleanup"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to cleanup NVMe validation files or perform final unmount."
        test_fail
        return
    fi

    NVME_MOUNTPOINT=""
    NVME_DEVICE_PARTITION=""
    NVME_MOUNTED_BY_TEST=0
    NVME_TEST_DIR=""
    NVME_TEST_FILE=""

    TEST_MESSAGE="NVMe validation files cleaned and final unmount completed successfully."

    test_pass
}

###############################################################################
# Register NVMe Tests
###############################################################################

nvme_register_tests()
{
    register_test \
        -i "NVME-001" \
        -f nvme_001 \
        -n "Detect & Verify NVMe Device" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "nvme,storage,lsblk,device" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect NVMe device and verify basic device information."

    register_test \
        -i "NVME-002" \
        -f nvme_002 \
        -n "Verify NVMe Device Information" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "nvme,device,information" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify NVMe controller and device information."

    register_test \
        -i "NVME-003" \
        -f nvme_003 \
        -n "Read NVMe SMART / Health" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "nvme,smart,health" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Read NVMe SMART and health information."

    register_test \
        -i "NVME-004" \
        -f nvme_004 \
        -n "Verify NVMe Temperature" \
        -c "thermal" \
        -t "auto" \
        -p "medium" \
        -o 40 \
        -g "nvme,temperature,thermal" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify NVMe temperature information."

    register_test \
        -i "NVME-005" \
        -f nvme_005 \
        -n "Mount NVMe" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 50 \
        -g "nvme,mount,filesystem" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Mount an unmounted NVMe filesystem for validation."

    register_test \
        -i "NVME-006" \
        -f nvme_006 \
        -n "Verify NVMe Read / Write Access" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 60 \
        -g "nvme,read,write,file" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify NVMe file create, write, read and delete operations."

    register_test \
        -i "NVME-007" \
        -f nvme_007 \
        -n "Verify NVMe Capacity / Usage" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 70 \
        -g "nvme,capacity,usage,df" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify NVMe capacity and filesystem usage."

    register_test \
        -i "NVME-008" \
        -f nvme_008 \
        -n "Verify NVMe Sequential Write Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 80 \
        -g "nvme,dd,write,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure NVMe sequential write performance."

    register_test \
        -i "NVME-009" \
        -f nvme_009 \
        -n "Verify NVMe Sequential Read Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 90 \
        -g "nvme,dd,read,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure NVMe sequential read performance."

    register_test \
        -i "NVME-010" \
        -f nvme_010 \
        -n "Verify NVMe Filesystem Synchronization" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 100 \
        -g "nvme,sync" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify NVMe filesystem buffer synchronization."

    register_test \
        -i "NVME-011" \
        -f nvme_011 \
        -n "Verify NVMe Filesystem Health" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 110 \
        -g "nvme,filesystem,fsck,health" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify NVMe filesystem integrity using a read-only filesystem check."

    register_test \
        -i "NVME-012" \
        -f nvme_012 \
        -n "Verify FIO Availability" \
        -c "performance" \
        -t "auto" \
        -p "low" \
        -o 120 \
        -g "nvme,fio" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify fio utility availability."

    register_test \
        -i "NVME-013" \
        -f nvme_013 \
        -n "Run NVMe FIO Performance Test" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 130 \
        -g "nvme,fio,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Run fio random read/write performance benchmark on the NVMe filesystem."

    register_test \
        -i "NVME-014" \
        -f nvme_014 \
        -n "Cleanup + Final Unmount" \
        -c "storage" \
        -t "auto" \
        -p "low" \
        -o 140 \
        -g "nvme,cleanup,unmount" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Cleanup NVMe validation files and release temporary mount when applicable."
}

###############################################################################
# Module Initialization
###############################################################################

nvme_init()
{
    log_info "========================================="
    log_info "Starting NVMe Validation"
    log_info "========================================="

    #
    # NVME_DEVICE comes from config.sh.
    #
    if [ -z "$NVME_DEVICE" ]
    then
        TEST_MESSAGE="NVME_DEVICE is not configured."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    #
    # Validate configured device path.
    #
    if [ ! -b "$NVME_DEVICE" ]
    then
        TEST_MESSAGE="Configured NVMe device does not exist: $NVME_DEVICE"
        log_error "$TEST_MESSAGE"
        return 1
    fi

    NVME_CONTROLLER=$(nvme_get_controller 2>/dev/null || true)

    log_info "Configured NVMe Device : $NVME_DEVICE"
    log_info "NVMe Controller        : ${NVME_CONTROLLER:-N/A}"

    nvme_register_tests

    return 0
}

###############################################################################
# Module Initialization When Sourced
###############################################################################

nvme_init

###############################################################################
# End Of File
