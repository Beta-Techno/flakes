# Observability Dashboards

This directory contains Grafana dashboard definitions as plain JSON files.

## Approach

- **Plain JSON files**: Dashboards are stored as human-readable JSON files under version control
- **Nix store integration**: Files are copied to the Nix store and referenced directly by Grafana
- **Immutable provisioning**: Dashboards are managed declaratively and restart Grafana when changed
- **Stable UIDs**: Dashboards reference datasources by stable UIDs (PROM, LOKI, BQ) for reliability

## Dashboard Files

- `host-overview.json` - System metrics (CPU, memory, disk, network)
- `nginx-overview.json` - Nginx web server metrics
- `logs-quick.json` - Log search and analysis

## Usage

Dashboards are automatically provisioned by Grafana when the observability-01 system starts. Changes to these files will trigger a Grafana restart to pick up the new dashboards.

## Adding New Dashboards

1. Create a new JSON file in this directory
2. Use stable datasource UIDs: `PROM`, `LOKI`, `BQ`
3. Follow Grafana dashboard JSON schema
4. The system will automatically pick up the new dashboard on next deployment
