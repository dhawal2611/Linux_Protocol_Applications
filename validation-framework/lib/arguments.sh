#!/bin/bash
###############################################################################
# File        : arguments.sh
# Description : Command Line Argument Parser
###############################################################################

###############################################################################
# Display Help
###############################################################################
show_help()
{
cat << EOF

===============================================================================
                 Embedded Linux Validation Framework
===============================================================================

Usage:
    ./validate.sh <module>
    ./validate.sh <suite>
    ./validate.sh all
    ./validate.sh -l <module>
    ./validate.sh --loop <module>

Examples

Run CPU Validation
    ./validate.sh cpu

Run DDR4 Validation
    ./validate.sh ddr4

Run Crypto Validation
    ./validate.sh crypto

Run Multiple Modules
    ./validate.sh cpu ddr4 ethernet

Run Storage Suite
    ./validate.sh storage

Run Networking Suite
    ./validate.sh networking

Run Power Management Suite
    ./validate.sh power_management

Run Security Suite
    ./validate.sh security

Run Interface Suite
    ./validate.sh interfaces

Run Stress Suite
    ./validate.sh stress

Run Complete Validation
    ./validate.sh full_validation

Run All Modules
    ./validate.sh all

Continuous Mode
    ./validate.sh --loop cpu

Help
    ./validate.sh --help

===============================================================================

EOF
}

###############################################################################
# Supported Individual Modules
###############################################################################

VALID_MODULES=(
cpu
thermal
power
ddr4
emmc
nvme
sata
spinor
spi
i2c
uart
gpio
ethernet
gbe_phy
dhcp
ssh
pcie
serdes
sgmii
usb
rtc
rtc_post
watchdog
watchdog_post
systemd
journald
suspend_resume
reboot
reboot_post
power_cycle
power_cycle_post
crypto
crypto_kernel
crypto_openssl
crypto_benchmark
crypto_rng
crypto_luks
crypto_stress
long_duration_stress
)

###############################################################################
# Supported Test Suites
###############################################################################

VALID_SUITES=(
basic
storage
interfaces
networking
power_management
security
stress
full_validation
)

###############################################################################
# Parse Command Line Arguments
###############################################################################

parse_arguments()
{
    MODULE_LIST=()

    while [[ $# -gt 0 ]]
    do
        case "$1" in

            -l|--loop)
                LOOP_MODE=1
                ;;

            -h|--help)
                show_help
                exit 0
                ;;
	    --log)
		    shift

		    case "$1" in
			console|file|both)
			    LOGGER_OUTPUT_MODE="$1"
			    TEST_LOG_OUTPUT_MODE="$1"
			    ;;
			*)
			    echo "Invalid log mode: $1"
			    echo "Valid values: console, file, both"
			    exit 1
			    ;;
		    esac
		    ;;

		--logger)
		    shift

		    case "$1" in
			console|file|both)
			    LOGGER_OUTPUT_MODE="$1"
			    ;;
			*)
			    echo "Invalid logger mode: $1"
			    exit 1
			    ;;
		    esac
		    ;;

		--testlog)
		    shift

		    case "$1" in
			console|file|both|none)
			    TEST_LOG_OUTPUT_MODE="$1"
			    ;;
			*)
			    echo "Invalid test log mode: $1"
			    exit 1
			    ;;
		    esac
		    ;;

            all)

                MODULE_LIST=(
                cpu
                thermal
                power
                ddr4
                emmc
                nvme
                sata
                spinor
                spi
                i2c
                uart
                gpio
                ethernet
                gbe_phy
                dhcp
                ssh
                pcie
                serdes
                sgmii
                usb
                rtc
                watchdog
                systemd
                journald
                suspend_resume
                reboot
                power_cycle
                crypto
                long_duration_stress
                )

                ;;

            *)

                FOUND=0

                #
                # Check Module
                #
                for module in "${VALID_MODULES[@]}"
                do
                    if [ "$module" = "$1" ]
                    then
                        MODULE_LIST+=("$1")
                        FOUND=1
                        break
                    fi
                done

                #
                # Check Suite
                #
                if [ "$FOUND" -eq 0 ]
                then
                    for suite in "${VALID_SUITES[@]}"
                    do
                        if [ "$suite" = "$1" ]
                        then
                            MODULE_LIST+=("$1")
                            FOUND=1
                            break
                        fi
                    done
                fi

                #
                # Invalid Input
                #
                if [ "$FOUND" -eq 0 ]
                then
                    echo ""
                    echo "ERROR : Invalid module/suite : $1"
                    echo ""

                    show_help

                    exit 1
                fi
                ;;

        esac

        shift

    done

    if [ ${#MODULE_LIST[@]} -eq 0 ]
    then
        echo ""
        echo "ERROR : No module selected."
        echo ""

        show_help

        exit 1
    fi
}
