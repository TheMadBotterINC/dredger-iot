# Dredger-IoT

A small, FOSS Ruby library for hardware access on embedded Linux (Beaglebone Black, etc.).

Goals:
- Generic, device-agnostic hardware integration (no proprietary references)
- Clean abstractions for GPIO and I2C
- Pluggable sensor drivers (DHT22, BME280 as starters)
- Simple scheduling/retry helpers
- Config-driven pin mapping (Beaglebone P9_XX labels)

License: MIT (c) The Mad Botter INC