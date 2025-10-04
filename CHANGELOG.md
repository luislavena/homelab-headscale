# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v0.4.0 - 2025-10-04

### Changed

- Change ENV placeholder in-place for broad compatibility

## v0.3.1 - 2025-10-03

### Fixed

- Restore variable interpolation in configuration

## v0.3.0 - 2025-10-02

### Added

- Advertise Headscale HTTP port in container

## v0.2.0 - 2025-10-02

### Added

- Ability to turn replication off using DISABLE_REPLICATION variable

### Changed

- Use environment variables directly in Headscale configuration
- Use 2-providers S3 replicas
- Upgrade Alpine Linux to latest 3.22.x
- Split Headscale and Litestream container layers
- Run headscale as non-root user
- Cleanup container entrypoint logic
- Cleanup container configs and script
- Removes unused DERP private key
- Upgrade Headscale to 0.26.1
- Remove unused DERP config reference
- Removed logtail setting (disabled by default)
- Automatically removes ephemeral nodes after 30 minutes

### Fixed

- Fix global DNS configuration compatible with 0.26.1
- Use correct location for private key
- Remove unused variable after cleanup

### Internal

- Automate releases using GitHub Actions
- Split Fly.io instructions from main README
- Move testing Compose out of main codebase

## 0.1.0 - 2025-10-01

- Pre-versioning Headscale + Litestream release
