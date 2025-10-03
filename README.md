# Dredger-IoT

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

Sensors use a provider pattern for testability and hardware abstraction.

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

## Notes

- libgpiod and i2c-dev backends are optional and only required on hardware.
- You can explicitly `require 'dredger/iot/bus/gpio_libgpiod'` or `'dredger/iot/bus/i2c_linux'` when running on target devices.
- The Auto API will attempt to load these backends if it detects the corresponding device nodes are present.
