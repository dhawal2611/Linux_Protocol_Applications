#!/bin/bash
###############################################################################
# File        : storage.sh
# Description : Storage Validation Module
###############################################################################

###############################################################################
# Module Information
###############################################################################

MODULE_NAME="STORAGE"
MODULE_DESCRIPTION="Storage Validation"

###############################################################################
# Required Commands
###############################################################################

REQUIRED_COMMANDS=(
    lsblk
    blkid
    df
    mount
    cat
    grep
    awk
    dd
    sync
    rm
    mkdir
    touch
    findmnt
    find
    sed
    tr
)

###############################################################################
# Helper Functions
###############################################################################

#
# Get Root Device
#
#storage_get_selected_device()
#{
#    findmnt -n -o SOURCE /
#}

###############################################################################

#
# check for device present or not
#
storage_is_device_present()
{
    [ -b "$STORAGE_DEVICE" ]
}

###############################################################################

#
# Get Root Block Device
#
storage_get_block_device()
{
    #storage_get_root_device | sed 's/[0-9]*$//'
    echo "$STORAGE_DEVICE" | sed 's/p\?[0-9]*$//'
}

###############################################################################

#
# Get Filesystem Type
#
storage_get_filesystem()
{
    #findmnt -n -o FSTYPE /
    findmnt -n -S "$STORAGE_DEVICE" -o FSTYPE
}

###############################################################################

#
# Get Mount Point
#
storage_get_mountpoint()
{
    #findmnt -n -o TARGET /
    findmnt -n -S "$STORAGE_DEVICE" -o TARGET
}

###############################################################################

#
# Get Device Size
#
storage_get_device_size()
{
    local DEVICE="$1"

    lsblk -dn -o SIZE "$DEVICE"
}

###############################################################################

#
# Get Device Model
#
storage_get_device_model()
{
    local DEVICE="$1"

    lsblk -dn -o MODEL "$DEVICE"
}

###############################################################################

#
# Get Device Type
#
storage_get_device_type()
{
    local DEVICE="$1"

    lsblk -dn -o TYPE "$DEVICE"
}

###############################################################################

#
# Check Read Write Mount
#
storage_is_rw()
{
    #mount | grep "on / " | grep -q "(rw"
    findmnt -n -S "$STORAGE_DEVICE" -o OPTIONS | grep -qw rw
}

###############################################################################

#
# Cleanup Test Files
#
storage_cleanup()
{
    #rm -rf "$STORAGE_TEST_DIR/$STORAGE_TEST_FILE" 2>/dev/null
    rm -rf "$STORAGE_TEST_DIR"/*
}

###############################################################################

#
# Verify Block Device Exists
#
storage_device_exists()
{
    local DEVICE="$1"

    [ -b "$DEVICE" ]
}

###############################################################################

#
# Verify Directory Exists
#
storage_directory_exists()
{
    local DIR="$1"

    [ -d "$DIR" ]
}

###############################################################################

#
# Create Test Directory
#
storage_create_test_directory()
{
    mkdir -p "$STORAGE_TEST_DIR"
}

###############################################################################

#
# Remove Test Directory
#
storage_remove_test_directory()
{
    rm -rf "$STORAGE_TEST_DIR"
}

###############################################################################
# STORAGE-001 : Detect Storage Devices
###############################################################################

storage_001()
{
    local DEVICE_COUNT

    log_info "[STORAGE-001] Detect Storage Devices"

    run_command \
        "STORAGE-001" \
        "Detect Storage Devices" \
        "lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT \"$STORAGE_DEVICE\""
        #"lsblk -d -o NAME,SIZE,TYPE,MODEL"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to detect storage devices."
        test_fail
        return
    fi

    DEVICE_COUNT=$(echo "$COMMAND_OUTPUT" | awk 'NR>1' | wc -l)

    if [ "$DEVICE_COUNT" -eq 0 ]
    then
        TEST_MESSAGE="No storage devices detected."
        test_fail
        return
    fi

    TEST_MESSAGE="Detected ${DEVICE_COUNT} storage device(s)."
    test_pass
}

###############################################################################
# STORAGE-002 : Verify Root Device
###############################################################################

storage_002()
{
    local ROOT_DEVICE

    log_info "[STORAGE-002] Verify Root Device"

    run_command \
        "STORAGE-002" \
        "Verify Root Device" \
        "findmnt -n -o SOURCE /"
        #"storage_get_selected_device"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine root device."
        test_fail
        return
    fi

    ROOT_DEVICE=$(echo "$COMMAND_OUTPUT" | tr -d '[:space:]')

    if [ -z "$ROOT_DEVICE" ]
    then
        TEST_MESSAGE="Root device is empty."
        test_fail
        return
    fi

    TEST_MESSAGE="Root Device=${ROOT_DEVICE}"
    test_pass
}

###############################################################################
# STORAGE-003 : Verify Block Device Information
###############################################################################

storage_003()
{
    TEST_ID="STORAGE-003"
    local DEVICE SIZE TYPE MODEL

    log_info "[STORAGE-003] Verify Block Device Information"

    #DEVICE=$(storage_get_block_device)
    DEVICE=$STORAGE_DEVICE

    if ! storage_device_exists "$DEVICE"
    then
        TEST_MESSAGE="Block device ${DEVICE} not found."
        test_fail
        return
    fi

    run_command \
        "STORAGE-003" \
        "Verify Block Device Information" \
        "lsblk -dn -o NAME,SIZE,TYPE,MODEL ${DEVICE}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to read block device information."
        test_fail
        return
    fi

    SIZE=$(storage_get_device_size "$DEVICE")
    TYPE=$(storage_get_device_type "$DEVICE")
    MODEL=$(storage_get_device_model "$DEVICE")

    TEST_MESSAGE="Device=${DEVICE}, Size=${SIZE}, Type=${TYPE}, Model=${MODEL}"
    test_pass
}

###############################################################################
# STORAGE-004 : Verify Filesystem Type
###############################################################################

storage_004()
{
    local FILESYSTEM

    log_info "[STORAGE-004] Verify Filesystem Type"

    run_command \
        "STORAGE-004" \
        "Verify Filesystem Type" \
        "storage_get_filesystem"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine filesystem."
        test_fail
        return
    fi

    FILESYSTEM=$(echo "$COMMAND_OUTPUT" | tr -d '[:space:]')

    if [ -z "$FILESYSTEM" ]
    then
        TEST_MESSAGE="Filesystem type is empty."
        test_fail
        return
    fi

    TEST_MESSAGE="Filesystem=${FILESYSTEM}"
    test_pass
}

###############################################################################
# STORAGE-005 : Verify Mounted Partitions
###############################################################################

storage_005()
{
    log_info "[STORAGE-005] Verify Mounted Partitions"

    run_command \
        "STORAGE-005" \
        "Verify Mounted Partitions" \
        "findmnt \"$STORAGE_DEVICE\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to retrieve mounted partitions."
        test_fail
        return
    fi

    if echo "$COMMAND_OUTPUT" | grep -q "/"
    then
        TEST_MESSAGE="Mounted partitions detected successfully."
        test_pass
    else
        TEST_MESSAGE="No mounted partitions found."
        test_fail
    fi
}

###############################################################################
# STORAGE-006 : Verify Disk Capacity
###############################################################################

storage_006()
{
    TEST_ID="STORAGE-006"
    local DEVICE
    local SIZE

    log_info "[STORAGE-006] Verify Disk Capacity"

    DEVICE=$(storage_get_block_device)

    if ! storage_device_exists "$DEVICE"
    then
        TEST_MESSAGE="Storage device not found."
        test_fail
        return
    fi

    run_command \
        "STORAGE-006" \
        "Verify Disk Capacity" \
        "lsblk -dn -o SIZE \"$STORAGE_DEVICE\""
        #"lsblk -dn -o SIZE ${DEVICE}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine disk capacity."
        test_fail
        return
    fi

    SIZE=$(echo "$COMMAND_OUTPUT" | tr -d '[:space:]')

    if [ -z "$SIZE" ]
    then
        TEST_MESSAGE="Disk capacity is empty."
        test_fail
        return
    fi

    TEST_MESSAGE="Disk Capacity=${SIZE}"
    test_pass
}

###############################################################################
# STORAGE-007 : Verify Disk Usage
###############################################################################

storage_007()
{
    local USED
    local AVAILABLE
    local UTILIZATION

    log_info "[STORAGE-007] Verify Disk Usage"

    run_command \
        "STORAGE-007" \
        "Verify Disk Usage" \
        "df -h \"$(storage_get_mountpoint)\""

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to retrieve disk usage."
        test_fail
        return
    fi

    USED=$(echo "$COMMAND_OUTPUT" | awk 'NR==2 {print $3}')
    AVAILABLE=$(echo "$COMMAND_OUTPUT" | awk 'NR==2 {print $4}')
    UTILIZATION=$(echo "$COMMAND_OUTPUT" | awk 'NR==2 {print $5}')

    TEST_MESSAGE="Used=${USED}, Available=${AVAILABLE}, Usage=${UTILIZATION}"
    test_pass
}

###############################################################################
# STORAGE-008 : Verify Read/Write Mount Status
###############################################################################

storage_008()
{
    log_info "[STORAGE-008] Verify Read/Write Mount Status"

    run_command \
        "STORAGE-008" \
        "Verify Read/Write Mount Status" \
        "mount | grep \"$STORAGE_DEVICE\""
        #"mount | grep 'on / '"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Unable to determine mount options."
        test_fail
        return
    fi

    if storage_is_rw
    then
        TEST_MESSAGE="Root filesystem mounted as Read-Write."
        test_pass
    else
        TEST_MESSAGE="Root filesystem is Read-Only."
        test_fail
    fi
}

###############################################################################
# STORAGE-009 : Verify File Creation
###############################################################################

storage_009()
{
    local TEST_FILE="${STORAGE_TEST_DIR}/${STORAGE_TEST_FILE}"

    log_info "[STORAGE-009] Verify File Creation"

    storage_create_test_directory

    run_command \
        "STORAGE-009" \
        "Verify File Creation" \
        "touch ${TEST_FILE}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to create test file."
        test_fail
        return
    fi

    if [ -f "$TEST_FILE" ]
    then
        TEST_MESSAGE="File created successfully."
        test_pass
    else
        TEST_MESSAGE="File not found after creation."
        test_fail
    fi
}

###############################################################################
# STORAGE-010 : Verify File Write
###############################################################################

storage_010()
{
    local TEST_FILE="${STORAGE_TEST_DIR}/${STORAGE_TEST_FILE}"

    log_info "[STORAGE-010] Verify File Write"

    storage_create_test_directory

    run_command \
        "STORAGE-010" \
        "Verify File Write" \
        "echo 'Storage Validation Framework' > ${TEST_FILE}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to write test file."
        test_fail
        return
    fi

    if grep -q "Storage Validation Framework" "$TEST_FILE"
    then
        TEST_MESSAGE="File write verified successfully."
        test_pass
    else
        TEST_MESSAGE="File content verification failed."
        test_fail
    fi
}

###############################################################################
# STORAGE-011 : Verify File Read
###############################################################################

storage_011()
{
    local TEST_FILE="${STORAGE_TEST_DIR}/${STORAGE_TEST_FILE}"

    log_info "[STORAGE-011] Verify File Read"

    run_command \
        "STORAGE-011" \
        "Verify File Read" \
        "cat ${TEST_FILE}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to read test file."
        test_fail
        return
    fi

    if echo "$COMMAND_OUTPUT" | grep -q "Storage Validation Framework"
    then
        TEST_MESSAGE="File read verified successfully."
        test_pass
    else
        TEST_MESSAGE="Unexpected file content."
        test_fail
    fi
}

###############################################################################
# STORAGE-012 : Verify File Deletion
###############################################################################

storage_012()
{
    local TEST_FILE="${STORAGE_TEST_DIR}/${STORAGE_TEST_FILE}"

    log_info "[STORAGE-012] Verify File Deletion"

    run_command \
        "STORAGE-012" \
        "Verify File Deletion" \
        "rm -f ${TEST_FILE}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Failed to delete test file."
        test_fail
        return
    fi

    if [ ! -f "$TEST_FILE" ]
    then
        TEST_MESSAGE="File deleted successfully."
        test_pass
    else
        TEST_MESSAGE="File still exists after deletion."
        test_fail
    fi

    storage_remove_test_directory
}

###############################################################################
# STORAGE-013 : Verify Sequential Write Performance
###############################################################################

storage_013()
{
    local TEST_FILE="${STORAGE_TEST_DIR}/${STORAGE_TEST_FILE}"

    log_info "[STORAGE-013] Verify Sequential Write Performance"

    storage_create_test_directory

    run_command \
        "STORAGE-013" \
        "Verify Sequential Write Performance" \
        "dd if=/dev/zero of=${TEST_FILE} bs=1M count=${STORAGE_DD_COUNT} conv=fsync status=progress"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Sequential write test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Sequential write completed successfully."
    test_pass
}

###############################################################################
# STORAGE-014 : Verify Sequential Read Performance
###############################################################################

storage_014()
{
    local TEST_FILE="${STORAGE_TEST_DIR}/${STORAGE_TEST_FILE}"

    log_info "[STORAGE-014] Verify Sequential Read Performance"

    if [ ! -f "$TEST_FILE" ]
    then
        TEST_MESSAGE="Test file not found."
        test_fail
        return
    fi

    run_command \
        "STORAGE-014" \
        "Verify Sequential Read Performance" \
        "dd if=${TEST_FILE} of=/dev/null bs=1M status=progress"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Sequential read test failed."
        test_fail
        return
    fi

    TEST_MESSAGE="Sequential read completed successfully."
    test_pass
}

###############################################################################
# STORAGE-015 : Verify File Synchronization
###############################################################################

storage_015()
{
    log_info "[STORAGE-015] Verify File Synchronization"

    run_command \
        "STORAGE-015" \
        "Verify File Synchronization" \
        "sync"

    if [ "$COMMAND_STATUS" -eq 0 ]
    then
        TEST_MESSAGE="Filesystem synchronized successfully."
        test_pass
    else
        TEST_MESSAGE="Filesystem synchronization failed."
        test_fail
    fi
}

###############################################################################
# STORAGE-016 : Verify FIO Availability
###############################################################################

storage_016()
{
    TEST_ID="STORAGE-016"
    log_info "[STORAGE-016] Verify FIO Availability"

    if ! command -v fio >/dev/null 2>&1
    then
        TEST_MESSAGE="fio utility is not installed."
        test_skip
        return
    fi

    TEST_MESSAGE="fio utility is available."
    test_pass
}

###############################################################################
# STORAGE-017 : Run FIO Storage Stress Test
###############################################################################

storage_017()
{
    TEST_ID="STORAGE-017"
    log_info "[STORAGE-017] Run FIO Storage Stress Test"

    if ! command -v fio >/dev/null 2>&1
    then
        TEST_MESSAGE="fio utility is not installed."
        test_skip
        return
    fi

    storage_create_test_directory

    run_command \
        "STORAGE-017" \
        "Run FIO Storage Stress Test" \
        "fio \
        --name=storage_validation \
        --directory=${STORAGE_TEST_DIR} \
        --size=${STORAGE_FIO_SIZE} \
        --rw=randrw \
        --bs=4k \
        --runtime=${STORAGE_FIO_RUNTIME} \
        --time_based \
        --group_reporting"

    if [ "$COMMAND_STATUS" -eq 0 ]
    then
        TEST_MESSAGE="fio benchmark completed successfully."
        test_pass
    else
        TEST_MESSAGE="fio benchmark failed."
        test_fail
    fi

    storage_cleanup
}

###############################################################################
# STORAGE-018 : Verify Filesystem Health
###############################################################################

storage_018()
{
    TEST_ID="STORAGE-018"
    local FILESYSTEM
    local DEVICE

    log_info "[STORAGE-018] Verify Filesystem Health"

    FILESYSTEM=$(storage_get_filesystem)
    DEVICE="$STORAGE_DEVICE"
    #STORAGE_DEVICE=""

    case "$FILESYSTEM" in

        ext2|ext3|ext4)

            run_command \
                "STORAGE-018" \
                "Verify Filesystem Health" \
                "fsck -nf ${DEVICE}"

            ;;

        xfs)

            if command -v xfs_repair >/dev/null 2>&1
            then

                run_command \
                    "STORAGE-018" \
                    "Verify Filesystem Health" \
                    "xfs_repair -n ${DEVICE}"

            else

                TEST_MESSAGE="xfs_repair utility not installed."
                test_skip
                return

            fi
            ;;

        btrfs)

            if command -v btrfs >/dev/null 2>&1
            then

                run_command \
                    "STORAGE-018" \
                    "Verify Filesystem Health" \
                    "btrfs check --readonly ${DEVICE}"

            else

                TEST_MESSAGE="btrfs utility not installed."
                test_skip
                return

            fi
            ;;

        *)

            TEST_MESSAGE="Filesystem ${FILESYSTEM} is not supported."
            test_skip
            return
            ;;
    esac

    if [ "$COMMAND_STATUS" -eq 0 ]
    then
        TEST_MESSAGE="Filesystem health verification completed."
        test_pass
    else
        TEST_MESSAGE="Filesystem health verification failed."
        test_fail
    fi
}

###############################################################################
# STORAGE-019 : Verify Storage Read/Write Capability
###############################################################################

storage_019()
{
    local TEST_FILE="${STORAGE_TEST_DIR}/rw_test.bin"

    log_info "[STORAGE-019] Verify Storage Read/Write Capability"

    storage_create_test_directory

    run_command \
        "STORAGE-019" \
        "Verify Storage Read/Write Capability" \
        "echo StorageValidation > ${TEST_FILE} && cat ${TEST_FILE}"

    if [ "$COMMAND_STATUS" -ne 0 ]
    then
        TEST_MESSAGE="Read/Write capability test failed."
        test_fail
        return
    fi

    if echo "$COMMAND_OUTPUT" | grep -q "StorageValidation"
    then
        TEST_MESSAGE="Storage Read/Write verified."
        test_pass
    else
        TEST_MESSAGE="Storage verification failed."
        test_fail
    fi

    rm -f "${TEST_FILE}"
}

###############################################################################
# STORAGE-020 : Cleanup Storage Test Files
###############################################################################

storage_020()
{
    TEST_ID="STORAGE-020"
    log_info "[STORAGE-020] Cleanup Storage Test Files"

    storage_remove_test_directory

    if [ ! -d "$STORAGE_TEST_DIR" ]
    then										
        TEST_MESSAGE="Temporary storage files removed."
        test_pass
    else
        TEST_MESSAGE="Failed to cleanup temporary files."
        test_fail
    fi
}

###############################################################################
# Register Storage Tests
###############################################################################

storage_register_tests()
{
    register_test \
        -i "STORAGE-001" \
        -f storage_001 \
        -n "Detect Storage Devices" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "storage,lsblk,device" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Detect all available storage devices."

    register_test \
        -i "STORAGE-002" \
        -f storage_002 \
        -n "Verify Root Device" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "storage,root,mount" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify Linux root storage device."

    register_test \
        -i "STORAGE-003" \
        -f storage_003 \
        -n "Verify Block Device Information" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "storage,block,lsblk" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify storage block device information."

    register_test \
        -i "STORAGE-004" \
        -f storage_004 \
        -n "Verify Filesystem Type" \
        -c "storage" \
        -t "auto" \
        -p "high" \
        -o 10 \
        -g "storage,filesystem" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify filesystem type."

    register_test \
        -i "STORAGE-005" \
        -f storage_005 \
        -n "Verify Mounted Partitions" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 10 \
        -g "storage,mount" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify mounted storage partitions."

    register_test \
        -i "STORAGE-006" \
        -f storage_006 \
        -n "Verify Disk Capacity" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 10 \
        -g "storage,capacity" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify storage capacity."

    register_test \
        -i "STORAGE-007" \
        -f storage_007 \
        -n "Verify Disk Usage" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 10 \
        -g "storage,usage,df" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify disk usage."

    register_test \
        -i "STORAGE-008" \
        -f storage_008 \
        -n "Verify Read Write Mount" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 10 \
        -g "storage,rw,mount" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify root filesystem mount mode."

    register_test \
        -i "STORAGE-009" \
        -f storage_009 \
        -n "Verify File Creation" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "storage,file" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify storage file creation."

    register_test \
        -i "STORAGE-010" \
        -f storage_010 \
        -n "Verify File Write" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "storage,write" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify file write operation."

    register_test \
        -i "STORAGE-011" \
        -f storage_011 \
        -n "Verify File Read" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "storage,read" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify file read operation."

    register_test \
        -i "STORAGE-012" \
        -f storage_012 \
        -n "Verify File Deletion" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "storage,delete" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify file deletion."

    register_test \
        -i "STORAGE-013" \
        -f storage_013 \
        -n "Verify Sequential Write Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 300 \
        -g "storage,dd,write" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Measure sequential write performance."

    register_test \
        -i "STORAGE-014" \
        -f storage_014 \
        -n "Verify Sequential Read Performance" \
        -c "performance" \
        -t "auto" \
        -p "high" \
        -o 300 \
        -g "storage,dd,read" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Measure sequential read performance."

    register_test \
        -i "STORAGE-015" \
        -f storage_015 \
        -n "Verify File Synchronization" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 20 \
        -g "storage,sync" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify filesystem synchronization."

    register_test \
        -i "STORAGE-016" \
        -f storage_016 \
        -n "Verify FIO Availability" \
        -c "performance" \
        -t "auto" \
        -p "low" \
        -o 10 \
        -g "storage,fio" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify fio utility availability."

    register_test \
        -i "STORAGE-017" \
        -f storage_017 \
        -n "Run FIO Storage Stress Test" \
        -c "stress" \
        -t "auto" \
        -p "high" \
        -o 600 \
        -g "storage,fio,stress" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Run fio storage stress benchmark."

    register_test \
        -i "STORAGE-018" \
        -f storage_018 \
        -n "Verify Filesystem Health" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 120 \
        -g "storage,fsck" \
        -w "Embedded Team" \
        -b "Linux" \
        -e "yes" \
        -d "Verify filesystem integrity."

    register_test \
        -i "STORAGE-019" \
        -f storage_019 \
        -n "Verify Storage Read Write Capability" \
        -c "storage" \
        -t "auto" \
        -p "medium" \
        -o 30 \
        -g "storage,rw" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Verify storage read/write capability."

    register_test \
        -i "STORAGE-020" \
        -f storage_020 \
        -n "Cleanup Storage Test Files" \
        -c "storage" \
        -t "auto" \
        -p "low" \
        -o 20 \
        -g "storage,cleanup" \
        -w "Embedded Team" \
        -b "All" \
        -e "yes" \
        -d "Cleanup temporary storage files."
}

###############################################################################
# Module Initialization
###############################################################################

storage_init()
{
    log_info "========================================="
    log_info "Starting Storage Validation"
    log_info "========================================="

    if [ -z "$STORAGE_DEVICE" ]
    then
        log_error "No storage device selected."
        return 1
    fi

    ###########################################################################
    # Translate logical storage name to actual device
    ###########################################################################
    case "${STORAGE_DEVICE,,}" in

	    emmc)
		STORAGE_DEVICE="$EMMC_DEVICE"
		STORAGE_NAME="eMMC"
		;;

	    sdcard)
		STORAGE_DEVICE="$SDCARD_DEVICE"
		STORAGE_NAME="SD Card"
		;;

	    nvme)
		STORAGE_DEVICE="$NVME_DEVICE"
		STORAGE_NAME="NVMe SSD"
		;;

	    sata)
		STORAGE_DEVICE="$SATA_DEVICE"
		STORAGE_NAME="SATA Drive"
		;;

	    usb)
		STORAGE_DEVICE="$USB_DEVICE"
		STORAGE_NAME="USB Storage"
		;;

	    local)
		STORAGE_DEVICE="$LOCAL_DEVICE"
		STORAGE_NAME="Local Storage"
		;;

	    *)
		log_error "Unknown storage device : ${STORAGE_DEVICE}"
		log_error ""
		log_error "Supported devices:"
		log_error "  emmc"
		log_error "  sdcard"
		log_error "  nvme"
		log_error "  sata"
		log_error "  usb"
		log_error "  local"
		return 1
		;;
    esac

    ###########################################################################
    # Verify Device
    ###########################################################################
    if [ ! -b "$STORAGE_DEVICE" ] && [ ! -d "$STORAGE_DEVICE" ]
    then
        log_error "Storage device ${STORAGE_DEVICE} does not exist."
        return 1
    fi

    ###########################################################################
    # Set Mount Point
    ###########################################################################
    STORAGE_MOUNTPOINT="$(storage_get_mountpoint)"

    if [ -z "$STORAGE_MOUNTPOINT" ] && [ -d "$STORAGE_DEVICE" ]
    then
        STORAGE_MOUNTPOINT="$STORAGE_DEVICE"
    fi

    log_info "========================================="
    log_info "Storage Name       : $STORAGE_NAME"
    log_info "Storage Device     : $STORAGE_DEVICE"
    log_info "Storage Mountpoint : $STORAGE_MOUNTPOINT"
    log_info "========================================="

    storage_register_tests
}

storage_init

###############################################################################
# End Of File
###############################################################################
