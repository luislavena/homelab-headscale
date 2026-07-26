# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v0.7.0 - 2026-07-26

### Changed

- Upgrade to Alpine Linux 3.24.1
- Upgrade to Litestream 0.3.14, fixing a panic during database restore
- Move ephemeral node timeout to the new `node.ephemeral.inactivity_timeout` setting
- Upgrade to Headscale 0.29.2 (upgrade from 0.28.x only, skipping minor versions is blocked)

### Fixed

- Take Litestream snapshots hourly to shorten database restores

### Internal

- Keep only one line in VERSION file

## v0.6.0 - 2026-03-08

### Changed

- Upgrade base Alpine Linux image from 3.23.2 to 3.23.3
- Upgrade Headscale from 0.27.1 to 0.28.0
- Expand validation instructions in AGENTS.md with build, runtime, and upgrade steps
- Switch policy from database mode to file-based with allow-all default

### Fixed

- Add healthcheck to server service in local development compose

### Internal

- Add AGENTS.md with build, test, and contribution guidelines

## v0.5.0 - 2026-01-19

### Changed

- Upgrade to Alpine Linux 3.23.2
- Upgrade Headscale to 0.27.1

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
