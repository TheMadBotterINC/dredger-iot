```
                      _______________                              
                     |  DREDGER-IoT  |                            
                     |_______________|                            
                    /|   ___     ___ |\                           
                   / |  |___|   |___|| \                          
                  /  |______________|  \                         
             ====|========================|====                   
            |    |    |-----------|     |    |                   
            |    |____|           |_____|    |                   
         ___|____|                         |____|___             
    ~~~~{________|_________________________|________}~~~~~~~     
      ~~      |  \\                     //  |         ~~~        
              |   \\___________________//   |                    
              |_____________________________|                    
         ~~~       \\                 //          ~~~            
                    \\_______________//                          

       Hardware Integration for Embedded Linux
```

[![CI](https://github.com/TheMadBotterINC/dredger-iot/workflows/CI/badge.svg)](https://github.com/TheMadBotterINC/dredger-iot/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/dredger-iot.svg)](https://badge.fury.io/rb/dredger-iot)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-ruby.svg)](https://www.ruby-lang.org/)

A small, FOSS Ruby library for hardware access on embedded Linux (Beaglebone Black, etc.).

Goals:
- Generic, device-agnostic hardware integration (no proprietary references)
- Clean abstractions for GPIO and I2C
- Pluggable sensor drivers (DHT22, BME280 as starters)
- Simple scheduling/retry helpers
- Config-driven pin mapping (Beaglebone P9_XX labels)

License: MIT (c) The Mad Botter INC

## Installation

Add to your Gemfile:

```ruby path=null start=null
gem 'dredger-iot', git: 'https://github.com/TheMadBotterINC/dredger-iot'
```

## Backends

Dredger-IoT supports multiple backends per bus:
- GPIO: Simulation (default), libgpiod (via FFI)
- I2C: Simulation (default), Linux i2c-dev (via FFI + ioctl)

Backends are not auto-required for portability. Use the Auto API to choose an appropriate backend at runtime.

## Auto-selection API

```ruby path=null start=null
require 'dredger/iot'

# GPIO
gpio = Dredger::IoT::Bus::Auto.gpio
# I2C
i2c  = Dredger::IoT::Bus::Auto.i2c
```

Auto rules:
- GPIO: if /dev/gpiochip0 exists and libgpiod is available → libgpiod; else simulation
- I2C: if bus path exists (default /dev/i2c-1) and backend is available → linux; else simulation

Environment overrides:
- `DREDGER_IOT_GPIO_BACKEND`: `simulation` | `libgpiod`
- `DREDGER_IOT_I2C_BACKEND`: `simulation` | `linux`

## Raspberry Pi GPIO label mapping

When the libgpiod backend is selected via Auto, Dredger-IoT resolves Raspberry Pi labels to the corresponding chip:line before accessing the GPIO line. Accepted labels:
- GPIO17 or BCM17 (Broadcom numbering)
- PIN11 or BOARD11 (header pin numbers)

On most Raspberry Pi boards, GPIO lines are exposed on gpiochip0 and the line offset matches the BCM number. The adapter will translate labels accordingly.

Example:

```ruby path=null start=null
require 'dredger/iot'

gpio = Dredger::IoT::Bus::Auto.gpio # picks libgpiod on RPi, otherwise simulation

# Use Raspberry Pi labels
gpio.set_direction('GPIO17', :out)
gpio.write('GPIO17', 1)
```

## Beaglebone P9_XX label mapping

When the libgpiod backend is selected via Auto, Dredger-IoT resolves Beaglebone labels like `P9_12` to the corresponding `gpiochipN:line` before accessing the GPIO line. A minimal built-in table is provided and can be extended in future releases.

Example:

```ruby path=null start=null
require 'dredger/iot'

gpio = Dredger::IoT::Bus::Auto.gpio # picks libgpiod on BBB, otherwise simulation

# Works with labels; on BBB this is translated to the correct chip:line
gpio.set_direction('P9_12', :out)
gpio.write('P9_12', 1)
value = gpio.read('P9_12')
```

If you run on a development host (no /dev/gpiochip0), Auto will default to the simulation backend and still accept labels without error, though they have no hardware effect.

## Sensors

Dredger-IoT includes drivers for popular embedded sensors:

- **DHT22** - GPIO humidity/temperature sensor
- **BME280** - I2C temperature/humidity/pressure sensor
- **DS18B20** - 1-Wire digital temperature sensor
- **BMP180** - I2C barometric pressure/temperature sensor
- **MCP9808** - I2C high-accuracy temperature sensor
- **SHT31** - I2C temperature/humidity sensor
- **BH1750** - I2C ambient light sensor (lux)
- **TSL2561** - I2C ambient light sensor (lux)
- **INA219** - I2C bus voltage/current monitor

Sensors use a provider pattern for testability and hardware abstraction.

## CLI Usage

Commands:
- list-sensors
  - List available sensor types supported by dredger-iot.
- read SENSOR [ARGS]
  - Read once or continuously from a sensor.
  - Examples:
    - dredger read bme280 0x76
    - dredger read dht22 P9_12
    - dredger read ina219 0x40 --shunt 0.1
- test-gpio PIN
  - Simple blink test to verify GPIO output works.
- test-i2c
  - Scans a few common I2C addresses (hardware backend only).
- info
  - Prints version, detected backends, and environment variables.

Options:
- --backend BACKEND
  - auto (default), simulation, hardware
  - simulation forces both GPIO and I2C simulation backends
  - hardware forces libgpiod (GPIO) and linux (I2C)
- --format FORMAT
  - text (default) or json
- --interval SECONDS
  - Poll continuously at the specified interval (e.g., 2.0)
- --shunt OHMS
  - INA219-only: specify the shunt resistance in ohms (default 0.1)

Examples:
```bash
# Read a BME280 once (auto-detected backends)
dredger read bme280 0x76

# Read a DHT22 every 2 seconds, JSON output
dredger read dht22 P9_12 --interval 2 --format json

# Force simulation backends for local testing
dredger --backend simulation read bh1750 0x23

# INA219 with custom shunt
dredger read ina219 0x40 --shunt 0.05
```

## Usage Examples

### DHT22 Temperature/Humidity Sensor

```ruby path=null start=null
require 'dredger/iot'

# Set up GPIO bus and DHT22 provider
gpio = Dredger::IoT::Bus::Auto.gpio
provider = Dredger::IoT::Sensors::DHT22Provider.new(gpio_bus: gpio)

# Create sensor instance
sensor = Dredger::IoT::Sensors::DHT22.new(
  pin_label: 'P9_12',
  provider: provider,
  metadata: { location: 'greenhouse' }
)

# Read measurements
readings = sensor.readings
readings.each do |r|
  puts "#{r.sensor_type}: #{r.value} #{r.unit}"
end
# => humidity: 65.2 %
# => temperature: 22.3 celsius
```

### BME280 Environmental Sensor

```ruby path=null start=null
require 'dredger/iot'

# Set up I2C bus and BME280 provider
i2c = Dredger::IoT::Bus::Auto.i2c
provider = Dredger::IoT::Sensors::BME280Provider.new(i2c_bus: i2c)

# Create sensor instance (default I2C address 0x76)
sensor = Dredger::IoT::Sensors::BME280.new(
  i2c_addr: 0x76,
  provider: provider,
  metadata: { location: 'weather_station' }
)

# Read all measurements
readings = sensor.readings
readings.each { |r| puts "#{r.sensor_type}: #{r.value} #{r.unit}" }
# => temperature: 24.1 celsius
# => humidity: 40.2 %
# => pressure: 101.4 kPa
```

### DS18B20 Waterproof Temperature Sensor

```ruby path=null start=null
require 'dredger/iot'

# Uses Linux kernel w1-gpio module (no FFI needed)
provider = Dredger::IoT::Sensors::DS18B20Provider.new

# List available devices
devices = provider.list_devices
puts "Found devices: #{devices.inspect}"
# => ["28-0000056789ab", "28-0000056789cd"]

# Read from specific device
sensor = Dredger::IoT::Sensors::DS18B20.new(
  device_id: '28-0000056789ab',
  provider: provider,
  metadata: { location: 'tank_a' }
)

temp = sensor.readings.first
puts "#{temp.value}°C"
```

### Multiple Sensors with Scheduled Polling

```ruby path=null start=null
require 'dredger/iot'

# Set up buses
gpio = Dredger::IoT::Bus::Auto.gpio
i2c = Dredger::IoT::Bus::Auto.i2c

# Create multiple sensors
sensors = [
  Dredger::IoT::Sensors::DHT22.new(
    pin_label: 'P9_12',
    provider: Dredger::IoT::Sensors::DHT22Provider.new(gpio_bus: gpio),
    metadata: { zone: 'indoor' }
  ),
  Dredger::IoT::Sensors::BME280.new(
    i2c_addr: 0x76,
    provider: Dredger::IoT::Sensors::BME280Provider.new(i2c_bus: i2c),
    metadata: { zone: 'outdoor' }
  )
]

# Poll sensors with jitter to avoid harmonics
scheduler = Dredger::IoT::Scheduler.periodic_with_jitter(
  base_interval: 60.0,
  jitter_ratio: 0.1
)

scheduler.each do |interval|
  sleep interval
  
  sensors.each do |sensor|
    readings = sensor.readings
    timestamp = Time.now.iso8601
    
    readings.each do |r|
      puts "#{timestamp} [#{r.metadata[:zone]}] #{r.sensor_type}: #{r.value} #{r.unit}"
    end
  end
end
```

## Scheduling Utilities

### Periodic with Jitter

Avoid harmonic spikes by adding randomized jitter to intervals:

```ruby path=null start=null
enum = Dredger::IoT::Scheduler.periodic_with_jitter(
  base_interval: 10.0,
  jitter_ratio: 0.2
)
sleeps = enum.take(3) # => [8.2, 10.4, 11.7] etc.
```

### Exponential Backoff

Retry failed operations with increasing delays:

```ruby path=null start=null
backoff = Dredger::IoT::Scheduler.exponential_backoff(
  base: 1.0,
  max: 30.0,
  attempts: 5
)

backoff.each do |delay|
  sleep delay
  break if try_operation # retry until success or attempts exhausted
end
```

## Hardware Setup

### Prerequisites

On embedded Linux hardware (Beaglebone, Raspberry Pi, etc.), certain kernel modules and permissions are required.

#### GPIO (libgpiod)

```bash path=null start=null
# Ensure gpiod tools are installed (optional but useful for testing)
sudo apt-get install gpiod

# Verify GPIO chips are available
ls /dev/gpiochip*

# Add user to gpio group for permissions
sudo usermod -a -G gpio $USER
# Log out and back in for group changes to take effect
```

#### I2C

```bash path=null start=null
# Enable I2C kernel module
sudo modprobe i2c-dev

# Make it permanent
echo 'i2c-dev' | sudo tee -a /etc/modules

# Add user to i2c group
sudo usermod -a -G i2c $USER

# Set permissions (if group doesn't exist)
sudo chmod 666 /dev/i2c-*
```

#### DS18B20 (1-Wire)

The DS18B20 sensor requires the kernel w1-gpio module:

```bash path=null start=null
# Load 1-Wire kernel modules
sudo modprobe w1-gpio
sudo modprobe w1-therm

# Make it permanent
echo 'w1-gpio' | sudo tee -a /etc/modules
echo 'w1-therm' | sudo tee -a /etc/modules

# Verify devices are detected
ls /sys/bus/w1/devices/
# Should show devices like: 28-00000xxxxxx
```

#### Raspberry Pi OS: Enable I2C and 1-Wire

On Raspberry Pi OS you can enable I2C and 1-Wire via raspi-config or by editing /boot/config.txt.

Option A: raspi-config (recommended)
```bash path=null start=null
sudo raspi-config
# Interface Options → I2C → Enable
# Interface Options → 1-Wire → Enable
sudo reboot
```

Option B: edit /boot/config.txt
```bash path=null start=null
# Enable I2C
sudo sed -i 's/^#\?dtparam=i2c_arm=.*/dtparam=i2c_arm=on/' /boot/config.txt
# Enable 1-Wire on default BCM4 (PIN7)
echo 'dtoverlay=w1-gpio,gpiopin=4' | sudo tee -a /boot/config.txt
sudo reboot
```

Note: Dredger-IoT accepts Raspberry Pi labels like GPIO17, BCM17, and PIN11.

#### Beaglebone Black Device Tree

For Beaglebone Black, you may need to enable device tree overlays:

```bash path=null start=null
# Edit /boot/uEnv.txt and enable overlays:
# For I2C:
uboot_overlay_addr4=/lib/firmware/BB-I2C1-00A0.dtbo

# For GPIO/1-Wire (if using P9_12 for example):
uboot_overlay_addr5=/lib/firmware/BB-W1-P9.12-00A0.dtbo

# Reboot after changes
sudo reboot
```

## Troubleshooting

### Permission Denied Errors

**Problem:** `Errno::EACCES: Permission denied - /dev/gpiochip0` or `/dev/i2c-1`

**Solution:**
```bash path=null start=null
# Add your user to the appropriate group
sudo usermod -a -G gpio $USER
sudo usermod -a -G i2c $USER

# Or temporarily change permissions (not recommended for production)
sudo chmod 666 /dev/gpiochip*
sudo chmod 666 /dev/i2c-*

# Log out and back in for group changes
```

### DS18B20 Not Found

**Problem:** `No DS18B20 devices found` or empty `/sys/bus/w1/devices/`

**Solution:**
```bash path=null start=null
# Verify modules are loaded
lsmod | grep w1

# Load if missing
sudo modprobe w1-gpio
sudo modprobe w1-therm

# Check dmesg for errors
sudo dmesg | grep w1

# Verify wiring: DS18B20 requires 4.7kΩ pull-up resistor on data line
```

### FFI Library Not Found

**Problem:** `LoadError: cannot load such file -- ffi`

**Solution:**
```bash path=null start=null
# Install FFI gem
gem install ffi

# Or ensure it's in your Gemfile
bundle install
```

### Sensor Reading Returns Nil or Errors

**Problem:** Sensor readings fail or return nil values

**Solutions:**
- **Verify wiring:** Double-check sensor connections (VCC, GND, data lines)
- **Check I2C address:** Use `i2cdetect -y 1` to scan for devices
- **Timing issues:** DHT22 requires ~2 second intervals between reads
- **Power supply:** Ensure adequate power for sensors (some require 3.3V, others 5V)
- **Enable simulation backend** for testing without hardware:
  ```bash path=null start=null
  export DREDGER_IOT_GPIO_BACKEND=simulation
  export DREDGER_IOT_I2C_BACKEND=simulation
  ```

### I2C Device Not Detected

**Problem:** I2C sensor not responding

**Solution:**
```bash path=null start=null
# Install i2c-tools
sudo apt-get install i2c-tools

# Scan I2C bus (bus 1 is common, try 0 if not found)
i2cdetect -y 1

# Should show device at its address (e.g., 0x76 for BME280)
# If not detected:
# - Check wiring and pull-up resistors (typically 4.7kΩ on SDA/SCL)
# - Verify I2C is enabled in device tree
# - Check for bus conflicts
```

## API Reference

### Core Modules

#### `Dredger::IoT::Bus::Auto`

Automatic backend selection for GPIO and I2C buses.

```ruby path=null start=null
gpio = Dredger::IoT::Bus::Auto.gpio  # Returns GPIO backend
i2c = Dredger::IoT::Bus::Auto.i2c    # Returns I2C backend
```

#### `Dredger::IoT::Bus::GPIOLibgpiod`

FFI-based GPIO access using libgpiod.

**Methods:**
- `set_direction(pin, direction)` - Set pin as `:in` or `:out`
- `write(pin, value)` - Write `0` or `1` to output pin
- `read(pin)` - Read current value from pin (returns `0` or `1`)
- `close` - Release GPIO resources

#### `Dredger::IoT::Bus::I2CLinux`

FFI-based I2C access using Linux i2c-dev.

**Methods:**
- `write(addr, data)` - Write bytes to I2C device at address
- `read(addr, count)` - Read bytes from I2C device
- `write_read(addr, write_data, read_count)` - Combined write then read
- `close` - Release I2C bus

### Sensors

All sensors follow a common interface:

```ruby path=null start=null
sensor = Dredger::IoT::Sensors::SensorClass.new(
  # Sensor-specific parameters
  provider: provider_instance,
  metadata: { custom: 'data' }  # Optional metadata
)

readings = sensor.readings  # Returns array of Reading objects
```

#### `Reading` Object

```ruby path=null start=null
reading.sensor_type  # e.g., 'temperature', 'humidity', 'pressure'
reading.value        # Numeric value
reading.unit         # Unit string (e.g., 'celsius', '%', 'kPa')
reading.metadata     # Hash of custom metadata
reading.timestamp    # Time object when reading was taken
```

#### Available Sensors

- **`DHT22`** - Temperature/humidity (GPIO)
  - Parameters: `pin_label`, `provider`
  - Returns: temperature (celsius), humidity (%)
  
- **`BME280`** - Environmental sensor (I2C)
  - Parameters: `i2c_addr` (default: `0x76`), `provider`
  - Returns: temperature (celsius), humidity (%), pressure (kPa)
  
- **`DS18B20`** - Waterproof temperature (1-Wire)
  - Parameters: `device_id`, `provider`
  - Returns: temperature (celsius)
  
- **`BMP180`** - Barometric pressure (I2C)
  - Parameters: `i2c_addr` (default: `0x77`), `provider`
  - Returns: temperature (celsius), pressure (kPa)
  
- **`MCP9808`** - High-accuracy temperature (I2C)
  - Parameters: `i2c_addr` (default: `0x18`), `provider`
  - Returns: temperature (celsius)
  
- **`SHT31`** - Temperature/humidity (I2C)
  - Parameters: `i2c_addr` (default: `0x44`), `provider`
  - Returns: temperature (celsius), humidity (%)
  
- **`BH1750`** - Ambient light (I2C)
  - Parameters: `i2c_addr` (default: `0x23`), `provider`
  - Returns: illuminance (lux)
  
- **`TSL2561`** - Ambient light (I2C)
  - Parameters: `i2c_addr` (default: `0x39`), `provider`
  - Returns: illuminance (lux)
  
- **`INA219`** - Bus voltage/current monitor (I2C)
  - Parameters: `i2c_addr` (default: `0x40`), `provider`
  - Returns: bus_voltage (V), current (mA)
  - CLI example:
    ```bash path=null start=null
    dredger read ina219 0x40 --shunt 0.1
    ```

### Scheduling

#### `Dredger::IoT::Scheduler.periodic_with_jitter`

Generates intervals with randomized jitter to avoid harmonic patterns.

```ruby path=null start=null
scheduler = Dredger::IoT::Scheduler.periodic_with_jitter(
  base_interval: 60.0,   # Base interval in seconds
  jitter_ratio: 0.1      # ±10% jitter
)

scheduler.each { |interval| sleep interval; poll_sensors }
```

#### `Dredger::IoT::Scheduler.exponential_backoff`

Generates exponentially increasing delays for retry logic.

```ruby path=null start=null
backoff = Dredger::IoT::Scheduler.exponential_backoff(
  base: 1.0,      # Initial delay
  max: 30.0,      # Maximum delay
  attempts: 5     # Number of attempts
)

backoff.each { |delay| sleep delay; break if retry_operation }
```

## Notes

- libgpiod and i2c-dev backends are optional and only required on hardware.
- You can explicitly `require 'dredger/iot/bus/gpio_libgpiod'` or `'dredger/iot/bus/i2c_linux'` when running on target devices.
- The Auto API will attempt to load these backends if it detects the corresponding device nodes are present.
- Simulation backends are perfect for development and testing without hardware access.
