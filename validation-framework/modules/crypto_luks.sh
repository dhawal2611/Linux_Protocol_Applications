#!/bin/bash
###############################################################################
# Module      : Crypto LUKS Validation
# Description : Validate dm-crypt / LUKS
###############################################################################

#
# CRYPTO-LUKS-001
# Create Image
#
crypto_luks_001()
{
    run_command \
        "CRYPTO-LUKS-001" \
        "Create Encrypted Image" \
        "dd if=/dev/zero of=${CRYPT_IMAGE} bs=1M count=${CRYPT_IMAGE_SIZE}"
}

#
# CRYPTO-LUKS-002
# Format LUKS
#
crypto_luks_002()
{
    run_command \
        "CRYPTO-LUKS-002" \
        "Format LUKS Image" \
        "echo -n ${CRYPT_PASSWORD} | cryptsetup luksFormat \
        --batch-mode \
        ${CRYPT_IMAGE} -"
}

#
# CRYPTO-LUKS-003
# Open Device
#
crypto_luks_003()
{
    run_command \
        "CRYPTO-LUKS-003" \
        "Open LUKS Device" \
        "echo -n ${CRYPT_PASSWORD} | cryptsetup luksOpen \
        ${CRYPT_IMAGE} \
        ${CRYPT_MAPPER} -"
}

#
# CRYPTO-LUKS-004
# Create Filesystem
#
crypto_luks_004()
{
    run_command \
        "CRYPTO-LUKS-004" \
        "Create ${CRYPT_FS} Filesystem" \
        "mkfs.${CRYPT_FS} /dev/mapper/${CRYPT_MAPPER}"
}

#
# CRYPTO-LUKS-005
# Create Mount Point
#
crypto_luks_005()
{
    run_command \
        "CRYPTO-LUKS-005" \
        "Create Mount Point" \
        "mkdir -p ${CRYPT_MOUNT}"
}

#
# CRYPTO-LUKS-006
# Mount Device
#
crypto_luks_006()
{
    run_command \
        "CRYPTO-LUKS-006" \
        "Mount LUKS Device" \
        "mount /dev/mapper/${CRYPT_MAPPER} ${CRYPT_MOUNT}"
}

#
# CRYPTO-LUKS-007
# Write Test File
#
crypto_luks_007()
{
    run_command \
        "CRYPTO-LUKS-007" \
        "Write Test File" \
        "echo '${CRYPT_TEST_STRING}' > ${CRYPT_MOUNT}/${CRYPT_TEST_FILE}"
}

#
# CRYPTO-LUKS-008
# Read Test File
#
crypto_luks_008()
{
    run_command \
        "CRYPTO-LUKS-008" \
        "Read Test File" \
        "cat ${CRYPT_MOUNT}/${CRYPT_TEST_FILE}"
}

#
# CRYPTO-LUKS-009
# Verify Test File
#
crypto_luks_009()
{
    run_command \
        "CRYPTO-LUKS-009" \
        "Verify Test File" \
        "grep '${CRYPT_TEST_STRING}' \
        ${CRYPT_MOUNT}/${CRYPT_TEST_FILE}"
}

#
# CRYPTO-LUKS-010
# Unmount Device
#
crypto_luks_010()
{
    run_command \
        "CRYPTO-LUKS-010" \
        "Unmount Filesystem" \
        "umount ${CRYPT_MOUNT}"
}

#
# CRYPTO-LUKS-011
# Close LUKS Device
#
crypto_luks_011()
{
    run_command \
        "CRYPTO-LUKS-011" \
        "Close LUKS Device" \
        "cryptsetup luksClose ${CRYPT_MAPPER}"
}

#
# CRYPTO-LUKS-012
# Cleanup
#
crypto_luks_012()
{
    run_command \
        "CRYPTO-LUKS-012" \
        "Cleanup Test Files" \
        "rm -rf ${CRYPT_MOUNT} ${CRYPT_IMAGE}"
}

###############################################################################
# Execute Module
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting Crypto LUKS Validation"
    log_info "========================================="

    crypto_luks_001
    crypto_luks_002
    crypto_luks_003
    crypto_luks_004
    crypto_luks_005
    crypto_luks_006
    crypto_luks_007
    crypto_luks_008
    crypto_luks_009
    crypto_luks_010
    crypto_luks_011
    crypto_luks_012

    log_info "========================================="
    log_info "Crypto LUKS Validation Completed"
    log_info "========================================="
}
