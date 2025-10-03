# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

The Mad Botter INC takes security seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by email to:

**opensource@themadbotter.com**

Include the following information in your report:

- Type of vulnerability (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the vulnerability
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your vulnerability report within 48 hours
- **Updates**: We will send you regular updates about our progress
- **Disclosure**: Once we've validated and fixed the issue, we will:
  - Issue a security advisory
  - Release a patched version
  - Credit you for the discovery (unless you prefer to remain anonymous)

### Security Best Practices

When using dredger-iot in production:

1. **Run with least privilege**: Don't run as root unless absolutely necessary
   - Use user groups (gpio, i2c) for hardware access instead
   
2. **Validate sensor data**: Always validate and sanitize data from sensors before using it in critical systems

3. **Network isolation**: If exposing sensor data over a network:
   - Use TLS/SSL for encryption
   - Implement proper authentication
   - Consider firewall rules and network segmentation

4. **Keep dependencies updated**: Regularly update the gem and its dependencies
   ```bash
   bundle update dredger-iot
   ```

5. **Simulation mode for testing**: Use simulation backends when testing to avoid hardware conflicts
   ```bash
   export DREDGER_IOT_GPIO_BACKEND=simulation
   export DREDGER_IOT_I2C_BACKEND=simulation
   ```

6. **Hardware access controls**: Ensure proper file permissions on device nodes
   ```bash
   # Check permissions
   ls -l /dev/gpiochip* /dev/i2c-*
   ```

## Known Security Considerations

### Hardware Access

This gem provides direct hardware access via FFI. Users should be aware that:

- **Physical access required**: Malicious code with hardware access could potentially damage equipment
- **GPIO/I2C are privileged**: Ensure only trusted code has access to hardware interfaces
- **No input sanitization at hardware level**: The library trusts that hardware responses are valid

### FFI (Foreign Function Interface)

- The gem uses FFI to interact with system libraries (libgpiod, i2c-dev)
- Ensure your system's shared libraries are from trusted sources
- Keep your system libraries updated

### Simulation Backends

- Simulation backends are for testing only
- They do not provide any real security boundaries
- Never rely on simulation backends for security-sensitive operations

## Scope

This security policy applies to:
- The dredger-iot gem (Ruby code)
- Example scripts provided in the repository
- Documentation that may affect security

This policy does NOT cover:
- Third-party dependencies (report to their respective maintainers)
- Hardware vulnerabilities
- Operating system or kernel vulnerabilities
- Physical security of IoT devices

## Contact

For general security questions (non-vulnerability related), you can:
- Open a [GitHub Discussion](https://github.com/TheMadBotterINC/dredger-iot/discussions)
- Email: opensource@themadbotter.com

---

**Thank you for helping keep dredger-iot and its users safe!**
