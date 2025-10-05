# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2025-10-05

### Added
- Examples: Raspberry Pi GPIO blink script (GPIO17)
- Docs: Raspberry Pi OS instructions to enable I2C and 1-Wire

## [0.2.0] - 2025-10-05

### Added
- New sensors: SHT31 (I2C temp/humidity), BH1750 (I2C lux), TSL2561 (I2C lux), INA219 (I2C bus voltage/current)
- CLI: --shunt option for INA219 to specify shunt resistance (default 0.1 Ω)
- Examples: example scripts for SHT31, BH1750, TSL2561, INA219

### Changed
- README: document new sensors and CLI usage
- Coverage: exclude all provider implementations from coverage (hardware-dependent)

## [0.1.2] - 2025-10-04

### Added
- Developer tools and community infrastructure.

### Changed
- Examples: seed BME280 calibration and sample data for I2C simulation.
- Examples: allow interval/cycles override via env for fast simulation runs.

## [0.1.1] - 2025-10-04

### Fixed
- Update CI workflows to use upload-artifact@v4 (v3 deprecated)
- Exclude vendor directory from RuboCop to prevent scanning bundled gems
- Fix Gemfile.lock synchronization with semantic FFI versioning
- Resolve all RuboCop violations with auto-corrections
- Add sensor name transforms for DS18B20, BMP180, MCP9808

### Changed
- Drop Ruby 3.1 support, require Ruby >= 3.2
- Update RuboCop target Ruby version to 3.2
- Increase MethodLength cop limit to 20 for scheduler methods
- Disable metric cops for provider implementations and examples

## [0.1.0] - 2025-10-03

### Added
- Initial release of dredger-iot gem
- GPIO access via libgpiod FFI backend with simulation fallback
- I2C access via Linux i2c-dev FFI backend with simulation fallback
- Auto-selection API for automatic backend detection
- Beaglebone Black P9_XX pin label mapping for libgpiod
- Sensor drivers:
  - DHT22 (GPIO-based temperature/humidity sensor)
  - BME280 (I2C temperature/humidity/pressure sensor)
  - DS18B20 (1-Wire temperature sensor via kernel w1-gpio)
  - BMP180 (I2C barometric pressure/temperature sensor)
  - MCP9808 (I2C high-accuracy temperature sensor)
- Provider pattern for sensor abstraction and testability
- Scheduling utilities:
  - `periodic_with_jitter` for distributed polling
  - `exponential_backoff` for retry logic
- Full RSpec test suite with 100% coverage (excluding hardware providers)
- RuboCop configuration and compliance
- Comprehensive documentation and usage examples

[Unreleased]: https://github.com/TheMadBotterINC/dredger-iot/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/TheMadBotterINC/dredger-iot/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/TheMadBotterINC/dredger-iot/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/TheMadBotterINC/dredger-iot/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/TheMadBotterINC/dredger-iot/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/TheMadBotterINC/dredger-iot/releases/tag/v0.1.0
