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

- DHT22 (GPIO)
- BME280 (I2C)

Sensors are driven via a simple provider interface to keep the core generic and testable.

## Scheduling utilities

```ruby path=null start=null
enum = Dredger::IoT::Scheduler.periodic_with_jitter(base_interval: 10.0, jitter_ratio: 0.2)
sleeps = enum.take(3) # => [8.2, 10.4, 11.7] etc.
```

## Notes

- libgpiod and i2c-dev backends are optional and only required on hardware.
- You can explicitly `require 'dredger/iot/bus/gpio_libgpiod'` or `'dredger/iot/bus/i2c_linux'` when running on target devices.
- The Auto API will attempt to load these backends if it detects the corresponding device nodes are present.
