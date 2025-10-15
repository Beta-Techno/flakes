# Observability-01 Setup Documentation

## Overview
This document tracks the complete setup process for `observability-01`, a dedicated observability VM using NixOS flakes with Prometheus, Grafana, Loki, and BigQuery integration.

## Sprint 1: Core Observability Stack

### ✅ Completed Tasks

#### 1. Inventory and Host Configuration
- **File**: `inventories/prod.nix`
- **Added**: `observability-01` host entry with `infra` role
- **System**: `x86_64-linux`
- **Networking**: DHCP (no fixed IP initially)

#### 2. Host Module Creation
- **File**: `nixos/hosts/servers/observability-01.nix`
- **Features**:
  - UEFI boot configuration
  - DHCP networking
  - Firewall rules (ports 22, 80, 443, 9090, 3000, 3100)
  - Admin user `nbg` with wheel/docker groups
  - Nginx virtual host for `observability.local`
  - `/nginx_status` endpoint for Prometheus exporter

#### 3. Infrastructure Role Updates
- **File**: `nixos/roles/infra.nix`
- **Changes**:
  - Added SOPS import
  - Added default `/nginx_status` location for nginx exporter
  - Ensured exporter readiness

#### 4. Prometheus Profile Fixes
- **File**: `nixos/profiles/prom.nix`
- **Issues Fixed**:
  - ❌ **Node exporter collector name**: Changed `"disk"` → `"diskstats"`
  - ❌ **Nginx exporter option**: Changed `nginxScrapeUri` → `scrapeUri`
  - ❌ **PostgreSQL exporter**: Gated with `lib.mkIf config.services.postgresql.enable`
  - ✅ **Added Loki scrape job**: `localhost:3100/metrics`
  - ❌ **Commented out missing rule file**: `prometheus-alerts.yml`

#### 5. SOPS Integration
- **File**: `nixos/profiles/sops.nix`
- **Added**:
  - Grafana admin password secret
  - Grafana secret key secret
  - BigQuery service account secret

#### 6. Encrypt Script Improvements
- **File**: `encrypt-secrets.sh`
- **Changes**:
  - Updated to read from `nixos/keys/age/*.txt` files instead of `.sops.yaml`
  - Added fallback to `.sops.yaml` if no `.txt` files exist
  - Shows which server keys are being used

#### 7. Age Key Management
- **Added**: `nixos/keys/age/observability-01.txt` with public key
- **Updated**: `.sops.yaml` to include observability-01 public key
- **Workflow**: Generate key on server → Add public key to repo → Encrypt secrets

#### 8. Grafana Configuration
- **File**: `nixos/profiles/grafana.nix`
- **Features**:
  - External access binding (`http_addr = "0.0.0.0"`)
  - BigQuery plugin auto-installation via `GF_INSTALL_PLUGINS`
  - Unsigned plugin allowance
  - Pre-configured data sources (Prometheus, Loki, BigQuery)
  - SOPS secret integration

#### 9. Loki Configuration Fixes
- **File**: `nixos/profiles/loki.nix`
- **Issues Fixed**:
  - Removed deprecated `max_transfer_retries`
  - Removed deprecated `enforce_metric_name`
  - Updated schema config to use `tsdb` and `v13`
  - Updated storage config to use `tsdb_shipper`
  - Removed deprecated `max_look_back_period`
  - Added `delete_request_store = "filesystem"`

### 🔧 Current Issues and Attempts

#### BigQuery Authentication Problem
**Status**: ❌ Still failing with "datasource is missing authentication details"

**Attempts Made**:

1. **Initial Configuration**:
   ```nix
   secureJsonData = {
     privateKey = "$__file{${config.sops.secrets."gcp-bq-sa.json".path}}";
   };
   ```
   - **Result**: ❌ Failed - wrong field name

2. **Changed to JWT field**:
   ```nix
   secureJsonData = {
     jwt = "$__file{${config.sops.secrets."gcp-bq-sa.json".path}}";
   };
   ```
   - **Result**: ❌ Still failing with "missing authentication details"

3. **Current attempt - Token field**:
   ```nix
   secureJsonData = {
     token = "$__file{${config.sops.secrets."gcp-bq-sa.json".path}}";
   };
   ```
   - **Status**: 🔄 Testing in progress

**Verification Steps Completed**:
- ✅ SOPS secret file exists: `/run/secrets/gcp-bq-sa.json`
- ✅ File permissions correct: `400` (readable by grafana user)
- ✅ File contains valid JSON with service account details
- ✅ BigQuery plugin installed and running (version 3.0.2)
- ✅ Grafana can read the file: `sudo -u grafana cat /run/secrets/gcp-bq-sa.json`

**Service Account Details**:
- **Project**: `bigquery-475119`
- **Service Account**: `bigquery-drive-audit@bigquery-475119.iam.gserviceaccount.com`
- **Purpose**: Drive audit data collection

## Current Status

### ✅ Working Components
- **Prometheus**: Running on port 9090, scraping all targets
- **Loki**: Running on port 3100, serving metrics
- **Grafana**: Running on port 3000, accessible externally
- **Node Exporter**: Running on port 9100
- **Nginx Exporter**: Running on port 9113
- **Promtail**: Running and shipping logs to Loki
- **SOPS**: Working, secrets decrypted properly

### ❌ Not Working
- **BigQuery Data Source**: Authentication failing despite correct configuration

## Next Steps

### Immediate
1. Test the `token` field approach for BigQuery authentication
2. If that fails, try alternative authentication methods:
   - Base64 encoding the JSON
   - Using individual fields instead of full JSON
   - Checking plugin version compatibility

### Future (Sprint 2)
- Google Drive audit collector implementation
- Systemd timer for periodic data collection
- Promtail configuration for audit log ingestion

## Commands Reference

### Deployment
```bash
cd /etc/nixos/flakes
sudo nixos-rebuild switch --flake .#observability-01
```

### Service Management
```bash
sudo systemctl restart grafana
sudo systemctl status grafana
```

### Logs
```bash
sudo journalctl -u grafana -f
sudo journalctl -u grafana -n 50 | grep -i bigquery
```

### Testing
```bash
# Test services
curl http://localhost:3000  # Grafana
curl http://localhost:9090  # Prometheus
curl http://localhost:3100/metrics  # Loki metrics

# Test BigQuery data source
# Go to Grafana UI → Configuration → Data Sources → BigQuery → Test
```

## File Structure
```
inventories/prod.nix                    # Host inventory
nixos/hosts/servers/observability-01.nix # Host-specific config
nixos/roles/infra.nix                   # Infrastructure role
nixos/profiles/
├── prom.nix                           # Prometheus configuration
├── loki.nix                           # Loki configuration
├── grafana.nix                        # Grafana configuration
└── sops.nix                           # SOPS secrets management
secrets/
├── prod.yaml                          # Encrypted secrets
└── prod.yaml.plaintext                # Plaintext secrets (git ignored)
nixos/keys/age/observability-01.txt    # Age public key
encrypt-secrets.sh                     # Secret encryption script
```

## Lessons Learned

1. **Node Exporter**: Use `diskstats` not `disk` for collector name
2. **Nginx Exporter**: Use `scrapeUri` not `nginxScrapeUri`
3. **Grafana Plugins**: Use `GF_INSTALL_PLUGINS` environment variable
4. **SOPS Workflow**: Generate keys on server, add public keys to repo
5. **BigQuery Plugin**: Field names matter (`jwt` vs `token` vs `privateKey`)

## Troubleshooting Notes

- Grafana logs show BigQuery plugin version 3.0.2
- Plugin expects authentication details in specific field format
- SOPS secrets are properly decrypted and accessible
- All other observability components working correctly
- Ready for Sprint 2 implementation once BigQuery is resolved
