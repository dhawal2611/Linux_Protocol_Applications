###############################################################################
# Initialize Framework
###############################################################################

initialize_framework()
{
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    trap cleanup SIGINT
    #
    # Create Directories
    #
    mkdir -p "$LOG_DIR"
    mkdir -p "$CSV_DIR"

    #
    # Create Log Files
    #
    create_log_files

    #
    # Print Framework Information
    #
    print_framework_banner
    print_environment
    print_test_configuration

    #
    # Environment Checks
    #
    check_root
}
###############################################################################
# Create Log/CSV Files
###############################################################################

create_log_files()
{
    #
    # Log File
    #
    if [ "$LOG_FILE_ENABLE" -eq 1 ]
    then
	LOG_FILE="${LOG_DIR}/validation_${TIMESTAMP}_${LOG_TARGET}.log"
        touch "$LOG_FILE"
    fi

    #
    # CSV Report
    #
    if [ "$CSV_REPORT_ENABLE" -eq 1 ]
    then
        touch "$CSV_FILE"

        #
        # CSV Header
        #
        if [ ! -s "$CSV_FILE" ]
        then
            echo "Test ID,Test Name,Result,Start Time,End Time,Execution Time,Command" \
                > "$CSV_FILE"
        fi
    fi
}

###############################################################################
# Check Command Availability
###############################################################################

command_exists()
{
    command -v "$1" >/dev/null 2>&1
}

###############################################################################
# Check Root Permission
###############################################################################

check_root()
{
    if [ "$(id -u)" -ne 0 ]
    then
        log_warn "Framework is not running as root."
        log_warn "Some validation modules may fail."
    fi
}

###############################################################################
# Check Module Dependencies
###############################################################################

check_dependencies()
{
    local CMD

    #
    # No Dependencies
    #
    [ $# -eq 0 ] && return 0

    for CMD in "$@"
    do
        if ! command_exists "$CMD"
        then
            log_error "Required command not found : $CMD"
            return 1
        fi
    done

    return 0
}

###############################################################################
# Print Framework Banner
###############################################################################

print_framework_banner()
{
    echo
    echo "==============================================================================="
    echo "                 Embedded Linux Validation Framework"
    echo "==============================================================================="
    echo
}

###############################################################################
# Print Environment Information
###############################################################################

print_environment()
{
    log_info "Framework Version : ${FRAMEWORK_VERSION}"
    log_info "Execution Time    : $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "Host Name         : $(hostname)"
    log_info "User              : $(whoami)"
    log_info "Kernel            : $(uname -sr)"
    log_info "Architecture      : $(uname -m)"
}

###############################################################################
# Print Test Configuration
###############################################################################

print_test_configuration()
{
    log_info ""
    log_info "Validation Target : ${LOG_TARGET}"
    log_info "Logger Mode       : ${LOGGER_OUTPUT_MODE}"
    log_info "Test Log Mode     : ${TEST_LOG_OUTPUT_MODE}"

    if [ "$CSV_REPORT_ENABLE" -eq 1 ]
    then
        log_info "CSV Report        : Enabled"
    else
        log_info "CSV Report        : Disabled"
    fi

    if [ "$LOOP_MODE" -eq 1 ]
    then
        log_info "Loop Mode         : Enabled"
    else
        log_info "Loop Mode         : Disabled"
    fi

    log_info ""
    log_info "==============================================================================="
}

###############################################################################
# Print Separator
###############################################################################

separator()
{
    printf '%*s\n' 79 '' | tr ' ' '='
}

###############################################################################
# Print Banner
###############################################################################

banner()
{
    local TITLE="$1"

    echo

    separator
    echo "$TITLE"
    separator
}

###############################################################################
# Get Current Timestamp
###############################################################################

get_timestamp()
{
    date "+%Y-%m-%d %H:%M:%S"
}

###############################################################################
# Format Duration
###############################################################################

format_duration()
{
    local TOTAL="$1"

    local DAYS HOURS MINUTES SECONDS

    DAYS=$((TOTAL / 86400))
    HOURS=$(((TOTAL % 86400) / 3600))
    MINUTES=$(((TOTAL % 3600) / 60))
    SECONDS=$((TOTAL % 60))

    if [ "$DAYS" -gt 0 ]
    then
        printf "%dd %02dh %02dm %02ds" \
            "$DAYS" "$HOURS" "$MINUTES" "$SECONDS"

    elif [ "$HOURS" -gt 0 ]
    then
        printf "%02dh %02dm %02ds" \
            "$HOURS" "$MINUTES" "$SECONDS"

    elif [ "$MINUTES" -gt 0 ]
    then
        printf "%02dm %02ds" \
            "$MINUTES" "$SECONDS"

    else
        printf "%02ds" "$SECONDS"
    fi
}

###############################################################################
# Cleanup
###############################################################################

cleanup()
{
    echo

    separator

    log_info "Validation interrupted."

    print_summary

    separator

    exit 0
}

###############################################################################
# Print Blank Line
###############################################################################

newline()
{
    echo
}

###############################################################################
# Check Command Success
###############################################################################

command_success()
{
    [ "$COMMAND_STATUS" -eq 0 ]
}

###############################################################################
# Execute Registered Tests
###############################################################################

run_registered_tests()
{
    local TEST

    banner "Starting ${MODULE_NAME} Validation"

    for TEST in "${TEST_CASES[@]}"
    do
        "$TEST"
    done

    banner "${MODULE_NAME} Validation Completed"
}

###############################################################################
# Get Storage device name
###############################################################################

storage_get_device_name()
{
    case "$STORAGE_DEVICE" in

        "$EMMC_DEVICE")
            echo "eMMC"
            ;;

        "$SDCARD_DEVICE")
            echo "SD Card"
            ;;

        "$NVME_DEVICE")
            echo "NVMe SSD"
            ;;

        "$SATA_DEVICE")
            echo "SATA"
            ;;

        "$USB_DEVICE")
            echo "USB Storage"
            ;;
        "$LOCAL_DEVICE")
            echo "Local Storage"
            ;;

        *)
            echo "Unknown"
            ;;

    esac
}
