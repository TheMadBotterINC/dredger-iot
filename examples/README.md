# Dredger-IoT Examples

This directory contains practical examples demonstrating how to use dredger-iot for various IoT applications.

## Running Examples

All examples can be run directly:

```bash
ruby examples/basic_gpio.rb
```

Or with bundler:

```bash
bundle exec ruby examples/basic_gpio.rb
```

## Available Examples

### `basic_gpio.rb`
Simple GPIO example that blinks an LED on pin P9_12.

**Hardware needed:**
- LED connected to P9_12 with appropriate resistor (220Ω - 1kΩ)

**Demonstrates:**
- Auto GPIO backend selection
- Setting pin direction
- Writing digital values
- Resource cleanup

---

### `dht22_sensor.rb`
Reads temperature and humidity from a DHT22 sensor.

**Hardware needed:**
- DHT22 sensor connected to P9_12
- 10kΩ pull-up resistor on data line

**Demonstrates:**
- GPIO-based sensor reading
- Provider pattern
- Sensor metadata
- Error handling
- Reading timing requirements

---

### `ds18b20_temperature.rb`
Reads temperature from DS18B20 waterproof sensor(s).

**Hardware needed:**
- DS18B20 sensor(s) connected to 1-Wire bus
- 4.7kΩ pull-up resistor on data line
- w1-gpio and w1-therm kernel modules loaded

**Demonstrates:**
- 1-Wire sensor discovery
- Device enumeration
- Continuous temperature monitoring
- Celsius to Fahrenheit conversion

---

### `multi_sensor_monitor.rb`
Complete environmental monitoring system with multiple sensors and scheduled polling.

**Hardware needed:**
- DHT22 sensor on GPIO P9_12
- BME280 sensor on I2C (address 0x76)

**Demonstrates:**
- Multi-sensor setup
- Scheduled polling with jitter
- Both GPIO and I2C sensors
- Graceful shutdown
- Optional JSON logging
- Real-world monitoring application

---

### `sht31_sensor.rb`
Reads temperature and humidity from SHT31.

**Hardware needed:**
- SHT31 sensor on I2C (default address 0x44)

**Run:**
```bash
ruby examples/sht31_sensor.rb
# or override address
SHT31_ADDR=0x45 ruby examples/sht31_sensor.rb
```

---

### `bh1750_lux.rb`
Reads ambient light (lux) from BH1750.

**Hardware needed:**
- BH1750 sensor on I2C (default address 0x23)

**Run:**
```bash
ruby examples/bh1750_lux.rb
# or override address
BH1750_ADDR=0x5C ruby examples/bh1750_lux.rb
```

---

### `tsl2561_lux.rb`
Reads ambient light (lux) from TSL2561.

**Hardware needed:**
- TSL2561 sensor on I2C (default address 0x39)

**Run:**
```bash
ruby examples/tsl2561_lux.rb
# or override address
TSL2561_ADDR=0x29 ruby examples/tsl2561_lux.rb
```

---

### `ina219_monitor.rb`
Monitors bus voltage and current using INA219.

**Hardware needed:**
- INA219 sensor on I2C (default address 0x40)
- Known shunt resistor (default 0.1Ω)

**Run:**
```bash
ruby examples/ina219_monitor.rb
# override shunt and address
INA219_SHUNT=0.05 INA219_ADDR=0x41 ruby examples/ina219_monitor.rb
```

---

## Simulation Mode

All examples will run in simulation mode if no hardware is detected. This is perfect for testing and development:

```bash
export DREDGER_IOT_GPIO_BACKEND=simulation
export DREDGER_IOT_I2C_BACKEND=simulation
ruby examples/multi_sensor_monitor.rb
```

## Customization

Feel free to modify these examples for your specific hardware setup:

- Change pin numbers/labels
- Adjust I2C addresses
- Modify polling intervals
- Add different sensors
- Implement custom data logging

## Need Help?

See the main [README](../README.md) for:
- Hardware setup instructions
- Troubleshooting guide
- Complete API reference
- Sensor specifications
