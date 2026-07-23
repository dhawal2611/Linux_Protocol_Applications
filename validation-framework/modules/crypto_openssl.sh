#!/bin/bash
###############################################################################
# Module      : Crypto OpenSSL Validation
# Description : Validate OpenSSL Encryption / Decryption
###############################################################################

#
# CRYPTO-OPENSSL-001
# Generate Random Data
#
crypto_openssl_001()
{
    run_command \
        "CRYPTO-OPENSSL-001" \
        "Generate Random Test File" \
        "dd if=/dev/urandom of=${CRYPTO_TEST_FILE} bs=1M count=${CRYPTO_TEST_SIZE_MB}"
}

#
# CRYPTO-OPENSSL-002
# Encrypt File
#
crypto_openssl_002()
{
    run_command \
        "CRYPTO-OPENSSL-002" \
        "Encrypt File (${CRYPTO_AES_ALGO})" \
        "openssl enc -${CRYPTO_AES_ALGO} \
         -k ${CRYPTO_PASSWORD} \
         -in ${CRYPTO_TEST_FILE} \
         -out ${CRYPTO_ENC_FILE}"
}

#
# CRYPTO-OPENSSL-003
# Decrypt File
#
crypto_openssl_003()
{
    run_command \
        "CRYPTO-OPENSSL-003" \
        "Decrypt File (${CRYPTO_AES_ALGO})" \
        "openssl enc -d -${CRYPTO_AES_ALGO} \
         -k ${CRYPTO_PASSWORD} \
         -in ${CRYPTO_ENC_FILE} \
         -out ${CRYPTO_DEC_FILE}"
}

#
# CRYPTO-OPENSSL-004
# Verify File Integrity
#
crypto_openssl_004()
{
    run_command \
        "CRYPTO-OPENSSL-004" \
        "Verify Encrypted/Decrypted File Integrity" \
        "cmp ${CRYPTO_TEST_FILE} ${CRYPTO_DEC_FILE}"
}

#
# CRYPTO-OPENSSL-005
# Verify MD5 Checksum
#
crypto_openssl_005()
{
    run_command \
        "CRYPTO-OPENSSL-005" \
        "Verify MD5 Checksums" \
        "md5sum ${CRYPTO_TEST_FILE} ${CRYPTO_DEC_FILE}"
}

#
# CRYPTO-OPENSSL-006
# Cleanup Test Files
#
crypto_openssl_006()
{
    run_command \
        "CRYPTO-OPENSSL-006" \
        "Cleanup Temporary Files" \
        "rm -f ${CRYPTO_TEST_FILE} \
               ${CRYPTO_ENC_FILE} \
               ${CRYPTO_DEC_FILE}"
}

###############################################################################
# Execute OpenSSL Validation
###############################################################################

run_test()
{
    log_info "========================================="
    log_info "Starting OpenSSL Validation"
    log_info "Algorithm : ${CRYPTO_AES_ALGO}"
    log_info "========================================="

    crypto_openssl_001
    crypto_openssl_002
    crypto_openssl_003
    crypto_openssl_004
    crypto_openssl_005
    crypto_openssl_006

    log_info "========================================="
    log_info "OpenSSL Validation Completed"
    log_info "========================================="
}
