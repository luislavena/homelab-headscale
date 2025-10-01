# Homelab Headscale

Making it easy (for me) to deploy production-ready setup

This repository provides a streamlined approach to deploy [Headscale][headscale] with minimal configuration while ensuring data persistence and backup using [Litestream][litestream].

## What is this?

This is a Docker-based setup for running Headscale (an open source, self-hosted implementation of the Tailscale control server) with:

* Automated S3 backup and replication using Litestream
* Production-ready configuration templates
* Easy deployment to Fly.io

## Deployment guides

* [Deploying to Fly.io](docs/fly/README.md) - Complete guide for deploying to Fly.io with S3 backups

[headscale]: https://github.com/juanfont/headscale
[litestream]: https://litestream.io/

## Contribution policy

Inspired by [Litestream](https://github.com/benbjohnson/litestream) and
[SQLite](https://sqlite.org/copyright.html#notopencontrib), this project is
open to code contributions for bug fixes only. Features carry a long-term
burden so they will not be accepted at this time. Please
[submit an issue](https://github.com/luislavena/homelab-headscale/issues/new) if you have
a feature you would like to request or discuss.

## License

Licensed under the Apache License, Version 2.0. You may obtain a copy of
the license [here](./LICENSE).
