# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

Dredger-IoT is a FOSS Ruby library for hardware integration on embedded Linux systems (Beaglebone Black, Raspberry Pi, etc.). It provides generic, device-agnostic hardware access through pluggable backends for GPIO and I2C buses, along with a growing collection of sensor drivers.

**Key Design Principles:**
- Hardware abstraction through backend pattern (simulation/hardware)
- Provider pattern for sensor implementations (enables testing without hardware)
- Platform-agnostic label mapping (Beaglebone P9_XX, Raspberry Pi GPIO/BCM/PIN labels)
- FFI-based native access (libgpiod for GPIO, i2c-dev for I2C)

## Rules

1. **Commit often.** Make small, frequent commits as you work. Don't batch up large changes into a single commit.
2. **Full test coverage.** Every change must include comprehensive tests. All new code paths, edge cases, and error conditions must be covered by specs.
3. **Never mention AI tools.** Do not reference AI tools, assistants, copilots, or similar in code, comments, commit messages, PRs, or documentation.

## Development Commands

### Testing
```bash
# Run all tests (default task includes rubocop + rspec)
bundle exec rake

# Run tests only
bundle exec rspec

# Run specific test file
bundle exec rspec spec/dredger/iot/sensors/bme280_spec.rb

# Run specific test by line number
bundle exec rspec spec/dredger/iot/sensors/bme280_spec.rb:42
```

### Linting
```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix safe offenses
bundle exec rubocop -a

# Auto-fix all offenses (including unsafe)
bundle exec rubocop -A
```

### Building & Installing
```bash
# Build gem
bundle exec rake build

# Install locally
bundle exec rake install

# Release (bump version, tag, push)
bundle exec rake release
```

### CLI Testing
```bash
# List available sensors
bin/dredger list-sensors

# Test reading sensor (simulation mode)
bin/dredger --backend simulation read bme280 0x76

# Test reading with continuous polling
bin/dredger read dht22 P9_12 --interval 2 --format json

# Test GPIO functionality
bin/dredger test-gpio P9_12

# Check system prerequisites
bin/dredger doctor

# Show system info and detected backends
bin/dredger info
```

## Architecture

### Module Structure

**`Dredger::IoT::Bus`** - Hardware bus abstraction layer
- `Bus::Auto` - Auto-detects and instantiates appropriate backend (simulation vs hardware)
- `Bus::GPIO` - GPIO interface wrapper with simulation fallback
- `Bus::GpioLibgpiod` - FFI implementation using libgpiod (hardware)
- `Bus::GPIOLabelAdapter` - Translates platform-specific labels (P9_12, GPIO17, etc.) to chip:line
- `Bus::I2C` - I2C interface wrapper with simulation fallback
- `Bus::I2cLinux` - FFI implementation using i2c-dev ioctl (hardware)

**`Dredger::IoT::Pins`** - Pin label mapping tables
- `Pins::Beaglebone` - Maps P8_XX/P9_XX labels to gpiochip:line
- `Pins::RaspberryPi` - Maps GPIO/BCM/PIN/BOARD labels to gpiochip:line

**`Dredger::IoT::Sensors`** - Sensor implementations
- `BaseSensor` - Abstract base class with common reading interface
- Each sensor has two classes:
  - `SensorNameProvider` - Hardware interaction logic (injected for testability)
  - `SensorName` - Public sensor interface (composition of provider + metadata)

**`Dredger::IoT::Scheduler`** - Timing utilities
- `periodic_with_jitter` - Generates intervals with randomized jitter to avoid harmonic patterns
- `exponential_backoff` - Retry logic with exponential delay

**`Dredger::IoT::Reading`** - Standardized sensor reading data structure

### Backend Selection Pattern

The Auto module inspects the system at runtime:
1. Check for device node existence (`/dev/gpiochip0`, `/dev/i2c-1`)
2. Attempt to load FFI backend
3. Fall back to simulation if hardware unavailable or FFI load fails
4. Override via environment variables: `DREDGER_IOT_GPIO_BACKEND`, `DREDGER_IOT_I2C_BACKEND`

This allows the same code to run on development machines (simulation) and embedded hardware (native access) without changes.

### Provider Pattern for Sensors

Sensors use dependency injection for hardware access:
```ruby
# Provider encapsulates hardware interaction
provider = Dredger::IoT::Sensors::BME280Provider.new(i2c_bus: i2c)

# Sensor consumes provider + adds metadata/interface
sensor = Dredger::IoT::Sensors::BME280.new(i2c_addr: 0x76, provider: provider)
```

This enables:
- Unit testing without hardware (mock providers)
- Simulation backends for development
- Clean separation of concerns (sensor logic vs bus I/O)

## Adding New Sensors

When adding a new sensor driver, follow this pattern:

1. **Create provider class** (`lib/dredger/iot/sensors/sensor_name_provider.rb`):
   - Implement hardware-specific read/write logic
   - Accept bus instance(s) in constructor (gpio_bus or i2c_bus)
   - Keep methods focused on raw hardware interaction

2. **Create sensor class** (`lib/dredger/iot/sensors/sensor_name.rb`):
   - Inherit from `BaseSensor`
   - Accept provider instance and metadata in constructor
   - Implement `readings` method returning array of `Reading` objects
   - Use `reading(sensor_type:, value:, unit:)` helper method

3. **Add specs** (`spec/dredger/iot/sensors/sensor_name_spec.rb`, `*_provider_spec.rb`):
   - Test with mock bus or simulation backend
   - Cover edge cases (nil values, out of range, etc.)

4. **Update CLI** (`bin/dredger`):
   - Add to `list_sensors` hash
   - Add case to `create_sensor` method

5. **Update RuboCop config** (`.rubocop.yml`):
   - Add sensor name mapping to `RSpec/SpecFilePathFormat` if needed

6. **Document in README** with usage example

Example sensor files to reference: BME280, DHT22, DS18B20

## Code Style Guidelines

- **Ruby version**: 3.2+ (configured in `.ruby-version`, gemspec, rubocop)
- **Style guide**: Standard Ruby with RuboCop enforcement
- **Line length**: 120 characters max
- **Test framework**: RSpec with custom transforms for IoT terminology
- **Naming conventions**: snake_case, idiomatic Ruby/Rails style
- **FFI code**: Keep in separate backend files, don't load unless needed

### RuboCop Exceptions
- `Style/Documentation` disabled (sensor classes are self-documenting)
- `Metrics/MethodLength` relaxed for provider classes and specs
- `Metrics/AbcSize` relaxed for provider classes
- `RSpec/MultipleExpectations` and `RSpec/ExampleLength` disabled

## Hardware Testing

Backends require specific kernel modules and permissions:

**GPIO (libgpiod):**
- Requires `/dev/gpiochip*` device nodes
- Add user to `gpio` group: `sudo usermod -a -G gpio $USER`

**I2C:**
- Requires `i2c-dev` kernel module: `sudo modprobe i2c-dev`
- Add user to `i2c` group: `sudo usermod -a -G i2c $USER`
- Device tree configuration may be needed (Beaglebone: `/boot/uEnv.txt`)

**1-Wire (DS18B20):**
- Requires `w1-gpio` and `w1-therm` kernel modules
- Devices appear at `/sys/bus/w1/devices/`

For development without hardware, use simulation backends:
```bash
export DREDGER_IOT_GPIO_BACKEND=simulation
export DREDGER_IOT_I2C_BACKEND=simulation
```

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`):
- Runs on: push to master/main/develop, pull requests
- Ruby matrix: 3.2, 3.3
- Jobs: RuboCop lint, RSpec tests
- Tests run with simulation backends (no hardware required)

## File Organization

```
lib/dredger/iot/
├── bus/              # Bus abstraction layer
│   ├── auto.rb       # Auto-detection logic
│   ├── gpio*.rb      # GPIO backends
│   └── i2c*.rb       # I2C backends
├── pins/             # Pin label mapping tables
├── sensors/          # Sensor drivers (pairs of sensor + provider)
├── reading.rb        # Data structure for sensor readings
├── scheduler.rb      # Timing/retry utilities
└── version.rb

spec/                 # RSpec tests (mirrors lib/ structure)
examples/             # Runnable example scripts
bin/dredger           # CLI tool
```

## Publishing

This gem is published to RubyGems:
- Repository: https://github.com/TheMadBotterINC/dredger-iot
- Gem: https://rubygems.org/gems/dredger-iot
- Requires MFA for publishing (configured in gemspec)
