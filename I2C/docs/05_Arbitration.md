# Arbitration

Arbitration is a mechanism used in I2C communication to resolve conflicts when multiple Masters attempt to access the bus simultaneously.

It ensures that only one Master controls the bus at any given time without corrupting ongoing transactions.

Arbitration is one of the key features that enables I2C to support **multi-master systems**.

---

# Why Arbitration is Required

In systems with multiple Masters, there is a possibility that two or more Masters may try to initiate communication at the same time.

Without arbitration:

* Data collisions may occur.
* Transactions may become corrupted.
* Slave devices may receive invalid data.
* Bus communication reliability would be compromised.

Arbitration guarantees that only one Master wins access to the bus.

---

# Arbitration Principle

Arbitration is performed using the **SDA line**.

Each Master continuously monitors the SDA line while transmitting data.

The fundamental rule is:

```text id="0h2qax"
LOW dominates HIGH
```

This is possible because the I2C bus uses open-drain outputs.

---

# Arbitration Process

The arbitration process follows these steps:

1. Two Masters start transmitting simultaneously.
2. Both Masters generate clock pulses.
3. Each Master places data on SDA.
4. Each Master monitors SDA.
5. If a Master transmits HIGH but observes LOW, it loses arbitration.
6. The losing Master immediately stops transmission.
7. The winning Master continues communication.

---

# Example Arbitration

Consider two Masters.

---

## Master 1

Transmits:

```text id="eopvjc"
1
```

---

## Master 2

Transmits:

```text id="km45lx"
0
```

---

## Bus Result

Observed value:

```text id="te6q3r"
0
```

Because LOW dominates HIGH.

Master 1 loses arbitration.

Master 2 wins arbitration.

---

# Timing Representation

```text id="mnbq6g"

Master1 SDA

──────────────1──────────────



Master2 SDA

──────────────0──────────────



Bus SDA

──────────────0──────────────



Master1

Stops transmission



Master2

Continues communication

```

---

# Arbitration During Address Transmission

Arbitration commonly occurs while Masters are transmitting slave addresses.

Example:

---

Master 1

```text id="puj3z9"
0x38
```

Binary

```text id="n5qupw"
00111000
```

---

Master 2

```text id="c1i0pj"
0x68
```

Binary

```text id="p5p7up"
01101000
```

---

At the first differing bit:

Master 1 transmits

```text id="shjlwm"
0
```

Master 2 transmits

```text id="8x1r0w"
1
```

Bus becomes

```text id="v1gwn7"
0
```

Master 2 detects loss of arbitration.

Master 1 continues.

---

# Arbitration Example Flow

```text id="nvf90k"

Master1 START
              │
              ▼

Master2 START
              │
              ▼

Address Transmission
              │
              ▼

SDA Comparison
              │
              ▼

Master1 Wins
              │
              ▼

Master2 Stops
              │
              ▼

Master1 Continues


```

---

# Open-Drain Requirement

Arbitration is only possible because I2C uses open-drain outputs.

Characteristics:

* Devices can pull SDA LOW.
* Devices cannot actively drive SDA HIGH.
* Pull-up resistors generate HIGH level.
* LOW always dominates HIGH.

---

# Arbitration and SCL

Arbitration primarily uses SDA.

SCL synchronization is also important.

If one Master stretches the clock:

All Masters must wait.

This ensures synchronized communication.

---

# Advantages of Arbitration

---

## Collision Avoidance

Prevents simultaneous Masters from corrupting data.

---

## Automatic Bus Sharing

No additional software coordination required.

---

## Reliable Communication

Ensures only one active transmitter.

---

## Suitable for Redundant Systems

Useful in:

* Automotive Systems
* Industrial Controllers
* Multi-Processor Designs

---

# Limitations

---

## Increased Complexity

Multi-master implementations require additional hardware and software validation.

---

## Rarely Used in Consumer Devices

Most embedded systems use:

```text id="j7gafz"

Single Master

Multiple Slaves

```

Examples:

* Linux SBC
* Raspberry Pi
* i.MX6ULL
* STM32
* CN9130

---

# Linux Considerations

Linux systems generally operate as a single I2C Master.

Examples:

* Embedded Linux
* Yocto Systems
* OpenWRT
* Industrial Gateways

Arbitration handling is typically implemented within the I2C controller hardware.

Applications usually do not need to manage arbitration directly.

---

# Debugging Arbitration Issues

Useful tools:

Oscilloscope

Logic Analyzer

Linux Utilities

```bash id="7xhhlt"
i2cdetect -y 1
```

```bash id="twwcy8"
i2ctransfer -y 1 ...
```

Monitor:

* Unexpected STOP conditions
* Lost transactions
* Arbitration loss messages
* Repeated retries

---

# Practical Recommendations

For most embedded Linux applications:

Recommended architecture:

```text id="h2mtt2"

Single Master


Multiple Slaves


AHT20


RTC


EEPROM


OLED


ADC


```

Advantages:

* Simpler software
* Easier debugging
* Better reliability

---

# Summary

Arbitration is a powerful feature of the I2C protocol that enables multiple Masters to share a common communication bus.

It relies on the open-drain characteristics of the SDA line, where a LOW level always dominates a HIGH level. Masters continuously monitor SDA while transmitting, and any Master detecting a mismatch immediately stops communication, allowing the winning Master to complete the transaction without data corruption.

Arbitration is essential in true multi-master systems but is rarely encountered in typical embedded Linux applications, where a single Master communicating with multiple Slaves remains the most common architecture.
