#!/bin/bash
###############################################################################
# Module      : Crypto Validation
# Description : Master Crypto Validation Module
###############################################################################

run_submodule()
{
    MODULE="$1"

    log_info ""
    log_info "============================================================"
    log_info "Running Crypto Module : ${MODULE}"
    log_info "============================================================"

    source "${SCRIPT_DIR}/modules/${MODULE}.sh"

    run_test
}

###############################################################################
# Execute Crypto Validation
###############################################################################

run_test()
{
    log_info ""
    log_info "############################################################"
    log_info "#           COMPLETE CRYPTO VALIDATION SUITE               #"
    log_info "############################################################"

    run_submodule "crypto_kernel"
    run_submodule "crypto_openssl"
    run_submodule "crypto_benchmark"
    run_submodule "crypto_rng"
    run_submodule "crypto_luks"
    run_submodule "crypto_stress"

    log_info ""
    log_info "############################################################"
    log_info "#     COMPLETE CRYPTO VALIDATION FINISHED SUCCESSFULLY     #"
    log_info "############################################################"
}
