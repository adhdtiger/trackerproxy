# trackerproxy Stack

This directory manages the trackerproxy service for torrent tracker proxying.

## Purpose
Provides a proxy for tracker connections to enhance privacy and control.

## Files
- `compose.yaml` - Docker Compose service definition for trackerproxy
- `trackerproxy.env` - Environment variables for trackerproxy (inherits from `global.env`)
- `README.md` - This documentation file

## Usage
1. Copy and update `trackerproxy.env` as needed.
2. Deploy with Docker Compose.

## Environment Variables
- Inherit from `global.env` for base variables.
- Service-specific variables are defined in `trackerproxy.env`.

## Standard Structure
- Health checks for monitoring
- Traefik labels for reverse proxy
- Named volumes for persistence
- Environment variable inheritance
- Consistent naming conventions

## Validation & Security
- Run `./scripts/environment-validator.sh` to validate environment variables and configuration
- Use `./scripts/security-manager.sh audit` to check for exposed secrets and security issues
- Execute `./scripts/service-health-manager.sh check` to verify service health and connectivity
- Run `./scripts/compose-validation.sh` to validate Docker Compose configuration

For comprehensive validation, use the main validation script: `./scripts/validate-all.sh`
