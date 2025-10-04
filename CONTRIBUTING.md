# Contributing to dredger-iot

Thanks for your interest in contributing! We welcome issues, PRs, and ideas to make this project better.

## Getting Started

1. Fork the repository and clone your fork
2. Install Ruby (>= 3.2) and Bundler
3. Install dependencies:
   ```bash
   bundle install
   ```
4. Run tests and linters:
   ```bash
   bundle exec rspec
   bundle exec rubocop --no-server
   ```

### Using Docker (optional)

You can use Docker for a consistent dev environment:

```bash
# Build and run an interactive dev shell
docker compose run --rm dev

# Run tests
docker compose run --rm test

# Run RuboCop
docker compose run --rm lint
```

## Project Structure

- `lib/` - Library source code
- `spec/` - RSpec tests
- `examples/` - Example scripts
- `bin/` - Executable scripts (CLI)
- `.github/workflows/` - CI/CD workflows

## Code Style

- We use RuboCop with project-specific rules
- Auto-correct where appropriate:
  ```bash
  bundle exec rubocop --autocorrect
  ```

## Running Tests

```bash
bundle exec rspec
```

We aim for high coverage. Hardware provider code may be partially excluded due to hardware dependencies.

## Commit Messages

- Use concise, descriptive commit messages
- For larger changes, include a summary and rationale in the PR description

## Pull Requests

1. Create a feature branch: `git checkout -b feature/my-change`
2. Ensure tests pass and lint is clean
3. Update docs/README/examples as needed
4. Open a PR with a clear description of the change

### PR Checklist

- [ ] Tests added/updated
- [ ] RuboCop passes
- [ ] README/docs updated (if needed)
- [ ] Changes are scoped and minimal

## Reporting Issues

- Use the Bug Report template when possible
- Include environment details, reproduction steps, and expected behavior

## Releasing (Maintainers)

1. Update `lib/dredger/iot/version.rb`
2. Update `CHANGELOG.md`
3. Tag release: `git tag vX.Y.Z && git push origin vX.Y.Z`
4. GitHub Actions will build and publish (if RUBYGEMS_API_KEY is configured)

## Code of Conduct

This project follows a standard Code of Conduct. Be respectful and considerate.
