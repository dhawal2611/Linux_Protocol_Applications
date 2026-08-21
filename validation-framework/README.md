# Embedded Linux Validation Framework

A modular, shell-based validation framework for embedded Linux hardware testing.
Supports interactive menu, direct CLI, predefined suites, loop/soak mode, and
flexible logging to console, file, or both.

Framework Version: 1.0.0

-------------------------------------------------------------------------------

## Project Structure

    validation-framework/
    |-- validate.sh              Entry point (interactive menu + direct CLI)
    |-- config.sh                Global configuration and defaults
    |-- lib/
    |   |-- arguments.sh         Command-line argument parser
    |   |-- assertions.sh        Test assertion helpers
    |   |-- command.sh           Command execution wrappers
    |   |-- common.sh            Shared utility functions
    |   |-- framework_check.sh   Pre-run environment checks
    |   |-- logger.sh            Logging engine
    |   `-- test_registry.sh     Test registration and result tracking
    |-- modules/                 Individual hardware test modules
    |-- suites/                  Predefined groups of modules
    |-- runtime/                 Runtime state files  (runtime/<module>/)
    |-- logs/                    Generated log files  (logs/<module>.log)
    `-- csv/                     Generated CSV reports (csv/<module>.csv)

-------------------------------------------------------------------------------

## Usage

### Interactive Menu

Run with no arguments to open the interactive menu:

    ./validate.sh

The menu provides:

- Numbered module list (2 columns for fewer than 20 modules, 3 columns otherwise)
- Multi-select by entering numbers separated by spaces  (e.g.  1 3 7)
- Single run or timed loop mode per selection
- Output option prompts (logger, test log, CSV)
- Existing file handling (append or delete before run)
- Confirmation prompt before execution
- Ctrl+C during loop prints a grand summary and returns to the menu

### Direct CLI

    ./validate.sh [OPTIONS] <MODULE(S)|SUITE(S)>

Run one module:

    ./validate.sh cpu

Run multiple modules:

    ./validate.sh cpu ethernet gpio

Run a predefined suite:

    ./validate.sh networking

Run all modules:

    ./validate.sh all

Show help:

    ./validate.sh --help

Show version:

    ./validate.sh --version

-------------------------------------------------------------------------------

## Available Modules

| Module             | Description                           |
|--------------------|---------------------------------------|
| cpu                | CPU functional and load tests         |
| thermal            | Thermal zone and stress tests         |
| power              | Power management tests                |
| ddr4               | DDR memory tests (memtester, stress)  |
| emmc               | eMMC read/write and performance       |
| nvme               | NVMe storage tests                    |
| sata               | SATA storage tests                    |
| spinor             | SPI NOR flash tests                   |
| sdcard             | SD card tests                         |
| spi                | SPI bus interface tests               |
| i2c                | I2C bus interface tests               |
| uart               | UART interface tests                  |
| gpio               | GPIO pin tests                        |
| usb                | USB device tests                      |
| ethernet           | Ethernet link, ping, and iperf        |
| gbe_phy            | GbE PHY validation                    |
| dhcp               | DHCP lease tests                      |
| sshaccess          | SSH access tests                      |
| pcie               | PCIe device enumeration               |
| serdes             | SerDes link tests                     |
| sgmii              | SGMII interface tests                 |
| rtc                | Real-time clock tests                 |
| watchdog           | Watchdog timer tests                  |
| systemd            | systemd service tests                 |
| journald           | journald logging tests                |
| suspend_resume     | Suspend/resume cycle tests            |
| reboot             | Reboot cycle tests                    |
| powercycle         | Power cycle tests                     |
| crypto             | Crypto engine tests                   |
| crypto_stress      | Crypto stress tests                   |
| crypto_luks        | LUKS encryption tests                 |
| crypto_rng         | Hardware RNG tests                    |
| crypto_benchmark   | Crypto benchmark tests                |
| crypto_openssl     | OpenSSL cipher tests                  |
| crypto_kernel      | Kernel crypto API tests               |
| longduration       | Long-duration stress tests            |

Modules are discovered automatically from the modules/ directory at runtime.

### Post Modules

The following modules are used internally for post-reboot or post-powercycle
state verification. They are discovered and listed at runtime but are not
intended to be run standalone.

| Module            | Description                                    |
|-------------------|------------------------------------------------|
| rtc_post          | RTC state check after reboot                   |
| watchdog_post     | Watchdog state check after reboot              |
| reboot_post       | System state check after reboot cycle          |
| powercycle_post   | System state check after power cycle           |
| journald_post     | journald state check after reboot              |

-------------------------------------------------------------------------------

## Available Suites

Suites are predefined module groups located in suites/.

| Suite            | Modules Included                                                        |
|------------------|-------------------------------------------------------------------------|
| basic            | cpu, thermal, power, ddr4                                               |
| storage          | emmc, nvme, sata, spinor                                                |
| interfaces       | spi, i2c, uart, gpio, usb                                               |
| networking       | ethernet, gbe_phy, dhcp, sshaccess, pcie, serdes, sgmii                 |
| power_management | rtc, watchdog, systemd, journald, suspend_resume, reboot, powercycle    |
| security         | crypto                                                                  |
| stress           | longduration, crypto_stress                                             |
| full_validation  | All modules (complete board validation)                                 |

Note: Modules and suites cannot be mixed in the same invocation.

-------------------------------------------------------------------------------

## Command-Line Options

    -h, --help                 Show help and exit
    --version                  Show framework version and exit

    -l, --loop                 Run in loop mode (infinite, stop with Ctrl+C)
    --duration MINUTES         Stop loop after N minutes (requires --loop)

    --logger  MODE             Set logger output mode   (default: console)
    --testlog MODE             Set test log output mode (default: console)

    --csv                      Enable CSV report, auto-named csv/<module>.csv
    --csv <file>               Enable CSV report with a custom filename

-------------------------------------------------------------------------------

## Logging

### LOGGER_OUTPUT_MODE

Controls where framework status messages ([INFO], [PASS], [FAIL], [WARN],
[SKIP], [ERROR]) are written.

    --logger console     Print to terminal only                  (default)
    --logger file        Write to logs/<module>.log only
    --logger both        Print to terminal and write to log file
    --logger none        No file output — messages still appear on console

### TEST_LOG_OUTPUT_MODE

Controls where detailed test execution logs are written. These include
test start/end headers, the executed command, command output, exit status,
and execution time.

    --testlog console    Print to terminal only                  (default)
    --testlog file       Write to logs/<module>.log only
    --testlog both       Print to terminal and write to log file
    --testlog none       Disable all detailed test logs

### Log File Location

Log files are written to the logs/ directory, one file per module:

    logs/<module>.log

The log file is created automatically when --logger or --testlog is set to
"file" or "both". Each run appends a timestamped separator to the file:

    ################################################################################
    # RUN START : 2026-08-21 09:00:00  |  Module: cpu
    ################################################################################

Log files accumulate across runs (append mode). The interactive menu offers
an option to delete existing log files before starting a new run.

-------------------------------------------------------------------------------

## CSV Reports

CSV report generation is disabled by default.

    # Auto-named CSV per module
    ./validate.sh cpu --csv
    # writes to csv/cpu.csv

    # Custom filename (all modules share one file)
    ./validate.sh cpu ethernet --csv my_report.csv
    # writes to csv/my_report.csv

CSV files accumulate across runs (append mode). The interactive menu offers
an option to delete existing CSV files before starting a new run.

-------------------------------------------------------------------------------

## Loop Mode

Loop mode re-runs the selected modules repeatedly. Useful for soak testing
and stability validation.

    # Infinite loop -- stop with Ctrl+C
    ./validate.sh cpu --loop

    # Timed loop -- stop after 10 minutes
    ./validate.sh cpu --loop --duration 10

    # Timed loop with CSV report
    ./validate.sh cpu --loop --duration 5 --csv

LOOP_DURATION_SECS=0 (default) means run indefinitely.

In CLI loop mode, Ctrl+C prints a final summary and exits cleanly.

Note: In CLI loop mode, log files are not written. Results go to CSV only.

-------------------------------------------------------------------------------

## Logging Examples

    # Default: console output only
    ./validate.sh cpu

    # Save logger and test logs to file
    ./validate.sh cpu --logger file --testlog file

    # Logger to terminal, test logs to file
    ./validate.sh cpu --logger console --testlog file

    # Both logger and test logs to terminal and file
    ./validate.sh cpu --logger both --testlog both

    # Suppress all output (silent run, CSV only)
    ./validate.sh cpu --logger none --testlog none --csv

-------------------------------------------------------------------------------

## Configuration (config.sh)

Key settings to review and adjust per board/environment.

### Storage Devices

    EMMC_DEVICE="/dev/mmcblk0"
    SDCARD_DEVICE="/dev/sdb"
    NVME_DEVICE="/dev/nvme0n1"
    SATA_DEVICE="/dev/sda"
    USB_DEVICE="/dev/sdb"

### Ethernet

    ETH_INTERFACES="eth0"

    ETH_SERVER_MAP=(
        "eth0:192.168.134.174"
    )

    ETH_IPERF_DURATION=10          # seconds

### GPIO

    GPIO_OFFSET=512                # Board-specific sysfs offset
    GPIO_PINS=(17 18 22 23)        # Logical pins to validate

### DDR

    DDR_TEST_SIZE="64M"
    DDR_TEST_ITERATION=1
    DDR_STRESS_VM=4
    DDR_STRESS_VM_BYTES="512M"
    DDR_STRESS_TIMEOUT=300         # seconds
    DDR_MBW_SIZE=256

### eMMC

    EMMC_TEST_SIZE="100M"
    EMMC_FIO_SIZE="256M"
    EMMC_FIO_RUNTIME=60            # seconds
    EMMC_MOUNTPOINT="/mnt/emmc_validation"

### SD Card

    SDCARD_FIO_SIZE="256M"
    SDCARD_FIO_RUNTIME=60          # seconds
    SDCARD_MOUNTPOINT_PATH="/mnt/sdcard_validation"

### SATA

    SATA_FIO_SIZE="256M"
    SATA_FIO_RUNTIME=60            # seconds
    SATA_MOUNTPOINT_PATH="/mnt/sata_validation"

### USB

    USB_FIO_SIZE="256M"
    USB_FIO_RUNTIME=30             # seconds

### Thermal

    THERMAL_STRESS_DURATION=5      # seconds
    THERMAL_STRESS_CPU=1

### UART

    UART_DEVICE="/dev/ttyUSB1"
    UART_BAUDRATE=115200
    UART_HIGH_SPEED=921600
    UART_DATABITS=8
    UART_PARITY="none"
    UART_STOPBITS=1
    UART_TEST_DATA="UART_TEST_12345"
    UART_STABILITY_ITERATIONS=100

### SPI

    SPI_DEVICE="/dev/spidev0.0"
    SPI_DEFAULT_SPEED=500000       # Hz
    SPI_TEST_SPEED=1000000         # Hz
    SPI_HIGH_SPEED=10000000        # Hz
    SPI_TRANSFER_DATA="12345678"
    SPI_STABILITY_LOOPS=100

### I2C

    I2C_GENERIC_BUS=1
    I2C_GENERIC_ADDRESS="0x38"
    I2C_GENERIC_DEVICES=("1:0x38")

### Logging Defaults

    LOGGER_OUTPUT_MODE="console"
    TEST_LOG_OUTPUT_MODE="console"

These defaults can always be overridden with --logger and --testlog flags.

-------------------------------------------------------------------------------

## Runtime State

Modules that perform device discovery (spi, i2c, uart) store their discovery
results under the runtime/ directory so that subsequent test cases within the
same module can read them, even when run in separate shell processes:

    runtime/
    |-- uart/
    |   `-- discovered_devices
    |-- spi/
    |   |-- discovery.status
    |   |-- devices.list
    |   `-- primary_device
    `-- i2c/
        |-- buses
        |-- discovery
        `-- status

The runtime/ directory is created automatically. Its contents are overwritten
on each new module run.

-------------------------------------------------------------------------------

## Notes

- Modules are loaded automatically from the modules/ directory at runtime.
- Suites are loaded automatically from the suites/ directory at runtime.
- Modules and suites cannot be mixed in the same invocation.
- --duration without --loop has no effect.
- In CLI loop mode, log files are not created; results go to CSV only.
- In interactive loop mode, multiple modules run in parallel each iteration.
- Press Ctrl+C at any time during loop mode to stop and see the summary.
- bc is not required; the framework uses awk for all floating-point math.
- --logger none does not suppress console output; it only disables file writing.

-------------------------------------------------------------------------------
