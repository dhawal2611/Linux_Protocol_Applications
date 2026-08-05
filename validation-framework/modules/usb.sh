#!/bin/bash
###############################################################################
# File        : usb.sh
# Description : USB Storage Validation Module
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="USB"
MODULE_DESCRIPTION="USB Storage Validation"

###############################################################################
# USB Runtime Variables
###############################################################################

USB_DEVICE_PARTITION=""
USB_MOUNTPOINT=""
USB_MOUNTED_BY_TEST=0

USB_TEST_DIR=""
USB_TEST_FILE=""
USB_PERFORMANCE_FILE=""
USB_FIO_FILE=""

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    lsusb
    lsblk
    blkid
    df
    findmnt
    mount
    umount
    mkdir
    touch
    echo
    cat
    grep
    rm
    dd
    sync
    dmesg
    awk
    tr
)

###############################################################################
# Helper Functions
###############################################################################

###############################################################################
# Check USB device
###############################################################################

usb_device_exists()
{
    [ -b "$USB_DEVICE" ]
}

###############################################################################
# Get filesystem-bearing USB device
###############################################################################

usb_get_filesystem_device()
{
    local DEVICE="$USB_DEVICE"

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    #
    # If configured device itself has a filesystem.
    #
    if blkid "$DEVICE" 2>/dev/null | grep -q "TYPE="
    then
        echo "$DEVICE"
        return 0
    fi

    #
    # Otherwise check child partitions.
    #
    lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICE" 2>/dev/null |
        awk '$3 != "" {print "/dev/" $1; exit}'
}

###############################################################################
# Get filesystem type
###############################################################################

usb_get_filesystem()
{
    local DEVICE="$1"

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    blkid -o value -s TYPE "$DEVICE" 2>/dev/null
}

###############################################################################
# Get existing USB mount point
###############################################################################

usb_get_mountpoint()
{
    local DEVICE="$1"

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    findmnt -n -S "$DEVICE" -o TARGET 2>/dev/null
}

###############################################################################
# Check whether USB filesystem is mounted
###############################################################################

usb_is_mounted()
{
    local DEVICE
    local MOUNTPOINT

    DEVICE=$(usb_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    MOUNTPOINT=$(usb_get_mountpoint "$DEVICE")

    [ -n "$MOUNTPOINT" ]
}

###############################################################################
# Ensure USB filesystem is mounted
#
# IMPORTANT:
# If already mounted, reuse the existing mount point.
# Do NOT create another mount point.
###############################################################################

usb_mount_for_test()
{
    local DEVICE
    local EXISTING_MOUNT
    local MOUNTPOINT

    DEVICE=$(usb_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        echo "ERROR: Unable to determine USB filesystem device."
        return 1
    fi

    echo "USB filesystem device : $DEVICE"

    #
    # Check existing mount first.
    #
    EXISTING_MOUNT=$(usb_get_mountpoint "$DEVICE")

    if [ -n "$EXISTING_MOUNT" ]
    then
        USB_DEVICE_PARTITION="$DEVICE"
        USB_MOUNTPOINT="$EXISTING_MOUNT"
        USB_MOUNTED_BY_TEST=0

        echo "USB filesystem is already mounted."
        echo "MOUNT_DEVICE=$USB_DEVICE_PARTITION"
        echo "MOUNTPOINT=$USB_MOUNTPOINT"
        echo "MOUNTED_BY_TEST=0"

        return 0
    fi

    #
    # No existing mount.
    #
    MOUNTPOINT="/mnt/usb_validation"

    #
    # Creating /mnt/usb_validation may require root.
    #
    if [ ! -d "$MOUNTPOINT" ]
    then
        if ! mkdir -p "$MOUNTPOINT"
        then
            echo "SKIP: Unable to create $MOUNTPOINT."
            echo "SKIP: USB filesystem is not mounted and mount point creation requires permission."
            return 3
        fi
    fi

    #
    # Mount USB filesystem.
    #
    if ! mount "$DEVICE" "$MOUNTPOINT"
    then
        echo "SKIP: Unable to mount $DEVICE on $MOUNTPOINT."
        return 3
    fi

    USB_DEVICE_PARTITION="$DEVICE"
    USB_MOUNTPOINT="$MOUNTPOINT"
    USB_MOUNTED_BY_TEST=1

    echo "USB filesystem mounted successfully."
    echo "MOUNT_DEVICE=$USB_DEVICE_PARTITION"
    echo "MOUNTPOINT=$USB_MOUNTPOINT"
    echo "MOUNTED_BY_TEST=1"

    return 0
}

###############################################################################
# Ensure USB filesystem is mounted
###############################################################################

usb_ensure_mounted()
{
    local DEVICE
    local EXISTING_MOUNT

    #
    # Reuse runtime mount point if still valid.
    #
    if [ -n "$USB_MOUNTPOINT" ]
    then
        if findmnt -n -T "$USB_MOUNTPOINT" >/dev/null 2>&1
        then
            return 0
        fi
    fi

    #
    # Determine filesystem device.
    #
    DEVICE=$(usb_get_filesystem_device)

    if [ -z "$DEVICE" ]
    then
        return 1
    fi

    #
    # IMPORTANT:
    # Always check actual system mount before attempting mount.
    #
    EXISTING_MOUNT=$(usb_get_mountpoint "$DEVICE")

    if [ -n "$EXISTING_MOUNT" ]
    then
        USB_DEVICE_PARTITION="$DEVICE"
        USB_MOUNTPOINT="$EXISTING_MOUNT"
        USB_MOUNTED_BY_TEST=0

        return 0
    fi

    usb_mount_for_test
}

###############################################################################
# Create USB validation directory
###############################################################################

usb_create_test_directory()
{
    if [ -z "$USB_MOUNTPOINT" ]
    then
        return 1
    fi

    USB_TEST_DIR="${USB_MOUNTPOINT}/usb_validation"

    mkdir -p "$USB_TEST_DIR"
}

###############################################################################
# Cleanup USB validation directory
###############################################################################

usb_cleanup_test_directory()
{
    if [ -n "$USB_TEST_DIR" ] &&
       [ -d "$USB_TEST_DIR" ]
    then
        rm -rf "$USB_TEST_DIR"
    else
        if [ -n "$USB_MOUNTPOINT" ] &&
           [ -d "${USB_MOUNTPOINT}/usb_validation" ]
        then
            rm -rf "${USB_MOUNTPOINT}/usb_validation"
        fi
    fi
}

###############################################################################
# Verify USB mount is read-write
###############################################################################

usb_is_rw()
{
    local MOUNTPOINT="$1"
    local OPTIONS

    if [ -z "$MOUNTPOINT" ]
    then
        return 1
    fi

    OPTIONS=$(findmnt -n -T "$MOUNTPOINT" -o OPTIONS 2>/dev/null)

    echo "MOUNT_OPTIONS=$OPTIONS"

    echo "$OPTIONS" | grep -qw rw
}

###############################################################################
# Synchronous filesystem flush
###############################################################################

usb_sync()
{
    sync
}

###############################################################################
# Filesystem health helper
###############################################################################

usb_filesystem_health_check()
{
    local DEVICE="$USB_DEVICE"
    local CHECK_DEVICE
    local FS_TYPE

    #
    # Determine filesystem-bearing device.
    #
    CHECK_DEVICE=$(usb_get_filesystem_device)

    if [ -z "$CHECK_DEVICE" ]
    then
        echo "ERROR: Unable to determine USB filesystem device."
        return 2
    fi

    #
    # Determine filesystem type.
    #
    FS_TYPE=$(usb_get_filesystem "$CHECK_DEVICE")

    if [ -z "$FS_TYPE" ]
    then
        echo "SKIP: Unable to determine filesystem type."
        return 3
    fi

    echo "FILESYSTEM=$FS_TYPE"
    echo "CHECK_DEVICE=$CHECK_DEVICE"

    case "$FS_TYPE" in

        ext2|ext3|ext4)
            fsck -N "$CHECK_DEVICE"
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

        *)
            echo "SKIP: Filesystem $FS_TYPE is not supported."
            return 3
            ;;

    esac
}

###############################################################################

# USB Cleanup Command Helper

###############################################################################

usb_cmd_cleanup()
{
    local STATUS=0
    local CLEANUP_DIR=""
    local MOUNTPOINT=""

    if [ -n "$USB_TEST_DIR" ]
    then
        CLEANUP_DIR="$USB_TEST_DIR"
    elif [ -n "$USB_MOUNTPOINT" ]
    then
        CLEANUP_DIR="${USB_MOUNTPOINT}/usb_validation"
    fi

    echo "USB_DEVICE=$USB_DEVICE"
    echo "USB_DEVICE_PARTITION=$USB_DEVICE_PARTITION"
    echo "USB_MOUNTPOINT=$USB_MOUNTPOINT"
    echo "USB_TEST_DIR=$USB_TEST_DIR"
    echo "USB_MOUNTED_BY_TEST=$USB_MOUNTED_BY_TEST"
    echo "CLEANUP_DIR=$CLEANUP_DIR"

    if [ -n "$CLEANUP_DIR" ] &&
       [ -d "$CLEANUP_DIR" ]
    then
        rm -rf "$CLEANUP_DIR"

        if [ $? -ne 0 ]
        then
            echo "ERROR: Failed to remove validation directory."
            STATUS=1
        else
            echo "Validation directory removed successfully."
        fi
    else
        echo "Validation directory does not exist. Nothing to remove."
    fi

    sync

    if [ $? -ne 0 ]
    then
        echo "ERROR: Filesystem synchronization failed."
        STATUS=1
    else
        echo "Filesystem synchronized successfully."
    fi

    if [ "$USB_MOUNTED_BY_TEST" -eq 1 ] &&
       [ -n "$USB_MOUNTPOINT" ]
    then
        MOUNTPOINT="$USB_MOUNTPOINT"

        echo "USB filesystem was mounted by validation."
        echo "Unmounting $MOUNTPOINT"

        umount "$MOUNTPOINT"

        if [ $? -ne 0 ]
        then
            echo "ERROR: Failed to unmount $MOUNTPOINT."
            STATUS=1
        else
            echo "USB filesystem unmounted successfully."

            if findmnt -n -T "$MOUNTPOINT" >/dev/null 2>&1
            then
                echo "ERROR: USB filesystem is still mounted."
                STATUS=1
            else
                echo "Final unmount verified successfully."
            fi
        fi
    else
        echo "USB filesystem was not mounted by validation."
        echo "Existing system/user mount will not be unmounted."
    fi

    return "$STATUS"
}

###############################################################################
# USB-001
# Enumerate USB Controllers
###############################################################################

usb_001()
{
    log_info "[USB-001] Enumerate USB Controllers"

    run_command \
        "USB-001" \
        "Enumerate USB Controllers" \
        "lsusb -t"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to enumerate USB controllers."
        test_fail
        return
    fi

    TEST_MESSAGE="USB controllers enumerated successfully."

    test_pass
}

###############################################################################
# USB-002
# List USB Devices
###############################################################################

usb_002()
{
    log_info "[USB-002] List USB Devices"

    run_command \
        "USB-002" \
        "List USB Devices" \
        "lsusb"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to enumerate USB devices."
        test_fail
        return
    fi

    TEST_MESSAGE="USB devices enumerated successfully."

    test_pass
}

###############################################################################

# USB-003 : Mount USB Drive

###############################################################################

usb_003()
{
    log_info "[USB-003] Mount USB Drive"

    run_command \
        "USB-003" \
        "Mount USB Drive" \
        "usb_mount_for_test"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to mount or detect mounted USB filesystem."
        test_fail
        return
    fi

    USB_DEVICE_PARTITION=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNT_DEVICE=/{print $2}')

    USB_MOUNTPOINT=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNTPOINT=/{print $2}')

    USB_MOUNTED_BY_TEST=$(echo "$COMMAND_OUTPUT" |
        awk -F= '/^MOUNTED_BY_TEST=/{print $2}')

    if [ -z "$USB_MOUNTPOINT" ]
    then
        TEST_MESSAGE="USB mount point could not be determined."
        test_fail
        return
    fi

    if ! findmnt -n -T "$USB_MOUNTPOINT" >/dev/null 2>&1
    then
        TEST_MESSAGE="USB filesystem is not mounted at ${USB_MOUNTPOINT}."
        test_fail
        return
    fi

    if [ "$USB_MOUNTED_BY_TEST" = "0" ]
    then
        TEST_MESSAGE="USB filesystem was already mounted at ${USB_MOUNTPOINT}. Existing mount reused."
    else
        TEST_MESSAGE="USB filesystem successfully mounted at ${USB_MOUNTPOINT} by validation."
    fi

    test_pass
}

###############################################################################
# USB-004
# Verify USB Read / Write Access
###############################################################################

usb_004()
{
    local TEST_FILE
    local TEST_STRING

    log_info "[USB-004] Verify USB Read / Write Access"

    if ! usb_ensure_mounted
    then
        TEST_MESSAGE="Unable to access mounted USB filesystem."
        test_fail
        return
    fi

    echo "USB_DEVICE=$USB_DEVICE_PARTITION"
    echo "USB_MOUNTPOINT=$USB_MOUNTPOINT"

    if ! usb_create_test_directory
    then
        TEST_MESSAGE="Unable to create USB validation directory: ${USB_MOUNTPOINT}/usb_validation"
        test_fail
        return
    fi

    TEST_FILE="${USB_TEST_DIR}/usb_rw_test.txt"
    TEST_STRING="USB Storage Validation Framework"

    USB_TEST_FILE="$TEST_FILE"

    run_command \
        "USB-004" \
        "Verify USB Read / Write Access" \
        "touch \"$TEST_FILE\" && echo \"$TEST_STRING\" > \"$TEST_FILE\" && cat \"$TEST_FILE\" && grep -q \"$TEST_STRING\" \"$TEST_FILE\" && rm -f \"$TEST_FILE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="USB file create/write/read/delete validation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="USB file create, write, read and delete operations verified."

    test_pass
}

###############################################################################
# USB-005
# Verify USB Capacity and Usage
###############################################################################

usb_005()
{
    local SIZE
    local USED
    local AVAILABLE
    local USAGE

    log_info "[USB-005] Verify USB Capacity and Usage"

    if ! usb_ensure_mounted
    then
        TEST_MESSAGE="Unable to access USB filesystem."
        test_fail
        return
    fi

    run_command \
        "USB-005" \
        "Verify USB Capacity and Usage" \
        "lsblk -dn -o NAME,SIZE,TYPE \"$USB_DEVICE_PARTITION\" && df -h \"$USB_MOUNTPOINT\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine USB capacity and usage."
        test_fail
        return
    fi

    SIZE=$(echo "$COMMAND_OUTPUT" |
        head -n 1 |
        awk '{print $2}')

    USED=$(echo "$COMMAND_OUTPUT" |
        tail -n 1 |
        awk '{print $3}')

    AVAILABLE=$(echo "$COMMAND_OUTPUT" |
        tail -n 1 |
        awk '{print $4}')

    USAGE=$(echo "$COMMAND_OUTPUT" |
        tail -n 1 |
        awk '{print $5}')

    TEST_MESSAGE="Capacity=${SIZE:-N/A}, Used=${USED:-N/A}, Available=${AVAILABLE:-N/A}, Usage=${USAGE:-N/A}"

    test_pass
}

###############################################################################
# USB-006
# Sequential Write Performance
###############################################################################

usb_006()
{
    log_info "[USB-006] Sequential Write Performance"

    if ! usb_ensure_mounted
    then
        TEST_MESSAGE="Unable to access USB filesystem."
        test_fail
        return
    fi

    if ! usb_create_test_directory
    then
        TEST_MESSAGE="Unable to create USB validation directory."
        test_fail
        return
    fi

    USB_PERFORMANCE_FILE="${USB_TEST_DIR}/usb_sequential_test.bin"

    run_command \
        "USB-006" \
        "Sequential Write Performance" \
        "dd if=/dev/zero of=\"$USB_PERFORMANCE_FILE\" bs=1M count=\"${USB_DD_COUNT:-100}\" conv=fsync status=progress"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="USB sequential write test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="USB sequential write completed successfully."

    test_pass
}

###############################################################################
# USB-007
# Sequential Read Performance
###############################################################################

usb_007()
{
    log_info "[USB-007] Sequential Read Performance"

    if ! usb_ensure_mounted
    then
        TEST_MESSAGE="Unable to access USB filesystem."
        test_fail
        return
    fi

    USB_PERFORMANCE_FILE="${USB_TEST_DIR}/usb_sequential_test.bin"

    if [ ! -f "$USB_PERFORMANCE_FILE" ]
    then
        TEST_MESSAGE="USB sequential read test file does not exist."
        test_fail
        return
    fi

    run_command \
        "USB-007" \
        "Sequential Read Performance" \
        "dd if=\"$USB_PERFORMANCE_FILE\" of=/dev/null bs=1M status=progress"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="USB sequential read test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="USB sequential read completed successfully."

    test_pass
}

###############################################################################
# USB-008
# Filesystem Synchronization
###############################################################################

usb_008()
{
    log_info "[USB-008] Filesystem Synchronization"

    run_command \
        "USB-008" \
        "Filesystem Synchronization" \
        "usb_sync"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="USB filesystem synchronization failed."
        test_fail
        return
    fi

    TEST_MESSAGE="USB filesystem synchronized successfully."

    test_pass
}

###############################################################################
# USB-009
# Filesystem Health
###############################################################################

usb_009()
{
    log_info "[USB-009] Filesystem Health"

    run_command \
        "USB-009" \
        "Filesystem Health" \
        "usb_filesystem_health_check"

    if [ "$COMMAND_STATUS" -eq 3 ]
    then
        TEST_MESSAGE="USB filesystem health check is unavailable or unsupported."
        test_skip
        return
    fi

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="USB filesystem health verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="USB filesystem health verification completed successfully."

    test_pass
}

###############################################################################
# USB-010
# FIO Availability
###############################################################################

usb_010()
{
    log_info "[USB-010] FIO Availability"

    run_command \
        "USB-010" \
        "FIO Availability" \
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
# USB-011
# FIO Performance Test
###############################################################################

usb_011()
{
    log_info "[USB-011] FIO Performance Test"

    if ! usb_ensure_mounted
    then
        TEST_MESSAGE="Unable to access USB filesystem."
        test_fail
        return
    fi

    if ! usb_create_test_directory
    then
        TEST_MESSAGE="Unable to create USB validation directory."
        test_fail
        return
    fi

    USB_FIO_FILE="${USB_TEST_DIR}/usb_fio_test.bin"

    run_command \
        "USB-011" \
        "FIO Performance Test" \
        "fio --name=usb_validation --filename=\"$USB_FIO_FILE\" --size=\"${USB_FIO_SIZE:-256M}\" --rw=randrw --bs=4k --runtime=\"${USB_FIO_RUNTIME:-60}\" --time_based --group_reporting"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="USB fio random read/write performance test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="USB fio random read/write performance test completed."

    test_pass
}

###############################################################################
# USB-012
# Cleanup + Final Unmount
#
# IMPORTANT:
# - Remove validation directory.
# - Synchronize filesystem.
# - Unmount only if validation mounted it.
# - Existing user/system mounts are NOT unmounted.
###############################################################################

usb_012()
{
    log_info "[USB-012] Cleanup + Final Unmount"

    run_command \
        "USB-012" \
        "Cleanup + Final Unmount" \
        "usb_cmd_cleanup"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="USB cleanup or final unmount failed."
        test_fail
        return
    fi

    USB_DEVICE_PARTITION=""
    USB_MOUNTPOINT=""
    USB_MOUNTED_BY_TEST=0
    USB_TEST_DIR=""
    USB_TEST_FILE=""
    USB_PERFORMANCE_FILE=""
    USB_FIO_FILE=""

    TEST_MESSAGE="USB validation cleanup and final unmount completed successfully."

    test_pass
}

###############################################################################
# Register USB Tests
###############################################################################

usb_register_tests()
{
    register_test \
        -i "USB-001" \
        -f usb_001 \
        -n "Enumerate USB Controllers" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 10 \
        -g "usb,lsusb,controller" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Enumerate USB controllers and topology."

    register_test \
        -i "USB-002" \
        -f usb_002 \
        -n "List USB Devices" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "usb,lsusb,device" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Enumerate connected USB devices."

    register_test \
        -i "USB-003" \
        -f usb_003 \
        -n "Mount USB Drive" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 20 \
        -g "usb,mount,filesystem" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Reuse an existing USB mount or mount an unmounted USB filesystem."

    register_test \
        -i "USB-004" \
        -f usb_004 \
        -n "Verify USB Read / Write Access" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "usb,read,write,file" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify USB file create, write, read and delete operations."

    register_test \
        -i "USB-005" \
        -f usb_005 \
        -n "Verify USB Capacity and Usage" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "usb,capacity,usage,df" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify USB storage capacity and filesystem usage."

    register_test \
        -i "USB-006" \
        -f usb_006 \
        -n "Sequential Write Performance" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 300 \
        -g "usb,dd,write,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure USB sequential write performance."

    register_test \
        -i "USB-007" \
        -f usb_007 \
        -n "Sequential Read Performance" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 300 \
        -g "usb,dd,read,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Measure USB sequential read performance."

    register_test \
        -i "USB-008" \
        -f usb_008 \
        -n "Filesystem Synchronization" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "usb,sync,filesystem" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Synchronize USB filesystem buffers."

    register_test \
        -i "USB-009" \
        -f usb_009 \
        -n "Filesystem Health" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 120 \
        -g "usb,filesystem,health,fsck" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Perform a read-only USB filesystem health check."

    register_test \
        -i "USB-010" \
        -f usb_010 \
        -n "FIO Availability" \
        -c "storage" \
        -t "auto" \
        -p "low" \
        -o 10 \
        -g "usb,fio" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify fio availability."

    register_test \
        -i "USB-011" \
        -f usb_011 \
        -n "FIO Performance Test" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 600 \
        -g "usb,fio,performance" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Run USB random read/write fio performance test."

    register_test \
        -i "USB-012" \
        -f usb_012 \
        -n "Cleanup + Final Unmount" \
        -c "storage" \
        -t "auto" \
        -p "low" \
        -o 30 \
        -g "usb,cleanup,unmount" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Remove validation files, synchronize filesystem and unmount only when mounted by validation."
}

###############################################################################
# Module Initialization
###############################################################################

usb_init()
{
    log_info "========================================="
    log_info "Starting USB Validation"
    log_info "========================================="

    if [ -z "$USB_DEVICE" ]
    then
        TEST_MESSAGE="USB_DEVICE is not configured."
        log_error "$TEST_MESSAGE"
        return 1
    fi

    log_info "Configured USB Device : $USB_DEVICE"

    usb_register_tests

    return 0
}

###############################################################################
# Module Initialization When Sourced
###############################################################################

usb_init

###############################################################################
# End Of File
###############################################################################
