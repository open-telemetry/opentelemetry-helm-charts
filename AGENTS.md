# AGENTS Instructions for Codex

These instructions apply to all development via the Codex web UI.

- Limit modifications to the `charts/opentelemetry-collector` folder when updating the chart.
- After changing files in that folder:
  1. Bump the chart version in `Chart.yaml`.
  2. Update the `CHANGELOG` accordingly.
  3. Run `make generate-examples CHARTS=opentelemetry-collector` to regenerate example manifests.
  4. Commit the regenerated examples along with your other changes.

### Updating Changelog
- Add new entry to `charts/opentelemetry-collector/CHANGELOG.md`.
- Use current date in YYYY-MM-DD format (get with `date +%Y-%m-%d`).
- Copy the entries from the opentelemetry-collector changelog.
- Follow the existing format: `### vX.Y.Z / YYYY-MM-DD`.

Make sure to update the version only once to avoid duplicate changelog entries.

