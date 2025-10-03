# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/TheMadBotterINC/dredger-iot/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/TheMadBotterINC/dredger-iot/releases/tag/v0.1.0
