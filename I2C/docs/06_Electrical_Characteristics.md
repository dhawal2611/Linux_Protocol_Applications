# Electrical Characteristics

I2C uses **open-drain/open-collector outputs**, which require external pull-up resistors on both the SDA and SCL lines.

The electrical characteristics of the bus directly affect communication reliability, signal integrity, and achievable bus speeds.

Poor electrical design can result in:

* Communication failures
* Missing acknowledgements
* Corrupted data
* Timing violations
* Bus lockups

---

# Open-Drain Architecture

Unlike push-pull outputs, I2C devices cannot actively drive the bus HIGH.

Devices can only:

* Pull the line LOW
* Release the line

Pull-up resistors are responsible for restoring the bus to a HIGH level.

---

## Open-Drain Bus

```text
                VCC
                 │
            ┌────┴────┐
            │         │
          Rp SDA    Rp SCL
            │         │
            │         │
Master ─────┼─────────┼──────── Slave1
            │         │
            ├─────────┼──────── Slave2
            │         │
            └─────────┼──────── Slave3
                      │
```

---

# Pull-up Resistors

Pull-up resistors are mandatory in I2C communication.

Without pull-ups:

* SDA remains floating
* SCL remains floating
* Communication becomes unreliable

---

## Why Pull-ups Are Needed

Devices can only sink current.

They cannot source current.

The resistor provides a path to VCC.

---

## Typical Circuit

```text
        VCC
         │
       4.7kΩ
         │
SDA ─────┼──────── Slave1
         │
         ├──────── Slave2
         │
         └──────── Master



        VCC
         │
       4.7kΩ
         │
SCL ─────┼──────── Slave1
         │
         ├──────── Slave2
         │
         └──────── Master
```

---

# Selecting Pull-up Resistors

Choosing the proper resistor value is important.

Selection depends on:

* Supply voltage
* Bus capacitance
* Number of devices
* Required rise time
* Communication speed

---

## Recommended Values

| Bus Speed | Pull-up Value        |
| --------- | -------------------- |
| 100 kbps  | 4.7 kΩ               |
| 400 kbps  | 2.2 kΩ               |
| 1 Mbps    | 1.8 kΩ               |
| 3.4 Mbps  | 680 Ω                |
| 5 Mbps    | Application Specific |

---

## Effects of Small Resistors

Advantages:

* Faster rise times
* Better signal integrity
* Supports higher speeds

Disadvantages:

* Increased power consumption
* Higher sink current

---

## Effects of Large Resistors

Advantages:

* Lower current consumption

Disadvantages:

* Slow signal transitions
* Timing violations
* Reduced maximum speed

---

# Bus Capacitance

Each component connected to the bus contributes capacitance.

Examples:

* MCU pins
* Sensors
* Connectors
* PCB traces
* Cables

---

# Maximum Bus Capacitance

According to the I2C specification:

Maximum recommended bus capacitance:

```text
400 pF
```

for Standard and Fast modes.

---

## Typical Capacitance Values

| Component    | Capacitance |
| ------------ | ----------- |
| MCU Pin      | 5–10 pF     |
| Sensor       | 5–15 pF     |
| Connector    | 2–5 pF      |
| PCB Trace    | 1–3 pF/cm   |
| Ribbon Cable | 50–100 pF/m |

---

# Rise Time

Rise time represents the transition from LOW to HIGH.

Slow rise times can cause communication failures.

---

## Rise Time Formula

Approximation:

```text
Tr = 0.8473 × Rp × Cbus
```

Where:

```text
Tr      = Rise Time

Rp      = Pull-up Resistance

Cbus    = Total Bus Capacitance
```

---

## Example Calculation

Assume:

```text
Rp = 4.7kΩ

Cbus = 200 pF
```

Calculation:

```text
Tr = 0.8473 × 4700 × 200×10⁻¹²


Tr ≈ 0.8 µs
```

---

# Maximum Rise Time Limits

| Mode     | Rise Time |
| -------- | --------- |
| 100 kbps | 1000 ns   |
| 400 kbps | 300 ns    |
| 1 Mbps   | 120 ns    |
| 3.4 Mbps | 80 ns     |

---

# Fall Time

Fall time is influenced primarily by device output drivers.

Unlike rise time:

Pull-up resistors have minimal impact.

---

## Maximum Fall Time

Typical specification:

| Mode           | Fall Time |
| -------------- | --------- |
| Standard Mode  | 300 ns    |
| Fast Mode      | 300 ns    |
| Fast Mode Plus | 120 ns    |

---

# Signal Integrity

Signal integrity becomes critical at higher speeds.

Common issues:

* Ringing
* Overshoot
* Undershoot
* Noise coupling

---

## Symptoms

Examples:

* Missing ACK
* Communication retries
* Device lockup
* Bus hangs

---

# Oscilloscope Verification

Recommended measurements:

Observe:

### SDA Rise Time

Measure:

```text
30% → 70%
```

---

### SCL Rise Time

Measure:

```text
30% → 70%
```

---

### Idle State

Expected:

```text
SDA = HIGH

SCL = HIGH
```

---

### Clock Stretching

Observe:

Long LOW periods.

---

# PCB Layout Recommendations

Good PCB design significantly improves communication reliability.

---

## Recommended Practices

Keep traces short.

Use solid ground plane.

Place pull-ups near Master.

Avoid long stubs.

Keep away from switching regulators.

---

## Avoid

Long ribbon cables.

Weak pull-ups.

Large capacitive loads.

Excessive fan-out.

Poor grounding.

---

# Long Cable Applications

For cable-based systems:

Reduce pull-up values.

Typical:

```text
1kΩ – 2.2kΩ
```

Consider:

Shielded cables.

Twisted pair routing.

Bus extenders.

---

# Practical Recommendations

Most embedded systems operate successfully with:

* 4.7kΩ pull-ups
* Bus capacitance below 200 pF
* Speeds of 100 kbps or 400 kbps

Examples:

* AHT20
* EEPROM
* RTC
* OLED

---

# Design Tips

For robust I2C designs:

✔ Verify rise times with an oscilloscope

✔ Follow sensor datasheet recommendations

✔ Minimize trace lengths

✔ Respect bus capacitance limits

✔ Use appropriate pull-up resistors

✔ Validate communication using Linux I2C tools

---

# Summary

Electrical characteristics play a crucial role in ensuring reliable I2C communication.

Proper pull-up resistor selection, maintaining acceptable bus capacitance, verifying rise times, and following good PCB layout practices help achieve stable communication, especially in embedded Linux systems where multiple sensors and peripherals share the same I2C bus.
