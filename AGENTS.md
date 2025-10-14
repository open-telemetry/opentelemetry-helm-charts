# AGENTS instructions for Codex contributors

These rules apply to the entire repository when working through the Codex web UI.

## Scope of changes

* Keep chart-related modifications confined to the `charts/opentelemetry-collector` directory.
* If you update the collector image, bump the chart's **minor** version (for example, `0.119.x` → `0.120.0`).

## Release hygiene (exactly once per PR/branch)

Whenever you make a change that will ship with the chart, you **must** perform the following release steps before the PR is finalized. Do them exactly once per PR/branch—do **not** bump the version multiple times within the same change set.

1. Bump the chart version in `charts/opentelemetry-collector/Chart.yaml`.
2. Add a consolidated entry for that version to `charts/opentelemetry-collector/CHANGELOG.md` using the format described below.
3. Regenerate any derived values and examples so the repository reflects the new defaults:
   * Update `charts/opentelemetry-collector/values.yaml` and `charts/opentelemetry-collector/values.schema.json` as needed.
   * Run `make generate-examples CHARTS=opentelemetry-collector` and include the refreshed manifests.
4. Commit the code changes together with the version bump, changelog entry, updated values, and regenerated examples.

## Updating the changelog

* Add the new entry to `charts/opentelemetry-collector/CHANGELOG.md`.
* Use the current date in `YYYY-MM-DD` format (retrieve it with `date +%Y-%m-%d`).
* Mirror the structure of the upstream opentelemetry-collector changelog.
* Follow the heading format `### vX.Y.Z / YYYY-MM-DD`.

### Additional guidelines

* Write a single consolidated changelog entry covering all changes included in the version.
* Only bump the chart version once per PR/branch to avoid duplicate changelog entries.
