# Domain Privacy Reverse Proxy Demo

A minimal example demonstrating how to configure reverse proxies (Traefik/Nginx) to protect domain privacy from IP-based scanning.

## Overview

This demo shows how to configure a reverse proxy that:
- Serves valid certificates for explicitly configured domains
- Serves self-signed certificates and redirects for all other requests (direct IP access, unknown domains)

## Why?

When someone scans your server's IP directly, they could discover what domains you're hosting. This configuration prevents that by only revealing valid certificates for expected domain names.

## Implementations

Two example configurations are provided:

- **[Traefik](./traefik/)** - Docker-native proxy with automatic certificate management
- **[Nginx](./nginx/)** - Traditional proxy with manual certificate configuration

## Quick Demo

```bash
# Valid domain request
$ curl https://app.yourdomain.com
# → Your application with valid certificate

# Direct IP scan
$ curl https://123.45.67.89
# → Self-signed cert + redirect to external site

# Unknown domain
$ curl https://random.com --resolve random.com:443:123.45.67.89
# → Self-signed cert + redirect to external site
```

## Setup

1. Choose either the Traefik or Nginx implementation
2. Follow the README in that directory
3. Configure your domains and redirect target
4. Deploy with Docker Compose

## Note

This is a minimal demonstration of the concept. For production use, consider additional security measures and proper configuration management.