#!/bin/bash
###############################################################################
# File        : sdcard.sh
# Description : SD Card Storage Validation Module
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="SDCARD"
MODULE_DESCRIPTION="SD Card Storage Validation"

###############################################################################
# SD Card Runtime Variables
###############################################################################

SDCARD_MOUNTPOINT=""
SDCARD_DEVICE_PARTITION=""
SDCARD_MOUNTED_BY_TEST=0

SDCARD_TEST_FILE=""
SDCARD_TEST_DIR=""

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
    tr
)

###############################################################################
# Helper Functions
###############################################################################

###############################################################################
# Check whether SD card device exists
###############################################################################

sdcard_device_exists()
{
    [ -b "$SDCARD_DEVICE" ]
}

###############################################################################
# Get SD card device name
###############################################################################

sdcard_get_device_name()
{
    lsblk -dn -o NAME "$SDCARD_DEVICE"
}

###############################################################################
# Get SD card size
###############################################################################

sdcard_get_size()
{
    lsblk -dn -o SIZE "$SDCARD_DEVICE"
}

###############################################################################
# Get SD card device type
###############################################################################

sdcard_get_type()
{
    lsblk -dn -o TYPE "$SDCARD_DEVICE"
}

###############################################################################
# Get SD card model
###############################################################################

sdcard_get_model()
{
    lsblk -dn -o MODEL "$SDCARD_DEVICE"
}

###############################################################################
# Get SD card filesystem
###############################################################################

sdcard_get_filesystem()
{
    local DEVICE="$SDCARD_DEVICE"
    local FS_TYPE

    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)

    if [ -n "$FS_TYPE" ]
    then
        echo "$FS_TYPE"
        return 0
    fi

    lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICE" 2>/dev/null |
        awk '$3 != "" {print $3; exit}'
}

###############################################################################
# Find filesystem-bearing SD card device
###############################################################################

sdcard_get_filesystem_device()
{
    local DEVICE="$SDCARD_DEVICE"
    local FS_TYPE

    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)

    if [ -n "$FS_TYPE" ]
    then
        echo "$DEVICE"
        return 0
    fi

    lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICE" 2>/dev/null |
        awk '$3 != "" {print "/dev/" $1; exit}'
}

###############################################################################
# Get SD card mount point
###############################################################################

sdcard_get_mountpoint()
{
    local MOUNT_DEVICE

    if [ -n "$SDCARD_MOUNTPOINT" ]
    then
        echo "$SDCARD_MOUNTPOINT"
        return 0
    fi

    MOUNT_DEVICE=$(sdcard_get_filesystem_device)

    if [ -z "$MOUNT_DEVICE" ]
    then
        return 1
    fi

    findmnt -n -S "$MOUNT_DEVICE" -o TARGET 2>/dev/null
}

###############################################################################
# Get SD card mount options
###############################################################################

sdcard_get_mount_options()
{
    local MOUNTPOINT="$1"

    if [ -z "$MOUNTPOINT" ]
    then
        return 1
    fi

    findmnt -n -T "$MOUNTPOINT" -o OPTIONS
}

###############################################################################
# Check whether SD card is mounted
###############################################################################

sdcard_is_mounted()
{
    local MOUNT_DEVICE

    MOUNT_DEVICE=$(sdcard_get_filesystem_device)

    if [ -z "$MOUNT_DEVICE" ]
    then
        return 1
    fi

    findmnt -n -S "$MOUNT_DEVICE" >/dev/null 2>&1
}

###############################################################################
# Check whether SD card filesystem is mounted read-write
###############################################################################

sdcard_is_rw()
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
# Create SD card test directory
###############################################################################

sdcard_create_test_directory()
{
    if [ -z "$SDCARD_MOUNTPOINT" ]
    then
        return 1
    fi

    SDCARD_TEST_DIR="${SDCARD_MOUNTPOINT}/sdcard_validation"

    mkdir -p "$SDCARD_TEST_DIR"
}

###############################################################################
# Get SD card test file
###############################################################################

sdcard_get_test_file()
{
    if [ -z "$SDCARD_TEST_DIR" ]
    then
        SDCARD_TEST_DIR="${SDCARD_MOUNTPOINT}/sdcard_validation"
    fi

    SDCARD_TEST_FILE="${SDCARD_TEST_DIR}/sdcard_test.bin"

    echo "$SDCARD_TEST_FILE"
}

###############################################################################
# Mount SD card
#
# This function is intentionally separate from SDCARD-002.
###############################################################################

sdcard_mount_for_test()
{
    local DEVICE
    local FS_TYPE
    local MOUNT_DEVICE
    local EXISTING_MOUNT
    local MOUNTPOINT

    DEVICE="$SDCARD_DEVICE"

    if [ ! -b "$DEVICE" ]
    then
        echo "ERROR: SD card device $DEVICE does not exist."
        return 1
    fi

    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)

    if [ -n "$FS_TYPE" ]
    then
        MOUNT_DEVICE="$DEVICE"
    else
        MOUNT_DEVICE=$(sdcard_get_filesystem_device)
    fi

    if [ -z "$MOUNT_DEVICE" ]
    then
        echo "ERROR: No filesystem-bearing SD card device found."
        return 1
    fi

    EXISTING_MOUNT=$(findmnt -n -S "$MOUNT_DEVICE" -o TARGET 2>/dev/null)

    if [ -n "$EXISTING_MOUNT" ]
    then
        SDCARD_DEVICE_PARTITION="$MOUNT_DEVICE"
        SDCARD_MOUNTPOINT="$EXISTING_MOUNT"
        SDCARD_MOUNTED_BY_TEST=0

        echo "MOUNT_DEVICE=$SDCARD_DEVICE_PARTITION"
        echo "MOUNTPOINT=$SDCARD_MOUNTPOINT"
        echo "MOUNTED_BY_TEST=0"

        return 0
    fi

    if [ -n "$SDCARD_MOUNTPOINT_PATH" ]
    then
        MOUNTPOINT="$SDCARD_MOUNTPOINT_PATH"
    else
        MOUNTPOINT="/mnt/sdcard_validation"
    fi

    mkdir -p "$MOUNTPOINT"

    if ! mount "$MOUNT_DEVICE" "$MOUNTPOINT"
    then
        echo "ERROR: Failed to mount $MOUNT_DEVICE on $MOUNTPOINT."
        return 1
    fi

    SDCARD_DEVICE_PARTITION="$MOUNT_DEVICE"
    SDCARD_MOUNTPOINT="$MOUNTPOINT"
    SDCARD_MOUNTED_BY_TEST=1

    echo "MOUNT_DEVICE=$SDCARD_DEVICE_PARTITION"
    echo "MOUNTPOINT=$SDCARD_MOUNTPOINT"
    echo "MOUNTED_BY_TEST=1"

    return 0
}

###############################################################################
# Ensure SD card is mounted
###############################################################################

sdcard_ensure_mounted()
{
    if [ -n "$SDCARD_MOUNTPOINT" ] &&
       findmnt -n -T "$SDCARD_MOUNTPOINT" >/dev/null 2>&1
    then
        return 0
    fi

    sdcard_mount_for_test
}

###############################################################################
# Filesystem Health Helper
###############################################################################

sdcard_filesystem_health_check()
{
    local DEVICE="$SDCARD_DEVICE"
    local CHECK_DEVICE
    local FS_TYPE

    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)

    if [ -n "$FS_TYPE" ]
    then
        CHECK_DEVICE="$DEVICE"
    else
        CHECK_DEVICE=$(sdcard_get_filesystem_device)
    fi

    if [ -z "$CHECK_DEVICE" ]
    then
        echo "ERROR: Unable to determine filesystem-bearing device."
        return 2
    fi

    FS_TYPE=$(blkid -o value -s TYPE "$CHECK_DEVICE" 2>/dev/null)

    if [ -z "$FS_TYPE" ]
    then
        echo "ERROR: Unable to determine filesystem type."
        return 2
    fi

    echo "FILESYSTEM=$FS_TYPE"
    echo "CHECK_DEVICE=$CHECK_DEVICE"

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

        *)
            echo "SKIP: Filesystem $FS_TYPE is not supported."
            return 3
            ;;

    esac
}

###############################################################################
# SDCARD-001 Command Helper
###############################################################################

sdcard_cmd_device_info()
{
    lsblk -dn -o NAME,SIZE,TYPE,FSTYPE,MODEL "$SDCARD_DEVICE"
}

###############################################################################
# SDCARD-003 Command Helper
###############################################################################

sdcard_cmd_rw_test()
{
    local TEST_FILE

    if ! sdcard_ensure_mounted
    then
        return 1
    fi

    if ! sdcard_create_test_directory
    then
        return 1
    fi

    TEST_FILE="${SDCARD_TEST_DIR}/sdcard_rw_test.txt"

    touch "$TEST_FILE" &&
    echo "SD Card Storage Validation Framework" > "$TEST_FILE" &&
    grep -q "SD Card Storage Validation Framework" "$TEST_FILE" &&
    cat "$TEST_FILE" >/dev/null &&
    rm -f "$TEST_FILE" &&
    [ ! -f "$TEST_FILE" ]
}

###############################################################################
# SDCARD-004 Command Helper
###############################################################################

sdcard_cmd_capacity()
{
    if ! sdcard_ensure_mounted
    then
        return 1
    fi

    lsblk -dn -o SIZE "$SDCARD_DEVICE"
    df -h "$SDCARD_MOUNTPOINT"
}

###############################################################################
# SDCARD-005 Command Helper
###############################################################################

sdcard_cmd_sequential_write()
{
    if ! sdcard_ensure_mounted
    then
        return 1
    fi

    if ! sdcard_create_test_directory
    then
        return 1
    fi

    SDCARD_TEST_FILE="${SDCARD_TEST_DIR}/sdcard_performance_test.bin"

    dd if=/dev/zero \
       of="$SDCARD_TEST_FILE" \
       bs=1M \
       count="${SDCARD_DD_COUNT:-100}" \
       conv=fsync \
       status=progress
}

###############################################################################
# SDCARD-006 Command Helper
###############################################################################

sdcard_cmd_sequential_read()
{
    if ! sdcard_ensure_mounted
    then
        return 1
    fi

    SDCARD_TEST_DIR="${SDCARD_MOUNTPOINT}/sdcard_validation"
    SDCARD_TEST_FILE="${SDCARD_TEST_DIR}/sdcard_performance_test.bin"

    if [ ! -f "$SDCARD_TEST_FILE" ]
    then
        echo "ERROR: Sequential write test file not found."
        return 1
    fi

    dd if="$SDCARD_TEST_FILE" \
       of=/dev/null \
       bs=1M \
       status=progress
}

###############################################################################
# SDCARD-007 Command Helper
###############################################################################

sdcard_cmd_sync()
{
    sync
}

###############################################################################
# SDCARD-009 Command Helper
###############################################################################

sdcard_cmd_fio_check()
{
    command -v fio
}

###############################################################################
# SDCARD-010 Command Helper
###############################################################################

sdcard_cmd_fio_performance()
{
    local FIO_FILE

    if ! sdcard_ensure_mounted
    then
        return 1
    fi

    if ! sdcard_create_test_directory
    then
        return 1
    fi

    FIO_FILE="${SDCARD_TEST_DIR}/sdcard_fio_test.bin"

    fio \
        --name=sdcard_validation \
        --filename="$FIO_FILE" \
        --size="${SDCARD_FIO_SIZE:-256M}" \
        --rw=randrw \
        --bs=4k \
        --runtime="${SDCARD_FIO_RUNTIME:-60}" \
        --time_based \
        --group_reporting
}

###############################################################################
# SD Card Cleanup Command
###############################################################################

sdcard_cmd_cleanup()
{
    local STATUS=0
    local CLEANUP_DIR=""

    echo "SDCARD_DEVICE=$SDCARD_DEVICE"
    echo "SDCARD_MOUNTPOINT=$SDCARD_MOUNTPOINT"
    echo "SDCARD_TEST_DIR=$SDCARD_TEST_DIR"
    echo "SDCARD_MOUNTED_BY_TEST=$SDCARD_MOUNTED_BY_TEST"

    #
    # Determine validation directory.
    #
    if [ -n "$SDCARD_TEST_DIR" ]
    then
        CLEANUP_DIR="$SDCARD_TEST_DIR"
    elif [ -n "$SDCARD_MOUNTPOINT" ]
    then
        CLEANUP_DIR="${SDCARD_MOUNTPOINT}/sdcard_validation"
    fi

    echo "CLEANUP_DIR=$CLEANUP_DIR"

    ###########################################################################
    # Remove validation directory
    ###########################################################################

    if [ -n "$CLEANUP_DIR" ] &&
       [ -d "$CLEANUP_DIR" ]
    then
        rm -rf "$CLEANUP_DIR"

        if [ $? -ne 0 ]
        then
            echo "ERROR: Failed to remove $CLEANUP_DIR"
            STATUS=1
        else
            echo "Validation directory removed successfully."
        fi
    else
        echo "Validation directory does not exist. Nothing to remove."
    fi

    ###########################################################################
    # Synchronize filesystem
    ###########################################################################

    sync

    if [ $? -ne 0 ]
    then
        echo "ERROR: sync failed."
        STATUS=1
    else
        echo "Filesystem synchronized successfully."
    fi

    ###########################################################################
    # Final unmount
    #
    # IMPORTANT:
    # Only unmount if this validation framework mounted the SD card.
    #
    ###########################################################################

    if [ "$SDCARD_MOUNTED_BY_TEST" -eq 1 ] &&
       [ -n "$SDCARD_MOUNTPOINT" ]
    then
        echo "SD card was mounted by validation."
        echo "Unmounting $SDCARD_MOUNTPOINT"

        umount "$SDCARD_MOUNTPOINT"

        if [ $? -ne 0 ]
        then
            echo "ERROR: Failed to unmount $SDCARD_MOUNTPOINT"
            STATUS=1
        else
            echo "SD card unmounted successfully."

            ###################################################################
            # Verify unmount
            ###################################################################

            if findmnt -n -T "$SDCARD_MOUNTPOINT" >/dev/null 2>&1
            then
                echo "ERROR: SD card is still mounted."
                STATUS=1
            else
                echo "Final unmount verified successfully."
            fi
        fi
    else
        echo "SD card was not mounted by validation."
        echo "Existing system mount will not be unmounted."
    fi

    return "$STATUS"
}

###############################################################################
# SDCARD-001 : Detect & Verify SD Card Device
###############################################################################

sdcard_001()
{
    local DEVICE_NAME
    local SIZE
    local TYPE
    local FSTYPE
    local MODEL

    log_info "[SDCARD-001] Detect & Verify SD Card Device"

    run_command \
        "SDCARD-001" \
        "Detect & Verify SD Card Device" \
        "sdcard_cmd_device_info"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to detect SD card device ${SDCARD_DEVICE}."
        test_fail
        return
    fi

    DEVICE_NAME=$(echo "$COMMAND_OUTPUT" | awk '{print $1}')
    SIZE=$(echo "$COMMAND_OUTPUT" | awk '{print $2}')
    TYPE=$(echo "$COMMAND_OUTPUT" | awk '{print $3}')
    FSTYPE=$(echo "$COMMAND_OUTPUT" | awk '{print $4}')
    MODEL=$(echo "$COMMAND_OUTPUT" | awk '{print $5}')

    if [ -z "$DEVICE_NAME" ]
    then
        TEST_MESSAGE="SD card device name could not be determined."
        test_fail
        return
    fi

    if [ -z "$SIZE" ]
    then
        TEST_MESSAGE="Unable to determine SD card size."
        test_fail
        return
    fi

    if [ -z "$TYPE" ]
    then
        TEST_MESSAGE="Unable to determine SD card device type."
        test_fail
        return
    fi

    TEST_MESSAGE="Device=${DEVICE_NAME}, Size=${SIZE}, Type=${TYPE}, Filesystem=${FSTYPE:-N/A}, Model=${MODEL:-N/A}"

    test_pass
}

###############################################################################
# SDCARD-002 : Mount SD Card
###############################################################################

sdcard_002()
{
    local MOUNT_DEVICE
    local MOUNTPOINT
    local MOUNTED_BY_TEST

    log_info "[SDCARD-002] Mount SD Card"

    run_command \
        "SDCARD-002" \
        "Mount SD Card" \
        "sdcard_mount_for_test"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to mount SD card filesystem."
        test_fail
        return
    fi

    MOUNT_DEVICE=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNT_DEVICE=/{print $2}')

    MOUNTPOINT=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNTPOINT=/{print $2}')

    MOUNTED_BY_TEST=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNTED_BY_TEST=/{print $2}')

    SDCARD_DEVICE_PARTITION="$MOUNT_DEVICE"
    SDCARD_MOUNTPOINT="$MOUNTPOINT"
    SDCARD_MOUNTED_BY_TEST="$MOUNTED_BY_TEST"

    if [ -z "$SDCARD_MOUNTPOINT" ]
    then
        TEST_MESSAGE="SD card mount point could not be determined."
        test_fail
        return
    fi

    TEST_MESSAGE="SD card mounted at ${SDCARD_MOUNTPOINT}; MountedByTest=${SDCARD_MOUNTED_BY_TEST}"

    test_pass
}

###############################################################################
# SDCARD-003 : Read / Write Access
###############################################################################

sdcard_003()
{
    log_info "[SDCARD-003] Verify SD Card Read/Write Access"

    run_command \
        "SDCARD-003" \
        "Verify SD Card Read/Write Access" \
        "sdcard_cmd_rw_test"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SD card create/write/read/delete operation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="SD card file create, write, read and delete operations verified."

    test_pass
}

###############################################################################
# SDCARD-004 : Capacity / Usage
###############################################################################

sdcard_004()
{
    local OUTPUT
    local SIZE
    local USED
    local AVAILABLE
    local UTILIZATION

    log_info "[SDCARD-004] Verify SD Card Capacity & Usage"

    run_command \
        "SDCARD-004" \
        "Verify SD Card Capacity & Usage" \
        "sdcard_cmd_capacity"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine SD card capacity or usage."
        test_fail
        return
    fi

    OUTPUT="$COMMAND_OUTPUT"

    SIZE=$(echo "$OUTPUT" |
        head -n 1 |
        tr -d '[:space:]')

    USED=$(echo "$OUTPUT" |
        awk 'NR==2 {print $3}')

    AVAILABLE=$(echo "$OUTPUT" |
        awk 'NR==2 {print $4}')

    UTILIZATION=$(echo "$OUTPUT" |
        awk 'NR==2 {print $5}')

    if [ -z "$SIZE" ]
    then
        TEST_MESSAGE="SD card capacity is empty."
        test_fail
        return
    fi

    TEST_MESSAGE="Capacity=${SIZE}, Used=${USED:-N/A}, Available=${AVAILABLE:-N/A}, Usage=${UTILIZATION:-N/A}"

    test_pass
}

###############################################################################
# SDCARD-005 : Sequential Write
###############################################################################

sdcard_005()
{
    log_info "[SDCARD-005] Verify Sequential Write Performance"

    run_command \
        "SDCARD-005" \
        "Verify Sequential Write Performance" \
        "sdcard_cmd_sequential_write"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Sequential SD card write test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Sequential SD card write completed successfully."

    test_pass
}

###############################################################################
# SDCARD-006 : Sequential Read
###############################################################################

sdcard_006()
{
    log_info "[SDCARD-006] Verify Sequential Read Performance"

    run_command \
        "SDCARD-006" \
        "Verify Sequential Read Performance" \
        "sdcard_cmd_sequential_read"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Sequential SD card read test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Sequential SD card read completed successfully."

    test_pass
}

###############################################################################
# SDCARD-007 : Sync
###############################################################################

sdcard_007()
{
    log_info "[SDCARD-007] Verify Filesystem Synchronization"

    run_command \
        "SDCARD-007" \
        "Verify Filesystem Synchronization" \
        "sdcard_cmd_sync"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Filesystem synchronization failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Filesystem synchronized successfully."

    test_pass
}

###############################################################################
# SDCARD-008 : Filesystem Health
###############################################################################

sdcard_008()
{
    log_info "[SDCARD-008] Verify Filesystem Health"

    run_command \
        "SDCARD-008" \
        "Verify Filesystem Health" \
        "sdcard_filesystem_health_check"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="Filesystem health utility is unavailable or filesystem is unsupported."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SD card filesystem health verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="SD card filesystem health verification completed successfully."

    test_pass
}

###############################################################################
# SDCARD-009 : FIO Availability
###############################################################################

sdcard_009()
{
    log_info "[SDCARD-009] Verify FIO Availability"

    run_command \
        "SDCARD-009" \
        "Verify FIO Availability" \
        "sdcard_cmd_fio_check"

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
# SDCARD-010 : FIO Performance
###############################################################################

sdcard_010()
{
    log_info "[SDCARD-010] Run FIO Performance Test"

    run_command \
        "SDCARD-010" \
        "Run FIO Performance Test" \
        "sdcard_cmd_fio_performance"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="fio SD card performance test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="fio SD card random read/write performance test completed."

    test_pass
}

###############################################################################
# SDCARD-011 : Cleanup + Final Unmount
###############################################################################

sdcard_011()
{
    log_info "[SDCARD-011] Cleanup + Final Unmount"

    run_command \
        "SDCARD-011" \
        "Cleanup + Final Unmount" \
        "sdcard_cmd_cleanup"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to cleanup SD card validation files or perform final unmount."
        test_fail
        return
    fi

    #
    # Reset runtime variables after successful cleanup.
    #
    SDCARD_TEST_FILE=""
    SDCARD_TEST_DIR=""
    SDCARD_DEVICE_PARTITION=""
    SDCARD_MOUNTPOINT=""
    SDCARD_MOUNTED_BY_TEST=0

    TEST_MESSAGE="SD card validation files removed, filesystem synchronized, and final unmount completed successfully."

    test_pass
}

###############################################################################
# Register SD Card Tests
###############################################################################

sdcard_register_tests()
{
    register_test \
        -i "SDCARD-001" \
        -f sdcard_001 \
        -n "Detect & Verify SD Card Device" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "sdcard,storage,lsblk,device" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect SD card device and verify basic device information."

    register_test \
        -i "SDCARD-002" \
        -f sdcard_002 \
        -n "Mount SD Card" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "sdcard,mount" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Automatically mount the SD card filesystem when required."

    register_test \
        -i "SDCARD-003" \
        -f sdcard_003 \
        -n "Verify SD Card Read/Write Access" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 30 \
        -g "sdcard,read,write,file" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SD card file create, write, read and delete operations."

    register_test \
        -i "SDCARD-004" \
        -f sdcard_004 \
        -n "Verify SD Card Capacity & Usage" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 40 \
        -g "sdcard,capacity,usage,lsblk,df" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SD card capacity and filesystem usage."

    register_test \
        -i "SDCARD-005" \
        -f sdcard_005 \
        -n "Verify Sequential Write Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 50 \
        -g "sdcard,dd,write,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure SD card sequential write performance."

    register_test \
        -i "SDCARD-006" \
        -f sdcard_006 \
        -n "Verify Sequential Read Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 60 \
        -g "sdcard,dd,read,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure SD card sequential read performance."

    register_test \
        -i "SDCARD-007" \
        -f sdcard_007 \
        -n "Verify Filesystem Synchronization" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 70 \
        -g "sdcard,sync" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify filesystem buffer synchronization."

    register_test \
        -i "SDCARD-008" \
        -f sdcard_008 \
        -n "Verify Filesystem Health" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 80 \
        -g "sdcard,filesystem,fsck,health" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SD card filesystem health using a read-only filesystem check."

    register_test \
        -i "SDCARD-009" \
        -f sdcard_009 \
        -n "Verify FIO Availability" \
        -c "performance" \
        -t "auto" \
        -p "low" \
        -o 90 \
        -g "sdcard,fio" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify fio utility availability."

    register_test \
        -i "SDCARD-010" \
        -f sdcard_010 \
        -n "Run FIO Performance Test" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 100 \
        -g "sdcard,fio,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Run fio random read/write performance benchmark."

    register_test \
        -i "SDCARD-011" \
        -f sdcard_011 \
        -n "Cleanup + Final Unmount" \
        -c "storage" \
        -t "auto" \
        -p "low" \
        -o 110 \
        -g "sdcard,cleanup,unmount,sync" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Remove validation files, synchronize filesystem and perform final SD card unmount."
}

###############################################################################
# Module Initialization
###############################################################################

sdcard_init()
{
    log_info "========================================="
    log_info "Starting SD Card Validation"
    log_info "========================================="

    #
    # SDCARD_DEVICE is provided by config.sh.
    #
    # The module is executed using:
    #
    #     ./validate.sh sdcard
    #
    # No device argument is expected from the command line.
    #
    if [ -z "$SDCARD_DEVICE" ]
    then
        TEST_MESSAGE="SDCARD_DEVICE is not configured."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    log_info "Configured SD Card Device : $SDCARD_DEVICE"

    if [ -n "$SDCARD_MOUNTPOINT_PATH" ]
    then
        log_info "Configured SD Card Mountpoint : $SDCARD_MOUNTPOINT_PATH"
    else
        log_info "SD Card Mountpoint : /mnt/sdcard_validation"
    fi

    sdcard_register_tests

    return 0
}

###############################################################################
# Module Initialization When Sourced
###############################################################################

sdcard_init

###############################################################################
# End Of File
###############################################################################

