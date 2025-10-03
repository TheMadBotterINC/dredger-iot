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
