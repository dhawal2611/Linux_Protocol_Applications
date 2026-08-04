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
    sed
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
# Get SD card filesystem
###############################################################################

sdcard_get_filesystem()
{
    local DEVICE="$SDCARD_DEVICE"

    blkid -o value -s TYPE "$DEVICE" 2>/dev/null

    if [ $? -eq 0 ]
    then
        return 0
    fi

    lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICE" 2>/dev/null |
        awk '$3 != "" {print $3; exit}'
}

###############################################################################
# Get SD card model
###############################################################################

sdcard_get_model()
{
    lsblk -dn -o MODEL "$SDCARD_DEVICE"
}

###############################################################################
# Find filesystem-bearing SD card device
###############################################################################

sdcard_get_filesystem_device()
{
    local DEVICE="$SDCARD_DEVICE"

    if blkid -o value -s TYPE "$DEVICE" 2>/dev/null | grep -q .
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
# Remove SD card test directory
###############################################################################

sdcard_remove_test_directory()
{
    if [ -n "$SDCARD_TEST_DIR" ]
    then
        rm -rf "$SDCARD_TEST_DIR" 2>/dev/null
    elif [ -n "$SDCARD_MOUNTPOINT" ]
    then
        rm -rf "${SDCARD_MOUNTPOINT}/sdcard_validation" 2>/dev/null
    fi
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
# This function is intentionally outside the test case.
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

    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null || true)

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

    EXISTING_MOUNT=$(findmnt -n -S "$MOUNT_DEVICE" -o TARGET 2>/dev/null || true)

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
    local FS_TYPE
    local CHECK_DEVICE

    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null || true)

    if [ -z "$FS_TYPE" ]
    then
        CHECK_DEVICE=$(sdcard_get_filesystem_device)
    else
        CHECK_DEVICE="$DEVICE"
    fi

    if [ -z "$CHECK_DEVICE" ]
    then
        echo "ERROR: Unable to determine filesystem-bearing device."
        return 2
    fi

    FS_TYPE=$(blkid -o value -s TYPE "$CHECK_DEVICE" 2>/dev/null || true)

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
# SDCARD-001 : Device Detection / Identification
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
        "lsblk -dn -o NAME,SIZE,TYPE,FSTYPE,MODEL \"$SDCARD_DEVICE\""

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
# SDCARD-002 : Filesystem & Mount Verification
###############################################################################

sdcard_002()
{
    local FILESYSTEM
    local MOUNT_DEVICE
    local MOUNTPOINT
    local OPTIONS

    log_info "[SDCARD-002] Verify SD Card Filesystem & Mount"

    MOUNT_DEVICE=$(sdcard_get_filesystem_device)

    if [ -z "$MOUNT_DEVICE" ]
    then
        TEST_MESSAGE="Unable to determine SD card filesystem device."
        test_fail
        return
    fi

    run_command \
        "SDCARD-002" \
        "Verify SD Card Filesystem & Mount" \
        "blkid -o value -s TYPE \"$MOUNT_DEVICE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine SD card filesystem."
        test_fail
        return
    fi

    FILESYSTEM=$(echo "$COMMAND_OUTPUT" | tr -d '[:space:]')

    if [ -z "$FILESYSTEM" ]
    then
        TEST_MESSAGE="SD card filesystem type is empty."
        test_fail
        return
    fi

    MOUNTPOINT=$(findmnt -n -S "$MOUNT_DEVICE" -o TARGET 2>/dev/null || true)

    if [ -n "$MOUNTPOINT" ]
    then
        OPTIONS=$(findmnt -n -T "$MOUNTPOINT" -o OPTIONS 2>/dev/null || true)

        if echo "$OPTIONS" | grep -qw rw
        then
            TEST_MESSAGE="Filesystem=${FILESYSTEM}, Mount=${MOUNTPOINT}, Options=${OPTIONS}, Access=RW"
        else
            TEST_MESSAGE="Filesystem=${FILESYSTEM}, Mount=${MOUNTPOINT}, Options=${OPTIONS}, Access=Not-RW"
        fi
    else
        TEST_MESSAGE="Filesystem=${FILESYSTEM}, Mount=Not currently mounted"
    fi

    test_pass
}

###############################################################################
# SDCARD-003 : Mount SD Card
###############################################################################

sdcard_003()
{
    local MOUNT_DEVICE
    local MOUNTPOINT
    local MOUNTED_BY_TEST

    log_info "[SDCARD-003] Mount SD Card"

    run_command \
        "SDCARD-003" \
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
# SDCARD-004 : Read / Write Access
###############################################################################

sdcard_004()
{
    local TEST_FILE
    local COMMAND

    log_info "[SDCARD-004] Verify SD Card Read/Write Access"

    if ! sdcard_ensure_mounted
    then
        TEST_MESSAGE="Unable to mount SD card for read/write validation."
        test_fail
        return
    fi

    SDCARD_TEST_DIR="${SDCARD_MOUNTPOINT}/sdcard_validation"
    SDCARD_TEST_FILE="${SDCARD_TEST_DIR}/sdcard_rw_test.txt"

    TEST_FILE="$SDCARD_TEST_FILE"

    COMMAND="
        mkdir -p \"$SDCARD_TEST_DIR\" &&
        touch \"$TEST_FILE\" &&
        echo 'SD Card Storage Validation Framework' > \"$TEST_FILE\" &&
        grep -q 'SD Card Storage Validation Framework' \"$TEST_FILE\" &&
        cat \"$TEST_FILE\" &&
        rm -f \"$TEST_FILE\" &&
        [ ! -f \"$TEST_FILE\" ]
    "

    run_command \
        "SDCARD-004" \
        "Verify SD Card Read/Write Access" \
        "$COMMAND"

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
# SDCARD-005 : Capacity / Usage
###############################################################################

sdcard_005()
{
    local SIZE
    local USED
    local AVAILABLE
    local UTILIZATION
    local MOUNTPOINT

    log_info "[SDCARD-005] Verify SD Card Capacity & Usage"

    if ! sdcard_ensure_mounted
    then
        TEST_MESSAGE="Unable to mount SD card for capacity validation."
        test_fail
        return
    fi

    MOUNTPOINT="$SDCARD_MOUNTPOINT"

    run_command \
        "SDCARD-005" \
        "Verify SD Card Capacity & Usage" \
        "lsblk -dn -o SIZE \"$SDCARD_DEVICE\" && df -h \"$MOUNTPOINT\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine SD card capacity or usage."
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
        TEST_MESSAGE="SD card capacity is empty."
        test_fail
        return
    fi

    TEST_MESSAGE="Capacity=${SIZE}, Used=${USED:-N/A}, Available=${AVAILABLE:-N/A}, Usage=${UTILIZATION:-N/A}"

    test_pass
}

###############################################################################
# SDCARD-006 : Sequential Write Performance
###############################################################################

sdcard_006()
{
    log_info "[SDCARD-006] Verify Sequential Write Performance"

    if ! sdcard_ensure_mounted
    then
        TEST_MESSAGE="Unable to mount SD card for sequential write test."
        test_fail
        return
    fi

    SDCARD_TEST_DIR="${SDCARD_MOUNTPOINT}/sdcard_validation"
    SDCARD_TEST_FILE="${SDCARD_TEST_DIR}/sdcard_performance_test.bin"

    mkdir -p "$SDCARD_TEST_DIR"

    run_command \
        "SDCARD-006" \
        "Verify Sequential Write Performance" \
        "dd if=/dev/zero of=\"$SDCARD_TEST_FILE\" bs=1M count=\"${SDCARD_DD_COUNT:-100}\" conv=fsync status=progress"

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
# SDCARD-007 : Sequential Read Performance
###############################################################################

sdcard_007()
{
    log_info "[SDCARD-007] Verify Sequential Read Performance"

    if ! sdcard_ensure_mounted
    then
        TEST_MESSAGE="Unable to mount SD card for sequential read test."
        test_fail
        return
    fi

    SDCARD_TEST_DIR="${SDCARD_MOUNTPOINT}/sdcard_validation"
    SDCARD_TEST_FILE="${SDCARD_TEST_DIR}/sdcard_performance_test.bin"

    if [ ! -f "$SDCARD_TEST_FILE" ]
    then
        TEST_MESSAGE="Sequential write test file not found."
        test_fail
        return
    fi

    run_command \
        "SDCARD-007" \
        "Verify Sequential Read Performance" \
        "dd if=\"$SDCARD_TEST_FILE\" of=/dev/null bs=1M status=progress"

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
# SDCARD-008 : Filesystem Synchronization
###############################################################################

sdcard_008()
{
    log_info "[SDCARD-008] Verify Filesystem Synchronization"

    run_command \
        "SDCARD-008" \
        "Verify Filesystem Synchronization" \
        "sync"

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
# SDCARD-009 : Filesystem Health
###############################################################################

sdcard_009()
{
    log_info "[SDCARD-009] Verify Filesystem Health"

    run_command \
        "SDCARD-009" \
        "Verify Filesystem Health" \
        "sdcard_filesystem_health_check"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="Filesystem health check utility is unavailable or filesystem is unsupported."
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
# SDCARD-010 : FIO Availability
###############################################################################

sdcard_010()
{
    log_info "[SDCARD-010] Verify FIO Availability"

    run_command \
        "SDCARD-010" \
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
# SDCARD-011 : FIO Performance Test
###############################################################################

sdcard_011()
{
    local FIO_FILE

    log_info "[SDCARD-011] Run FIO Performance Test"

    if ! sdcard_ensure_mounted
    then
        TEST_MESSAGE="Unable to mount SD card for fio performance test."
        test_fail
        return
    fi

    SDCARD_TEST_DIR="${SDCARD_MOUNTPOINT}/sdcard_validation"
    FIO_FILE="${SDCARD_TEST_DIR}/sdcard_fio_test.bin"

    mkdir -p "$SDCARD_TEST_DIR"

    run_command \
        "SDCARD-011" \
        "Run FIO Performance Test" \
        "fio --name=sdcard_validation --filename=\"$FIO_FILE\" --size=\"${SDCARD_FIO_SIZE:-256M}\" --rw=randrw --bs=4k --runtime=\"${SDCARD_FIO_RUNTIME:-60}\" --time_based --group_reporting"

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
# SDCARD-012 : Cleanup + Final Unmount
###############################################################################

sdcard_012()
{
    local COMMAND

    log_info "[SDCARD-012] Cleanup SD Card Test Files and Final Unmount"

    COMMAND='
        STATUS=0

        #
        # Synchronize filesystem before cleanup.
        #
        sync || STATUS=1

        #
        # Remove validation directory.
        #
        if [ -n "'"$SDCARD_TEST_DIR"'" ] &&
           [ -d "'"$SDCARD_TEST_DIR"'" ]
        then
            rm -rf "'"$SDCARD_TEST_DIR"'" || STATUS=1
        fi

        #
        # Final unmount only if this validation mounted
        # the SD card.
        #
        if [ "'"$SDCARD_MOUNTED_BY_TEST"'" -eq 1 ] &&
           [ -n "'"$SDCARD_MOUNTPOINT"'" ]
        then
            umount "'"$SDCARD_MOUNTPOINT"'" || STATUS=1
        fi

        exit $STATUS
    '

    run_command \
        "SDCARD-012" \
        "Cleanup SD Card Test Files and Final Unmount" \
        "$COMMAND"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to cleanup SD card validation files or perform final unmount."
        test_fail
        return
    fi

    SDCARD_MOUNTPOINT=""
    SDCARD_DEVICE_PARTITION=""
    SDCARD_MOUNTED_BY_TEST=0
    SDCARD_TEST_DIR=""
    SDCARD_TEST_FILE=""

    TEST_MESSAGE="SD card validation files cleaned and final unmount completed successfully."

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
        -n "Verify SD Card Filesystem & Mount" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "sdcard,filesystem,mount" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SD card filesystem, mount point and read-write status."

    register_test \
        -i "SDCARD-003" \
        -f sdcard_003 \
        -n "Mount SD Card" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "sdcard,mount" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Automatically mount the SD card filesystem when required."

    register_test \
        -i "SDCARD-004" \
        -f sdcard_004 \
        -n "Verify SD Card Read/Write Access" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 40 \
        -g "sdcard,read,write,file" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SD card file creation, write, read and deletion."

    register_test \
        -i "SDCARD-005" \
        -f sdcard_005 \
        -n "Verify SD Card Capacity & Usage" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 50 \
        -g "sdcard,capacity,usage,df" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SD card capacity and filesystem usage."

    register_test \
        -i "SDCARD-006" \
        -f sdcard_006 \
        -n "Verify Sequential Write Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 60 \
        -g "sdcard,dd,write,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure SD card sequential write performance."

    register_test \
        -i "SDCARD-007" \
        -f sdcard_007 \
        -n "Verify Sequential Read Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 70 \
        -g "sdcard,dd,read,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure SD card sequential read performance."

    register_test \
        -i "SDCARD-008" \
        -f sdcard_008 \
        -n "Verify Filesystem Synchronization" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 80 \
        -g "sdcard,sync" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify filesystem buffer synchronization."

    register_test \
        -i "SDCARD-009" \
        -f sdcard_009 \
        -n "Verify Filesystem Health" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 90 \
        -g "sdcard,filesystem,fsck,health" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SD card filesystem integrity using a read-only filesystem check."

    register_test \
        -i "SDCARD-010" \
        -f sdcard_010 \
        -n "Verify FIO Availability" \
        -c "performance" \
        -t "auto" \
        -p "low" \
        -o 100 \
        -g "sdcard,fio" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify fio utility availability."

    register_test \
        -i "SDCARD-011" \
        -f sdcard_011 \
        -n "Run FIO Performance Test" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 110 \
        -g "sdcard,fio,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Run fio random read/write performance benchmark."

    register_test \
        -i "SDCARD-012" \
        -f sdcard_012 \
        -n "Cleanup SD Card Test Files and Final Unmount" \
        -c "storage" \
        -t "auto" \
        -p "low" \
        -o 120 \
        -g "sdcard,cleanup,unmount" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Remove temporary SD card validation files and perform final unmount."
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
    # SDCARD_DEVICE comes from config.sh.
    #
    # Do not call test_fail() here because this is not a registered test.
    # SDCARD-001 owns SD card device validation.
    #
    if [ -z "$SDCARD_DEVICE" ]
    then
        TEST_MESSAGE="SDCARD_DEVICE is not configured."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    log_info "Configured SD Card Device : $SDCARD_DEVICE"

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
