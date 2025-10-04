# Performance Benchmarks

Performance benchmarks for dredger-iot operations.

## Running Benchmarks

All benchmarks use simulation backends by default:

```bash
# GPIO operations benchmark
ruby benchmark/gpio_benchmark.rb

# Sensor polling benchmark
ruby benchmark/sensor_benchmark.rb
```

Or use bundler:

```bash
bundle exec ruby benchmark/gpio_benchmark.rb
bundle exec ruby benchmark/sensor_benchmark.rb
```

## Benchmark Scripts

### `gpio_benchmark.rb`

Tests GPIO operation speeds:
- Write operations (setting pin HIGH/LOW)
- Read operations (reading pin state)
- Direction changes (switching between input/output)

### `sensor_benchmark.rb`

Tests sensor reading speeds:
- Individual sensor polling (DHT22, BME280)
- Multi-sensor polling
- Provides real-world timing expectations

## Notes

- **Simulation Backend**: Benchmarks use simulation by default for consistency
- **Hardware Performance**: Real hardware will be slower due to actual I/O operations
- **Platform Variance**: Results will vary significantly based on:
  - CPU speed
  - Hardware platform (Beaglebone vs Raspberry Pi)
  - Sensor response times
  - I2C/GPIO clock speeds

## Expected Real-World Performance

### GPIO (Hardware)
- Write: 1-10µs per operation
- Read: 1-10µs per operation
- Limited by system call overhead and hardware access

### Sensors (Hardware)
- **DHT22**: ~250ms per reading (sensor limitation)
- **BME280**: 10-50ms (depends on oversampling settings)
- **DS18B20**: 750ms-1000ms (sensor conversion time)
- **BMP180**: 5-26ms (depends on oversampling mode)
- **MCP9808**: 30-250ms (depends on resolution)

## Adding New Benchmarks

Create a new file in `benchmark/` following this pattern:

```ruby
#!/usr/bin/env ruby
require 'bundler/setup'
require 'dredger/iot'
require 'benchmark'

# Set backends
ENV['DREDGER_IOT_GPIO_BACKEND'] = 'simulation'

# Your benchmark code here
Benchmark.bm(20) do |x|
  x.report('Operation:') do
    # Your test
  end
end
```

Make it executable:
```bash
chmod +x benchmark/your_benchmark.rb
```
