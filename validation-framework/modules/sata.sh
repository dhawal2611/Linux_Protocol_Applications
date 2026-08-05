#!/bin/bash
###############################################################################
# File        : sata.sh
# Description : SATA Storage Validation Module
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="SATA"
MODULE_DESCRIPTION="SATA Storage Validation"

###############################################################################
# SATA Runtime Variables
###############################################################################

SATA_MOUNTPOINT=""
SATA_DEVICE_PARTITION=""
SATA_MOUNTED_BY_TEST=0

SATA_TEST_DIR=""
SATA_TEST_FILE=""

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
    dmesg
    hdparm
)

###############################################################################
# Helper Functions
###############################################################################

###############################################################################
# Check SATA device
###############################################################################

sata_device_exists()
{
    [ -b "$SATA_DEVICE" ]
}

###############################################################################
# Get SATA device name
###############################################################################

sata_get_device_name()
{
    lsblk -dn -o NAME "$SATA_DEVICE"
}

###############################################################################
# Get SATA device size
###############################################################################

sata_get_size()
{
    lsblk -dn -o SIZE "$SATA_DEVICE"
}

###############################################################################
# Get SATA device type
###############################################################################

sata_get_type()
{
    lsblk -dn -o TYPE "$SATA_DEVICE"
}

###############################################################################
# Get SATA model
###############################################################################

sata_get_model()
{
    lsblk -dn -o MODEL "$SATA_DEVICE"
}

###############################################################################
# Get SATA transport
###############################################################################

sata_get_transport()
{
    lsblk -dn -o TRAN "$SATA_DEVICE"
}

###############################################################################
# Find filesystem-bearing SATA device
###############################################################################

sata_get_filesystem_device()
{
    local DEVICE="$SATA_DEVICE"
    local FSTYPE
    local FS_DEVICE

    FSTYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)

    if [ -n "$FSTYPE" ]
    then
        echo "$DEVICE"
        return 0
    fi

    FS_DEVICE=$(lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICE" 2>/dev/null |
        awk '$3 != "" {print "/dev/" $1; exit}')

    if [ -n "$FS_DEVICE" ]
    then
        echo "$FS_DEVICE"
        return 0
    fi

    return 1
}

###############################################################################
# Get SATA filesystem
###############################################################################

sata_get_filesystem()
{
    local DEVICE

    DEVICE=$(sata_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    blkid -o value -s TYPE "$DEVICE" 2>/dev/null
}

###############################################################################
# Get SATA mount point
###############################################################################

sata_get_mountpoint()
{
    local DEVICE
    local MOUNTPOINT

    if [ -n "$SATA_MOUNTPOINT" ]
    then
        echo "$SATA_MOUNTPOINT"
        return 0
    fi

    DEVICE=$(sata_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    MOUNTPOINT=$(findmnt -n -S "$DEVICE" -o TARGET 2>/dev/null)

    if [ -n "$MOUNTPOINT" ]
    then
        echo "$MOUNTPOINT"
        return 0
    fi

    return 1
}

###############################################################################
# Check SATA mounted state
###############################################################################

sata_is_mounted()
{
    local DEVICE

    DEVICE=$(sata_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    findmnt -n -S "$DEVICE" >/dev/null 2>&1
}

###############################################################################
# Check SATA filesystem read/write
###############################################################################

sata_is_rw()
{
    local MOUNTPOINT="$1"

    if [ -z "$MOUNTPOINT" ]
    then
        return 1
    fi

    findmnt -n -T "$MOUNTPOINT" -o OPTIONS 2>/dev/null |
        grep -qw rw
}

###############################################################################
# Create SATA validation directory
###############################################################################

sata_create_test_directory()
{
    if [ -z "$SATA_MOUNTPOINT" ]
    then
        return 1
    fi

    SATA_TEST_DIR="${SATA_MOUNTPOINT}/sata_validation"

    mkdir -p "$SATA_TEST_DIR"
}

###############################################################################
# Mount SATA filesystem
###############################################################################

sata_mount_for_test()
{
    local DEVICE
    local EXISTING_MOUNT
    local MOUNTPOINT

    DEVICE=$(sata_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        echo "ERROR: No filesystem-bearing SATA device found."
        return 1
    fi

    EXISTING_MOUNT=$(findmnt -n -S "$DEVICE" -o TARGET 2>/dev/null)

    if [ -n "$EXISTING_MOUNT" ]
    then
        SATA_DEVICE_PARTITION="$DEVICE"
        SATA_MOUNTPOINT="$EXISTING_MOUNT"
        SATA_MOUNTED_BY_TEST=0

        echo "MOUNT_DEVICE=$SATA_DEVICE_PARTITION"
        echo "MOUNTPOINT=$SATA_MOUNTPOINT"
        echo "MOUNTED_BY_TEST=0"

        return 0
    fi

    if [ -n "$SATA_MOUNTPOINT_PATH" ]
    then
        MOUNTPOINT="$SATA_MOUNTPOINT_PATH"
    else
        MOUNTPOINT="/mnt/sata_validation"
    fi

    mkdir -p "$MOUNTPOINT"

    if ! mount "$DEVICE" "$MOUNTPOINT"
    then
        echo "ERROR: Failed to mount $DEVICE on $MOUNTPOINT."
        return 1
    fi

    SATA_DEVICE_PARTITION="$DEVICE"
    SATA_MOUNTPOINT="$MOUNTPOINT"
    SATA_MOUNTED_BY_TEST=1

    echo "MOUNT_DEVICE=$SATA_DEVICE_PARTITION"
    echo "MOUNTPOINT=$SATA_MOUNTPOINT"
    echo "MOUNTED_BY_TEST=1"

    return 0
}

###############################################################################
# Ensure SATA filesystem is mounted
###############################################################################

sata_ensure_mounted()
{
    if [ -n "$SATA_MOUNTPOINT" ] &&
       findmnt -n -T "$SATA_MOUNTPOINT" >/dev/null 2>&1
    then
        return 0
    fi

    sata_mount_for_test
}

###############################################################################
# SATA kernel message command
###############################################################################

sata_cmd_kernel_messages()
{
    dmesg | grep -i sata
}

###############################################################################
# SATA device information command
###############################################################################

sata_cmd_device_info()
{
    lsblk -o NAME,MODEL,SIZE,TYPE,FSTYPE,TRAN,MOUNTPOINT "$SATA_DEVICE"
}

###############################################################################
# SATA filesystem information command
###############################################################################

sata_cmd_filesystem_info()
{
    local DEVICE

    DEVICE=$(sata_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        echo "ERROR: Unable to determine filesystem-bearing SATA device."
        return 1
    fi

    echo "DEVICE=$DEVICE"
    echo "FILESYSTEM=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)"
    echo "MOUNTPOINT=$(findmnt -n -S "$DEVICE" -o TARGET 2>/dev/null)"

    findmnt -n -S "$DEVICE" -o SOURCE,TARGET,FSTYPE,OPTIONS 2>/dev/null
}

###############################################################################
# SATA capacity command
###############################################################################

sata_cmd_capacity()
{
    local MOUNTPOINT

    MOUNTPOINT=$(sata_get_mountpoint)

    lsblk -dn -o NAME,SIZE,TYPE "$SATA_DEVICE"

    if [ -n "$MOUNTPOINT" ]
    then
        df -h "$MOUNTPOINT"
    fi
}

###############################################################################
# SATA read/write access command
###############################################################################

sata_cmd_rw()
{
    local TEST_FILE

    if ! sata_ensure_mounted
    then
        return 1
    fi

    sata_create_test_directory || return 1

    TEST_FILE="${SATA_TEST_DIR}/sata_rw_test.txt"
    SATA_TEST_FILE="$TEST_FILE"

    touch "$TEST_FILE" &&
    echo "SATA Storage Validation Framework" > "$TEST_FILE" &&
    grep -q "SATA Storage Validation Framework" "$TEST_FILE" &&
    cat "$TEST_FILE" &&
    rm -f "$TEST_FILE" &&
    [ ! -f "$TEST_FILE" ]
}

###############################################################################
# SATA sequential write command
###############################################################################

sata_cmd_sequential_write()
{
    if ! sata_ensure_mounted
    then
        return 1
    fi

    sata_create_test_directory || return 1

    SATA_TEST_FILE="${SATA_TEST_DIR}/sata_performance_test.bin"

    dd if=/dev/zero \
       of="$SATA_TEST_FILE" \
       bs=1M \
       count="${SATA_DD_COUNT:-100}" \
       conv=fsync \
       status=progress
}

###############################################################################
# SATA sequential read command
###############################################################################

sata_cmd_sequential_read()
{
    if ! sata_ensure_mounted
    then
        return 1
    fi

    if [ -z "$SATA_TEST_FILE" ]
    then
        SATA_TEST_FILE="${SATA_MOUNTPOINT}/sata_validation/sata_performance_test.bin"
    fi

    if [ ! -f "$SATA_TEST_FILE" ]
    then
        echo "ERROR: SATA sequential write test file not found."
        return 1
    fi

    dd if="$SATA_TEST_FILE" \
       of=/dev/null \
       bs=1M \
       status=progress
}

###############################################################################
# SATA hdparm throughput command
###############################################################################

sata_cmd_hdparm()
{
    hdparm -tT "$SATA_DEVICE"
}

###############################################################################
# SATA sync command
###############################################################################

sata_cmd_sync()
{
    sync
}

###############################################################################
# SATA filesystem health command
###############################################################################

sata_filesystem_health_check()
{
    local DEVICE
    local FS_TYPE

    DEVICE=$(sata_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        echo "ERROR: Unable to determine filesystem-bearing SATA device."
        return 2
    fi

    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)

    if [ -z "$FS_TYPE" ]
    then
        echo "ERROR: Unable to determine SATA filesystem type."
        return 2
    fi

    echo "FILESYSTEM=$FS_TYPE"
    echo "CHECK_DEVICE=$DEVICE"

    case "$FS_TYPE" in

        ext2|ext3|ext4)
            fsck -N "$DEVICE"
            ;;

        xfs)
            if ! command -v xfs_repair >/dev/null 2>&1
            then
                echo "SKIP: xfs_repair utility is not installed."
                return 3
            fi

            xfs_repair -n "$DEVICE"
            ;;

        btrfs)
            if ! command -v btrfs >/dev/null 2>&1
            then
                echo "SKIP: btrfs utility is not installed."
                return 3
            fi

            btrfs check --readonly "$DEVICE"
            ;;

        vfat|fat|fat16|fat32)
            if ! command -v fsck.fat >/dev/null 2>&1
            then
                echo "SKIP: fsck.fat utility is not installed."
                return 3
            fi

            fsck.fat -n "$DEVICE"
            ;;

        exfat)
            if command -v fsck.exfat >/dev/null 2>&1
            then
                fsck.exfat -n "$DEVICE"
            elif command -v exfatfsck >/dev/null 2>&1
            then
                exfatfsck -n "$DEVICE"
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
# FIO availability command
###############################################################################

sata_cmd_fio_available()
{
    command -v fio
}

###############################################################################
# FIO performance command
###############################################################################

sata_cmd_fio()
{
    local FIO_FILE

    if ! sata_ensure_mounted
    then
        return 1
    fi

    sata_create_test_directory || return 1

    FIO_FILE="${SATA_TEST_DIR}/sata_fio_test.bin"

    fio \
        --name=sata_validation \
        --filename="$FIO_FILE" \
        --size="${SATA_FIO_SIZE:-256M}" \
        --rw=randrw \
        --bs=4k \
        --runtime="${SATA_FIO_RUNTIME:-60}" \
        --time_based \
        --group_reporting
}

###############################################################################
# SATA cleanup command
###############################################################################

sata_cmd_cleanup()
{
    local STATUS=0
    local CLEANUP_DIR=""
    local MOUNTPOINT=""

    echo "SATA_DEVICE=$SATA_DEVICE"
    echo "SATA_MOUNTPOINT=$SATA_MOUNTPOINT"
    echo "SATA_TEST_DIR=$SATA_TEST_DIR"
    echo "SATA_MOUNTED_BY_TEST=$SATA_MOUNTED_BY_TEST"

    ###########################################################################
    # Determine validation directory
    ###########################################################################

    if [ -n "$SATA_TEST_DIR" ]
    then
        CLEANUP_DIR="$SATA_TEST_DIR"
    elif [ -n "$SATA_MOUNTPOINT" ]
    then
        CLEANUP_DIR="${SATA_MOUNTPOINT}/sata_validation"
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
    # Only unmount when validation mounted the SATA filesystem.
    ###########################################################################

    if [ "$SATA_MOUNTED_BY_TEST" -eq 1 ] &&
       [ -n "$SATA_MOUNTPOINT" ]
    then
        MOUNTPOINT="$SATA_MOUNTPOINT"

        echo "SATA filesystem was mounted by validation."
        echo "Unmounting $MOUNTPOINT"

        umount "$MOUNTPOINT"

        if [ $? -ne 0 ]
        then
            echo "ERROR: Failed to unmount $MOUNTPOINT"
            STATUS=1
        else
            echo "SATA filesystem unmounted successfully."

            if findmnt -n -T "$MOUNTPOINT" >/dev/null 2>&1
            then
                echo "ERROR: SATA filesystem is still mounted."
                STATUS=1
            else
                echo "Final unmount verified successfully."
            fi
        fi
    else
        echo "SATA filesystem was not mounted by validation."
        echo "Existing system mount will not be unmounted."
    fi

    return "$STATUS"
}

###############################################################################
# SATA-001 : Check SATA Kernel Messages
###############################################################################

sata_001()
{
    log_info "[SATA-001] Check SATA Kernel Messages"

    run_command \
        "SATA-001" \
        "Check SATA Kernel Messages" \
        "sata_cmd_kernel_messages"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to find SATA messages in kernel log."
        test_fail
        return
    fi

    TEST_MESSAGE="SATA kernel messages detected successfully."

    test_pass
}

###############################################################################
# SATA-002 : Detect & Verify SATA Device
###############################################################################

sata_002()
{
    local DEVICE_NAME
    local SIZE
    local TYPE

    log_info "[SATA-002] Detect & Verify SATA Device"

    run_command \
        "SATA-002" \
        "Detect & Verify SATA Device" \
        "sata_cmd_device_info"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to detect SATA device ${SATA_DEVICE}."
        test_fail
        return
    fi

    DEVICE_NAME=$(sata_get_device_name)
    SIZE=$(sata_get_size)
    TYPE=$(sata_get_type)

    if [ -z "$DEVICE_NAME" ]
    then
        TEST_MESSAGE="Unable to determine SATA device name."
        test_fail
        return
    fi

    if [ -z "$SIZE" ]
    then
        TEST_MESSAGE="Unable to determine SATA device size."
        test_fail
        return
    fi

    if [ -z "$TYPE" ]
    then
        TEST_MESSAGE="Unable to determine SATA device type."
        test_fail
        return
    fi

    TEST_MESSAGE="Device=${DEVICE_NAME}, Size=${SIZE}, Type=${TYPE}"

    test_pass
}

###############################################################################
# SATA-003 : Verify SATA Device Information
###############################################################################

sata_003()
{
    local MODEL
    local TRANSPORT

    log_info "[SATA-003] Verify SATA Device Information"

    run_command \
        "SATA-003" \
        "Verify SATA Device Information" \
        "sata_cmd_device_info"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to read SATA device information."
        test_fail
        return
    fi

    MODEL=$(sata_get_model)
    TRANSPORT=$(sata_get_transport)

    TEST_MESSAGE="Model=${MODEL:-N/A}, Transport=${TRANSPORT:-N/A}"

    test_pass
}

###############################################################################
# SATA-004 : Verify SATA Filesystem & Mount
###############################################################################

sata_004()
{
    local DEVICE
    local FILESYSTEM

    log_info "[SATA-004] Verify SATA Filesystem & Mount"

    DEVICE=$(sata_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        TEST_MESSAGE="Unable to determine SATA filesystem-bearing device."
        test_fail
        return
    fi

    FILESYSTEM=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)

    if [ -z "$FILESYSTEM" ]
    then
        TEST_MESSAGE="Unable to determine SATA filesystem type."
        test_fail
        return
    fi

    run_command \
        "SATA-004" \
        "Verify SATA Filesystem & Mount" \
        "sata_cmd_filesystem_info"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to verify SATA filesystem and mount information."
        test_fail
        return
    fi

    TEST_MESSAGE="Filesystem=${FILESYSTEM}, Device=${DEVICE}, Mount=${SATA_MOUNTPOINT:-Not currently mounted}"

    test_pass
}

###############################################################################
# SATA-005 : Verify SATA Capacity & Usage
###############################################################################

sata_005()
{
    log_info "[SATA-005] Verify SATA Capacity & Usage"

    if ! sata_ensure_mounted
    then
        TEST_MESSAGE="Unable to mount SATA filesystem for capacity validation."
        test_fail
        return
    fi

    run_command \
        "SATA-005" \
        "Verify SATA Capacity & Usage" \
        "sata_cmd_capacity"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine SATA capacity or usage."
        test_fail
        return
    fi

    TEST_MESSAGE="SATA capacity and filesystem usage verified."

    test_pass
}

###############################################################################
# SATA-006 : Verify SATA Read / Write Access
###############################################################################

sata_006()
{
    log_info "[SATA-006] Verify SATA Read / Write Access"

    run_command \
        "SATA-006" \
        "Verify SATA Read / Write Access" \
        "sata_cmd_rw"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SATA file create/write/read/delete validation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="SATA file create, write, read and delete operations verified."

    test_pass
}

###############################################################################
# SATA-007 : Sequential Write Performance
###############################################################################

sata_007()
{
    log_info "[SATA-007] Sequential Write Performance"

    run_command \
        "SATA-007" \
        "Sequential Write Performance" \
        "sata_cmd_sequential_write"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SATA sequential write performance test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="SATA sequential write completed successfully."

    test_pass
}

###############################################################################
# SATA-008 : Sequential Read Performance
###############################################################################

sata_008()
{
    log_info "[SATA-008] Sequential Read Performance"

    run_command \
        "SATA-008" \
        "Sequential Read Performance" \
        "sata_cmd_sequential_read"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SATA sequential read performance test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="SATA sequential read completed successfully."

    test_pass
}

###############################################################################
# SATA-009 : SATA Throughput Test
###############################################################################

sata_009()
{
    log_info "[SATA-009] SATA Throughput Test"

    run_command \
        "SATA-009" \
        "SATA Throughput Test" \
        "sata_cmd_hdparm"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SATA hdparm throughput test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="SATA hdparm throughput test completed successfully."

    test_pass
}

###############################################################################
# SATA-010 : Filesystem Synchronization
###############################################################################

sata_010()
{
    log_info "[SATA-010] Filesystem Synchronization"

    run_command \
        "SATA-010" \
        "Filesystem Synchronization" \
        "sata_cmd_sync"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SATA filesystem synchronization failed."
        test_fail
        return
    fi

    TEST_MESSAGE="SATA filesystem synchronized successfully."

    test_pass
}

###############################################################################
# SATA-011 : Filesystem Health
###############################################################################

sata_011()
{
    log_info "[SATA-011] Filesystem Health"

    run_command \
        "SATA-011" \
        "Filesystem Health" \
        "sata_filesystem_health_check"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="Filesystem health-check utility is unavailable or filesystem is unsupported."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="SATA filesystem health verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="SATA filesystem health verification completed successfully."

    test_pass
}

###############################################################################
# SATA-012 : FIO Availability
###############################################################################

sata_012()
{
    log_info "[SATA-012] FIO Availability"

    run_command \
        "SATA-012" \
        "FIO Availability" \
        "sata_cmd_fio_available"

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
# SATA-013 : FIO Performance
###############################################################################

sata_013()
{
    log_info "[SATA-013] FIO Performance"

    run_command \
        "SATA-013" \
        "FIO Read/Write Performance" \
        "sata_cmd_fio"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="fio SATA random read/write performance test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="fio SATA random read/write performance test completed successfully."

    test_pass
}

###############################################################################
# SATA-014 : Cleanup + Final Unmount
###############################################################################

sata_014()
{
    log_info "[SATA-014] Cleanup + Final Unmount"

    run_command \
        "SATA-014" \
        "Cleanup + Final Unmount" \
        "sata_cmd_cleanup"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to cleanup SATA validation files or perform final unmount."
        test_fail
        return
    fi

    SATA_MOUNTPOINT=""
    SATA_DEVICE_PARTITION=""
    SATA_MOUNTED_BY_TEST=0
    SATA_TEST_DIR=""
    SATA_TEST_FILE=""

    TEST_MESSAGE="SATA validation files cleaned and final unmount completed successfully."

    test_pass
}

###############################################################################
# Register SATA Tests
###############################################################################

sata_register_tests()
{
    register_test \
        -i "SATA-001" \
        -f sata_001 \
        -n "Check SATA Kernel Messages" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 10 \
        -g "sata,storage,dmesg,kernel" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Check kernel messages for SATA controller and device detection."

    register_test \
        -i "SATA-002" \
        -f sata_002 \
        -n "Detect & Verify SATA Device" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "sata,storage,lsblk,device" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Detect SATA device and verify basic device information."

    register_test \
        -i "SATA-003" \
        -f sata_003 \
        -n "Verify SATA Device Information" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "sata,storage,model,transport" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SATA device model, transport and block-device information."

    register_test \
        -i "SATA-004" \
        -f sata_004 \
        -n "Verify SATA Filesystem & Mount" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "sata,filesystem,mount,blkid,findmnt" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SATA filesystem, mount point and mount information."

    register_test \
        -i "SATA-005" \
        -f sata_005 \
        -n "Verify SATA Capacity & Usage" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "sata,capacity,usage,df" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SATA capacity and filesystem usage."

    register_test \
        -i "SATA-006" \
        -f sata_006 \
        -n "Verify SATA Read / Write Access" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 30 \
        -g "sata,read,write,file" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify SATA file creation, write, read and deletion."

    register_test \
        -i "SATA-007" \
        -f sata_007 \
        -n "Sequential Write Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 300 \
        -g "sata,dd,write,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure SATA filesystem sequential write performance using dd."

    register_test \
        -i "SATA-008" \
        -f sata_008 \
        -n "Sequential Read Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 300 \
        -g "sata,dd,read,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure SATA filesystem sequential read performance using dd."

    register_test \
        -i "SATA-009" \
        -f sata_009 \
        -n "SATA Throughput Test" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 300 \
        -g "sata,hdparm,throughput,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure SATA device read throughput using hdparm."

    register_test \
        -i "SATA-010" \
        -f sata_010 \
        -n "Filesystem Synchronization" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "sata,sync,filesystem" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Flush SATA filesystem buffers using sync."

    register_test \
        -i "SATA-011" \
        -f sata_011 \
        -n "Filesystem Health" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 120 \
        -g "sata,filesystem,fsck,health" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Perform a read-only SATA filesystem health check."

    register_test \
        -i "SATA-012" \
        -f sata_012 \
        -n "FIO Availability" \
        -c "performance" \
        -t "auto" \
        -p "low" \
        -o 10 \
        -g "sata,fio" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify fio utility availability."

    register_test \
        -i "SATA-013" \
        -f sata_013 \
        -n "FIO Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 600 \
        -g "sata,fio,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Run fio random read/write SATA performance benchmark."

    register_test \
        -i "SATA-014" \
        -f sata_014 \
        -n "Cleanup + Final Unmount" \
        -c "storage" \
        -t "auto" \
        -p "low" \
        -o 30 \
        -g "sata,cleanup,unmount,sync" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Remove SATA validation files, synchronize filesystem and perform final unmount when mounted by validation."
}

###############################################################################
# Module Initialization
###############################################################################

sata_init()
{
    log_info "========================================="
    log_info "Starting SATA Validation"
    log_info "========================================="

    #
    # SATA_DEVICE comes from config.sh.
    #
    # Example:
    # SATA_DEVICE="/dev/sda"
    #
    if [ -z "$SATA_DEVICE" ]
    then
        TEST_MESSAGE="SATA_DEVICE is not configured."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    log_info "Configured SATA Device : $SATA_DEVICE"

    sata_register_tests

    return 0
}

###############################################################################
# Module Initialization When Sourced
###############################################################################

sata_init

###############################################################################
# End Of File
###############################################################################
