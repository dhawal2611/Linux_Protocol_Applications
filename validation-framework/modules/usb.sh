#!/bin/bash
###############################################################################
# Module      : USB Validation
# Description : USB Host and USB Storage validation test cases
###############################################################################

#
# USB-001
# Enumerate USB Controllers
#
usb_001()
{
    run_command \
        "USB-001" \
        "Enumerate USB Controllers" \
        "lsusb -t"
}

#
# USB-002
# List USB Devices
#
usb_002()
{
    run_command \
        "USB-002" \
        "List USB Devices" \
        "lsusb"
}

#
# USB-003
# Check USB Kernel Messages
#
usb_003()
{
    run_command \
        "USB-003" \
        "Check USB Kernel Messages" \
        "dmesg | tail"
}

#
# USB-004
# Mount USB Drive
#
usb_004()
{
    run_command \
        "USB-004" \
        "Mount USB Drive" \
        "mount ${USB_DEVICE} ${USB_MOUNT_POINT}"
}

#
# USB-005
# Write Test File
#
usb_005()
{
    run_command \
        "USB-005" \
        "Write Test File to USB Drive" \
        "dd if=/dev/zero of=${USB_MOUNT_POINT}/${USB_TEST_FILE} bs=1M count=${USB_TEST_SIZE}"
}

#
# USB-006
# Verify Written File
#
usb_006()
{
    run_command \
        "USB-006" \
        "Verify Test File Integrity" \
        "md5sum ${USB_MOUNT_POINT}/${USB_TEST_FILE}"
}

#
# USB-007
# Unmount USB Drive
#
usb_007()
{
    run_command \
        "USB-007" \
        "Unmount USB Drive" \
        "umount ${USB_MOUNT_POINT}"
}

#
# USB-008
# USB Hot Plug Verification
#
usb_008()
{
    log_info "[USB-008] USB Hot Plug Verification"

    echo ""
    echo "==========================================================="
    echo " MANUAL TEST REQUIRED"
    echo "==========================================================="
    echo "1. Disconnect the USB device."
    echo "2. Wait for 5 seconds."
    echo "3. Reconnect the USB device."
    echo "4. Verify that the device is detected."
    echo ""
    read -p "Press ENTER after reconnecting the USB device..."

    run_command \
        "USB-008" \
        "Verify USB Detection After Hot Plug" \
        "dmesg | tail -20"
}

###############################################################################
# Execute all USB Test Cases
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting USB Validation"
    log_info "========================================="

    usb_001
    usb_002
    usb_003
    usb_004
    usb_005
    usb_006
    usb_007
    usb_008

    log_info "========================================="
    log_info "USB Validation Completed"
    log_info "========================================="
}
