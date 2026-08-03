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
# eMMC Runtime Variables
###############################################################################

EMMC_MOUNTPOINT=""
EMMC_DEVICE_PARTITION=""
EMMC_MOUNTED_BY_TEST=0

EMMC_TEST_FILE=""
EMMC_TEST_DIR=""

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
    #mmc
)

###############################################################################
# Helper Functions
###############################################################################

#
# Check whether eMMC device exists
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
    blkid -o value -s TYPE "$EMMC_DEVICE"
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
# Get eMMC mount point
#
emmc_get_mountpoint()
{
    if [ -n "$EMMC_MOUNTPOINT" ]
    then
        echo "$EMMC_MOUNTPOINT"
        return 0
    fi

    findmnt -n -S "$EMMC_DEVICE" -o TARGET 2>/dev/null
}

###############################################################################

#
# Get eMMC mount options
#
emmc_get_mount_options()
{
    local MOUNTPOINT="$1"

    if [ -z "$MOUNTPOINT" ]
    then
        return 1
    fi

    findmnt -n -T "$MOUNTPOINT" -o OPTIONS
}

###############################################################################

#
# Check whether eMMC is mounted
#
emmc_is_mounted()
{
    findmnt -n -S "$EMMC_DEVICE" >/dev/null 2>&1
}

###############################################################################

#
# Check whether filesystem is mounted read-write
#
emmc_is_rw()
{
    local MOUNTPOINT="$1"

    if [ -z "$MOUNTPOINT" ]
    then
        return 1
    fi

    findmnt -n -T "$MOUNTPOINT" -o OPTIONS | grep -qw rw
}

###############################################################################

#
# Find filesystem-bearing eMMC partition
#
emmc_get_filesystem_device()
{
    local DEVICE="$EMMC_DEVICE"

    #
    # First check whether the supplied device itself contains a filesystem.
    #
    if blkid -o value -s TYPE "$DEVICE" 2>/dev/null | grep -q .
    then
        echo "$DEVICE"
        return 0
    fi

    #
    # Otherwise search its children for a filesystem.
    #
    lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICE" 2>/dev/null |
        awk '$3 != "" {print "/dev/" $1; exit}'
}

###############################################################################

#
# Create temporary eMMC test directory
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
# Remove temporary eMMC test directory
#
emmc_remove_test_directory()
{
    if [ -n "$EMMC_TEST_DIR" ]
    then
        rm -rf "$EMMC_TEST_DIR" 2>/dev/null
    elif [ -n "$EMMC_MOUNTPOINT" ]
    then
        rm -rf "${EMMC_MOUNTPOINT}/emmc_validation" 2>/dev/null
    fi
}

###############################################################################

#
# Get test file path
#
emmc_get_test_file()
{
    if [ -z "$EMMC_TEST_DIR" ]
    then
        EMMC_TEST_DIR="${EMMC_MOUNTPOINT}/emmc_validation"
    fi

    EMMC_TEST_FILE="${EMMC_TEST_DIR}/emmc_test.bin"

    echo "$EMMC_TEST_FILE"
}

###############################################################################

#
# Cleanup mount created by the validation framework
#
emmc_unmount_if_required()
{
    if [ "$EMMC_MOUNTED_BY_TEST" -eq 1 ] &&
       [ -n "$EMMC_MOUNTPOINT" ]
    then
        umount "$EMMC_MOUNTPOINT" >/dev/null 2>&1

        EMMC_MOUNTED_BY_TEST=0
        EMMC_MOUNTPOINT=""
        EMMC_DEVICE_PARTITION=""
        EMMC_TEST_DIR=""
        EMMC_TEST_FILE=""
    fi
}

###############################################################################

#
# Mount the emmc device
#
emmc_mount_for_test()
{
    local MOUNT_DEVICE
    local MOUNTPOINT

    MOUNT_DEVICE="$EMMC_DEVICE"

    MOUNTPOINT=$(findmnt -n -S "$MOUNT_DEVICE" -o TARGET 2>/dev/null)

    if [ -n "$MOUNTPOINT" ]
    then
        EMMC_MOUNTPOINT="$MOUNTPOINT"
        EMMC_MOUNTED_BY_TEST=0
        return 0
    fi

    MOUNTPOINT="/mnt/emmc_validation"

    mkdir -p "$MOUNTPOINT"

    mount "$MOUNT_DEVICE" "$MOUNTPOINT" || return 1

    EMMC_MOUNTPOINT="$MOUNTPOINT"
    EMMC_MOUNTED_BY_TEST=1

    return 0
}

###############################################################################
# EMMC-001 : Detect & Verify eMMC Device
###############################################################################

emmc_001()
{
    local DEVICE_NAME
    local SIZE
    local TYPE
    local FSTYPE
    local MODEL

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

    DEVICE_NAME=$(echo "$COMMAND_OUTPUT" | awk '{print $1}')
    SIZE=$(echo "$COMMAND_OUTPUT" | awk '{print $2}')
    TYPE=$(echo "$COMMAND_OUTPUT" | awk '{print $3}')
    FSTYPE=$(echo "$COMMAND_OUTPUT" | awk '{print $4}')
    MODEL=$(echo "$COMMAND_OUTPUT" | awk '{print $5}')

    if [ -z "$DEVICE_NAME" ]
    then
        TEST_MESSAGE="eMMC device name could not be determined."
        test_fail
        return
    fi

    if [ -z "$SIZE" ]
    then
        TEST_MESSAGE="Unable to determine eMMC size."
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
# EMMC-002 : Verify eMMC EXT_CSD
###############################################################################

emmc_002()
{
    log_info "[EMMC-002] Verify eMMC EXT_CSD"

    run_command \
        "EMMC-002" \
        "Verify eMMC EXT_CSD" \
        "mmc extcsd read \"$EMMC_DEVICE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to read eMMC EXT_CSD information."
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
# EMMC-003 : Verify Filesystem & Mount
###############################################################################

emmc_003()
{
    local FILESYSTEM
    local OPTIONS

    log_info "[EMMC-003] Verify eMMC Filesystem & Mount"

    run_command \
        "EMMC-003" \
        "Verify eMMC Filesystem & Mount" \
        "emmc_mount_for_test"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to mount or verify eMMC filesystem."
        test_fail
        return
    fi

    FILESYSTEM=$(blkid -o value -s TYPE "$EMMC_DEVICE" 2>/dev/null)
    OPTIONS=$(findmnt -n -T "$EMMC_MOUNTPOINT" -o OPTIONS 2>/dev/null)

    if [ -z "$FILESYSTEM" ]
    then
        TEST_MESSAGE="Unable to determine eMMC filesystem."
        test_fail
        return
    fi

    if ! echo "$OPTIONS" | grep -qw rw
    then
        TEST_MESSAGE="eMMC filesystem is mounted read-only."
        test_fail
        return
    fi

    TEST_MESSAGE="Filesystem=$FILESYSTEM, Mountpoint=$EMMC_MOUNTPOINT, Options=$OPTIONS"
    test_pass
}
###############################################################################
# EMMC-004 : Verify Capacity & Usage
###############################################################################

emmc_004()
{
    local SIZE
    local USED
    local AVAILABLE
    local UTILIZATION
    local MOUNTPOINT

    log_info "[EMMC-004] Verify eMMC Capacity & Usage"

    MOUNTPOINT=$(emmc_get_mountpoint)

    if [ -z "$MOUNTPOINT" ]
    then
        TEST_MESSAGE="eMMC is not mounted. Run EMMC-003 first."
        test_fail
        return
    fi

    run_command \
        "EMMC-004" \
        "Verify eMMC Capacity & Usage" \
        "lsblk -dn -o SIZE \"$EMMC_DEVICE\" && df -h \"$MOUNTPOINT\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine eMMC capacity or usage."
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

    TEST_MESSAGE="Capacity=${SIZE}, Used=${USED}, Available=${AVAILABLE}, Usage=${UTILIZATION}"
    test_pass
}

###############################################################################
# EMMC-005 : Verify Read/Write Access
###############################################################################

emmc_005()
{
    local TEST_FILE
    local COMMAND

    log_info "[EMMC-005] Verify eMMC Read/Write Access"

    if [ -z "$EMMC_MOUNTPOINT" ]
    then
        TEST_MESSAGE="eMMC is not mounted. Run EMMC-003 first."
        test_fail
        return
    fi

    EMMC_TEST_DIR="${EMMC_MOUNTPOINT}/emmc_validation"
    EMMC_TEST_FILE="${EMMC_TEST_DIR}/emmc_rw_test.txt"

    COMMAND="
        mkdir -p \"$EMMC_TEST_DIR\" &&
        touch \"$EMMC_TEST_FILE\" &&
        echo 'eMMC Storage Validation Framework' > \"$EMMC_TEST_FILE\" &&
        grep -q 'eMMC Storage Validation Framework' \"$EMMC_TEST_FILE\" &&
        cat \"$EMMC_TEST_FILE\" &&
        rm -f \"$EMMC_TEST_FILE\" &&
        [ ! -f \"$EMMC_TEST_FILE\" ]
    "

    run_command \
        "EMMC-005" \
        "Verify eMMC Read/Write Access" \
        "$COMMAND"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="eMMC create/write/read/delete operation failed."
        test_fail
        return
    fi

    TEST_MESSAGE="eMMC file create, write, read and delete operations verified."
    test_pass
}

###############################################################################
# EMMC-006 : Sequential Write Performance
###############################################################################

emmc_006()
{
    local TEST_FILE

    log_info "[EMMC-006] Verify Sequential Write Performance"

    if [ -z "$EMMC_MOUNTPOINT" ]
    then
        TEST_MESSAGE="eMMC is not mounted. Run EMMC-003 first."
        test_fail
        return
    fi

    EMMC_TEST_DIR="${EMMC_MOUNTPOINT}/emmc_validation"
    EMMC_TEST_FILE="${EMMC_TEST_DIR}/emmc_performance_test.bin"

    mkdir -p "$EMMC_TEST_DIR"

    run_command \
        "EMMC-006" \
        "Verify Sequential Write Performance" \
        "dd if=/dev/zero of=\"$EMMC_TEST_FILE\" bs=1M count=\"${EMMC_DD_COUNT:-100}\" conv=fsync status=progress"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Sequential eMMC write test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Sequential eMMC write completed successfully."
    test_pass
}

###############################################################################
# EMMC-007 : Sequential Read Performance
###############################################################################

emmc_007()
{
    log_info "[EMMC-007] Verify Sequential Read Performance"

    if [ -z "$EMMC_TEST_FILE" ] || [ ! -f "$EMMC_TEST_FILE" ]
    then
        TEST_MESSAGE="Sequential write test file not found."
        test_fail
        return
    fi

    run_command \
        "EMMC-007" \
        "Verify Sequential Read Performance" \
        "dd if=\"$EMMC_TEST_FILE\" of=/dev/null bs=1M status=progress"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Sequential eMMC read test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Sequential eMMC read completed successfully."
    test_pass
}

###############################################################################
# EMMC-008 : Filesystem Synchronization
###############################################################################

emmc_008()
{
    log_info "[EMMC-008] Verify Filesystem Synchronization"

    run_command \
        "EMMC-008" \
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
# EMMC-009 : Filesystem Health
###############################################################################

emmc_009()
{
    local FILESYSTEM
    local CHECK_DEVICE
    local COMMAND

    log_info "[EMMC-009] Verify Filesystem Health"

    CHECK_DEVICE="$EMMC_DEVICE_PARTITION"

    if [ -z "$CHECK_DEVICE" ]
    then
        CHECK_DEVICE="$EMMC_DEVICE"
    fi

    FILESYSTEM=$(emmc_get_filesystem)

    if [ -z "$FILESYSTEM" ]
    then
        TEST_MESSAGE="Unable to determine eMMC filesystem."
        test_fail
        return
    fi

    case "$FILESYSTEM" in

        ext2|ext3|ext4)

            COMMAND="fsck -N \"$CHECK_DEVICE\""
            ;;

        xfs)

            if ! command -v xfs_repair >/dev/null 2>&1
            then
                TEST_MESSAGE="xfs_repair utility is not installed."
                test_skip
                return
            fi

            COMMAND="xfs_repair -n \"$CHECK_DEVICE\""
            ;;

        btrfs)

            if ! command -v btrfs >/dev/null 2>&1
            then
                TEST_MESSAGE="btrfs utility is not installed."
                test_skip
                return
            fi

            COMMAND="btrfs check --readonly \"$CHECK_DEVICE\""
            ;;

        *)

            TEST_MESSAGE="Filesystem ${FILESYSTEM} is not supported for health validation."
            test_skip
            return
            ;;
    esac

    run_command \
        "EMMC-009" \
        "Verify Filesystem Health" \
        "$COMMAND"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Filesystem health verification failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Filesystem health verification completed for ${FILESYSTEM}."
    test_pass
}

###############################################################################
# EMMC-010 : FIO Availability
###############################################################################

emmc_010()
{
    log_info "[EMMC-010] Verify FIO Availability"

    run_command \
        "EMMC-010" \
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
# EMMC-011 : FIO Performance Test
###############################################################################

emmc_011()
{
    local FIO_FILE

    log_info "[EMMC-011] Run FIO Performance Test"

    if ! command -v fio >/dev/null 2>&1
    then
        TEST_MESSAGE="fio utility is not installed."
        test_skip
        return
    fi

    if [ -z "$EMMC_MOUNTPOINT" ]
    then
        TEST_MESSAGE="eMMC is not mounted. Run EMMC-003 first."
        test_fail
        return
    fi

    EMMC_TEST_DIR="${EMMC_MOUNTPOINT}/emmc_validation"
    FIO_FILE="${EMMC_TEST_DIR}/emmc_fio_test.bin"

    mkdir -p "$EMMC_TEST_DIR"

    run_command \
        "EMMC-011" \
        "Run FIO Performance Test" \
        "fio --name=emmc_validation --filename=\"$FIO_FILE\" --size=\"${EMMC_FIO_SIZE:-256M}\" --rw=randrw --bs=4k --runtime=\"${EMMC_FIO_RUNTIME:-60}\" --time_based --group_reporting"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="fio eMMC performance test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="fio eMMC random read/write performance test completed."
    test_pass
}

###############################################################################
# EMMC-012 : Cleanup eMMC Test Files
###############################################################################

emmc_012()
{
    local COMMAND

    log_info "[EMMC-012] Cleanup eMMC Test Files"

    COMMAND="
        if [ -n \"$EMMC_TEST_DIR\" ] && [ -d \"$EMMC_TEST_DIR\" ]; then
            rm -rf \"$EMMC_TEST_DIR\"
        fi

        if [ \"$EMMC_MOUNTED_BY_TEST\" -eq 1 ] && [ -n \"$EMMC_MOUNTPOINT\" ]; then
            umount \"$EMMC_MOUNTPOINT\"
        fi
    "

    run_command \
        "EMMC-012" \
        "Cleanup eMMC Test Files" \
        "$COMMAND"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to cleanup eMMC test files or unmount eMMC."
        test_fail
        return
    fi

    #
    # Reset runtime state only after successful cleanup.
    #
    EMMC_MOUNTPOINT=""
    EMMC_DEVICE_PARTITION=""
    EMMC_MOUNTED_BY_TEST=0
    EMMC_TEST_DIR=""
    EMMC_TEST_FILE=""

    TEST_MESSAGE="eMMC test files cleaned and temporary mount released successfully."
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
        -d "Read and verify eMMC EXT_CSD information."

    register_test \
        -i "EMMC-003" \
        -f emmc_003 \
        -n "Verify eMMC Filesystem & Mount" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 30 \
        -g "emmc,filesystem,mount,rw" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify filesystem, mount point and read-write status; automatically mount an unmounted eMMC filesystem."

    register_test \
        -i "EMMC-004" \
        -f emmc_004 \
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
        -i "EMMC-005" \
        -f emmc_005 \
        -n "Verify eMMC Read/Write Access" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 30 \
        -g "emmc,read,write,file" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify eMMC file creation, write, read and deletion."

    register_test \
        -i "EMMC-006" \
        -f emmc_006 \
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
        -i "EMMC-007" \
        -f emmc_007 \
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
        -i "EMMC-008" \
        -f emmc_008 \
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
        -i "EMMC-009" \
        -f emmc_009 \
        -n "Verify Filesystem Health" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 120 \
        -g "emmc,filesystem,health,fsck" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify eMMC filesystem integrity using a filesystem-specific read-only check."

    register_test \
        -i "EMMC-010" \
        -f emmc_010 \
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
        -i "EMMC-011" \
        -f emmc_011 \
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
        -i "EMMC-012" \
        -f emmc_012 \
        -n "Cleanup eMMC Test Files" \
        -c "storage" \
        -t "auto" \
        -p "low" \
        -o 20 \
        -g "emmc,cleanup,umount" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Remove temporary eMMC test files and safely unmount eMMC when mounted by the test."
}

###############################################################################
# Module Initialization
###############################################################################

emmc_init()
{
    log_info "========================================="
    log_info "Starting eMMC Validation"
    log_info "========================================="

    if [ -z "$EMMC_DEVICE" ]
    then
        TEST_MESSAGE="No eMMC device configured."

        log_error "EMMC_DEVICE is not configured."

        return 1
    fi

    if [ ! -b "$EMMC_DEVICE" ]
    then
        log_error "eMMC device $EMMC_DEVICE does not exist."

        return 1
    fi

    log_info "eMMC Device : $EMMC_DEVICE"

    emmc_register_tests
}

###############################################################################
# Register tests when module is sourced
###############################################################################

emmc_init

###############################################################################
# End Of File
###############################################################################
