# AGENTS Instructions for Codex

These instructions apply to all development via the Codex web UI.

- Limit modifications to the `charts/opentelemetry-collector` folder when updating the chart.
- After changing files in that folder:
  1. Bump the chart version in `Chart.yaml`.
  2. Update the `CHANGELOG` accordingly.
  3. Run `make generate-examples CHARTS=opentelemetry-collector` to regenerate example manifests.
  4. Commit the regenerated examples along with your other changes.

