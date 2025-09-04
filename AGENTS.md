# AGENTS Instructions for Codex

These instructions apply to all development via the Codex web UI.

- Limit modifications to the `charts/opentelemetry-collector` folder when updating the chart.
- Release hygiene (do this once per change set, not per commit):
  1. When you are ready to finalize a change set (typically at PR end), bump the chart version in `Chart.yaml` exactly once.
  2. Update the `CHANGELOG` with a single consolidated entry for that version (do not add one entry per commit).
  3. Run `make generate-examples CHARTS=opentelemetry-collector` to regenerate example manifests.
  4. Commit the regenerated examples together with your code changes and the version/changelog updates in the same final commit (or squash prior commits on merge).

### Updating Changelog
- Add new entry to `charts/opentelemetry-collector/CHANGELOG.md`.
- Use current date in YYYY-MM-DD format (get with `date +%Y-%m-%d`).
- Copy the entries from the opentelemetry-collector changelog.
- Follow the existing format: `### vX.Y.Z / YYYY-MM-DD`.

Guidelines:
- Write a single, consolidated entry summarizing all relevant changes for the version (avoid one entry per commit).
- Perform the version bump and changelog update once per PR/release, at the end when changes are finalized.
- Make sure to update the version only once to avoid duplicate changelog entries.
