# Clock Stretching

Clock Stretching is an optional feature of the I2C protocol that allows a Slave device to temporarily pause communication when it is not ready to continue transferring data.

This mechanism enables slower peripheral devices to communicate reliably with faster Masters.

---

# Why Clock Stretching is Required

The Master typically controls the SCL signal and determines the communication speed.

However, some slave devices require additional processing time before they can:

* Accept new data
* Process received commands
* Perform measurements
* Fetch data from internal memory
* Complete analog conversions

Examples include:

* Temperature Sensors
* Humidity Sensors
* EEPROM Devices
* ADC Converters
* RTC Devices

Without Clock Stretching, the Master would continue transmitting data, potentially causing communication failures.

---

# How Clock Stretching Works

Normally, the Master generates clock pulses on the SCL line.

During Clock Stretching:

1. The Master releases the SCL line.
2. The Slave keeps the SCL line LOW.
3. Communication is temporarily paused.
4. The Slave completes its internal operation.
5. The Slave releases SCL.
6. The Master resumes communication.

---

# Timing Representation

```text
Master SCL

──────┐      ┌────────────────────────
      │      │
      └──────┘



Slave SCL

────────────────┐
                │
                └─────────────────────



Bus SCL

──────┐____________________┌──────────
      │                    │
      │<-- Stretch Time -->│
      └────────────────────┘
```

---

# Signal Behavior

During Clock Stretching:

### Master

Attempts to drive SCL HIGH.

### Slave

Keeps SCL LOW.

### Bus

Remains LOW.

Communication resumes only after the Slave releases the clock.

---

# Example Scenario

Suppose a humidity sensor requires 80 ms to complete a measurement.

Sequence:

```text
Master sends command

        │

        ▼

Slave starts conversion

        │

        ▼

Slave holds SCL LOW

        │

        ▼

Conversion completed

        │

        ▼

Slave releases SCL

        │

        ▼

Master continues communication
```

---

# AHT20 Example

The AHT20 sensor internally requires time to perform humidity and temperature measurements.

Typical application:

```text
Trigger Measurement

        │

        ▼

Wait for Conversion

        │

        ▼

Read Sensor Data
```

Linux example:

```bash
i2ctransfer -y 1 \
w3@0x38 0xAC 0x33 0x00 && \
sleep 0.1 && \
i2ctransfer -y 1 r7@0x38
```

The delay ensures that the sensor has sufficient time to complete the conversion.

Some devices use Clock Stretching internally, while others rely on software delays.

---

# Devices Commonly Using Clock Stretching

Examples:

* AHT20
* BMP280
* BME280
* ADS1115
* MCP3421
* DS3231
* AT24Cxx EEPROM

---

# Linux Support

The Linux I2C subsystem supports Clock Stretching.

Support depends on:

* I2C Controller Hardware
* Device Driver
* Kernel Configuration

Most modern controllers support it transparently.

Applications typically do not need special handling.

---

# Advantages

Clock Stretching provides several benefits.

---

## Reliable Communication

Allows slower devices to communicate safely.

---

## Improved Compatibility

Supports peripherals with long processing times.

---

## Reduces Data Corruption

Prevents incomplete transfers.

---

## Simplifies Slave Design

Slave devices do not need to operate at the maximum bus speed.

---

# Limitations

Clock Stretching also introduces some challenges.

---

## Increased Latency

Communication pauses while waiting for the slave.

---

## Controller Dependency

Some I2C controllers do not fully support stretching.

---

## Debug Complexity

Bus analyzers may show extended LOW periods.

This can sometimes be mistaken for communication faults.

---

# Detecting Clock Stretching

An oscilloscope or logic analyzer can be used.

Observe:

```text
SCL remains LOW

Longer than expected
```

Example:

```text
Expected Clock Period

5 µs


Observed Clock Period

25 µs


Clock Stretching

20 µs
```

---

# Linux Debugging

Useful commands:

Check available buses.

```bash
ls /dev/i2c*
```

Scan devices.

```bash
i2cdetect -y 1
```

Read sensor.

```bash
i2ctransfer -y 1 w3@0x38 0xAC 0x33 0x00 && sleep 0.1 && i2ctransfer -y 1 r7@0x38
```

---

# Best Practices

Recommendations:

* Verify controller support.
* Use logic analyzers during debugging.
* Respect device conversion times.
* Avoid aggressive polling.
* Follow sensor datasheet timing requirements.

---

# Summary

Clock Stretching is an important feature of the I2C protocol that enables slower slave devices to temporarily pause communication.

It improves interoperability between devices operating at different speeds and ensures reliable data transfers, especially for sensors, EEPROMs, and ADCs that require additional processing time.
