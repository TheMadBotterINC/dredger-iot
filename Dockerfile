FROM ruby:3.3-slim

# Install development dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libgpiod-dev \
    i2c-tools \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy gemspec and lock files
COPY dredger-iot.gemspec Gemfile Gemfile.lock ./
COPY lib/dredger/iot/version.rb ./lib/dredger/iot/

# Install gem dependencies
RUN bundle install

# Copy the rest of the application
COPY . .

# Set environment to use simulation backends by default
ENV DREDGER_IOT_GPIO_BACKEND=simulation
ENV DREDGER_IOT_I2C_BACKEND=simulation

# Default command runs tests
CMD ["bundle", "exec", "rspec"]
