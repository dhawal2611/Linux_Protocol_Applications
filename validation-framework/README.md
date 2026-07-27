# Validation Framework

Usage:
./validate.sh crypto
./validate.sh crypto ethernet
./validate.sh all
./validate.sh --loop all

Structure:
- validate.sh: entry point
- config.sh: config
- lib/: utilities
- modules/: test modules
- logs/: output logs

| `COMMAND_OUTPUT_MODE` | Result                                            |
| --------------------- | ------------------------------------------------- |
| `"none"`              | No command output anywhere                        |
| `"console"`           | Command output only on the terminal               |
| `"file"`              | Command output only in the log file (recommended) |
| `"both"`              | Command output on both terminal and log file      |


| `LOGGER_OUTPUT_MODE` | Result                                                     |
| -------------------- | ---------------------------------------------------------- |
| `"console"`          | INFO/PASS/FAIL only on the terminal                        |
| `"file"`             | INFO/PASS/FAIL only in the log file                        |
| `"both"`             | INFO/PASS/FAIL on both terminal and log file (recommended) |


### Example command-line overrides

With the above defaults, users can still override them when running the framework:

```bash
./validate.sh cpu
```

Uses:

* `LOGGER_OUTPUT_MODE="console"`
* `TEST_LOG_OUTPUT_MODE="console"`

```bash
./validate.sh cpu --log file
```

Uses:

* `LOGGER_OUTPUT_MODE="file"`
* `TEST_LOG_OUTPUT_MODE="file"`

```bash
./validate.sh cpu --logger both --testlog file
```

Uses:

* `LOGGER_OUTPUT_MODE="both"`
* `TEST_LOG_OUTPUT_MODE="file"`

This documentation makes it immediately clear to anyone maintaining the framework what each variable controls, the accepted values, and the default behavior.

