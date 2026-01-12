# Fork Changes Summary

This document summarizes the changes made to adapt this fork for the Liteverge organization.

## Repository Information

- **Upstream Repository**: https://github.com/open-telemetry/opentelemetry-helm-charts
- **Fork Repository**: https://github.com/liteverge/opentelemetry-helm-charts
- **Helm Repository URL**: https://liteverge.github.io/opentelemetry-helm-charts

## Changes Made

### 1. Main Repository Files

- **README.md**: Updated all repository links and Helm repository URLs to point to `liteverge/opentelemetry-helm-charts` and `https://liteverge.github.io/opentelemetry-helm-charts`
- **artifacthub-repo.yml**: Updated repository ID and owners (marked with placeholders for your actual values)
- **CONTRIBUTING.md**: Updated references to upstream repository

### 2. Chart Files Updated

All charts have been updated with the following changes:

#### Charts Updated:
- opentelemetry-collector
- opentelemetry-operator
- opentelemetry-demo
- opentelemetry-ebpf
- opentelemetry-ebpf-instrumentation
- opentelemetry-kube-stack
- opentelemetry-target-allocator

#### Files Updated per Chart:
- **README.md**: Updated Helm repository add commands to use `liteverge-opentelemetry` repository
- **CONTRIBUTING.md**: Updated links to Contributing Guide
- **UPGRADING.md**: Updated links to this repository, marked historical upstream links with "(upstream)"
- **templates/NOTES.txt**: Updated error message links
- **values.yaml**: Updated documentation links

### 3. Chart Dependencies

Updated Helm chart dependencies in:
- **opentelemetry-demo/Chart.yaml**: opentelemetry-collector dependency now points to Liteverge repository
- **opentelemetry-demo/Chart.lock**: Updated repository URL
- **opentelemetry-kube-stack/Chart.yaml**: opentelemetry-operator dependency now points to Liteverge repository
- **opentelemetry-kube-stack/Chart.lock**: Updated repository URL

### 4. Subchart READMEs

Updated references in:
- charts/opentelemetry-kube-stack/charts/prometheus-crds/README.md
- charts/opentelemetry-kube-stack/charts/otel-crds/README.md

### 5. GitHub Workflows and Actions

Updated CI/CD workflows:
- **.github/workflows/release.yaml**: Updated Helm repository reference for chart dependencies
- **.github/workflows/lint.yaml**: Updated chart repository URL for linting
- **.github/workflows/demo-test.yaml**: Updated chart repository URL for testing
- **.github/workflows/operator-test.yaml**: Marked upstream issue references
- **.github/CODEOWNERS**: Updated to reflect Liteverge team structure (placeholders for team members)

## Setup Instructions

### 1. Update Team Configuration

Edit these files with your actual team information:

**artifacthub-repo.yml**:
- `UPDATE_WITH_LITEVERGE_REPOSITORY_ID` → Your actual Artifact Hub repository ID
- `UPDATE_WITH_LITEVERGE_EMAIL` → Your team's contact email

**.github/CODEOWNERS**:
- Replace `@liteverge/helm-maintainers` with your actual GitHub team or individual maintainers
- Update chart-specific owners as needed

### 2. Setup GitHub Pages

The repository includes a `release.yaml` workflow that automatically publishes Helm charts to GitHub Pages. To enable it:

1. **Enable GitHub Pages**:
   - Go to repository Settings → Pages
   - Set Source to "Deploy from a branch"
   - Select the `gh-pages` branch

2. **Ensure Workflow Permissions**:
   - Go to Settings → Actions → General
   - Under "Workflow permissions", select "Read and write permissions"
   - Enable "Allow GitHub Actions to create and approve pull requests"

3. **Trigger a Release**:
   - The workflow runs automatically on push to `main` branch
   - Charts are packaged and published to `https://liteverge.github.io/opentelemetry-helm-charts`
   - Charts are also pushed to GitHub Container Registry at `ghcr.io/liteverge/opentelemetry-helm-charts`

### 3. Update Chart Dependencies

After setting up GitHub Pages, you may need to rebuild chart dependencies:

```bash
helm dependency update charts/opentelemetry-demo
helm dependency update charts/opentelemetry-kube-stack
```

## Usage

Add the Liteverge Helm repository:

```bash
helm repo add liteverge-opentelemetry https://liteverge.github.io/opentelemetry-helm-charts
helm repo update
```

Install a chart:

```bash
helm install my-collector liteverge-opentelemetry/opentelemetry-collector
```

## Maintaining the Fork

### Syncing with Upstream

To sync with upstream changes:

```bash
# Add upstream remote if not already added
git remote add upstream https://github.com/open-telemetry/opentelemetry-helm-charts.git

# Fetch upstream changes
git fetch upstream

# Merge or rebase upstream changes
git merge upstream/main
# or
git rebase upstream/main

# Review and update any new references to the upstream repository
# Then push your changes
git push origin main
```

### Before Merging Upstream Changes

When merging upstream changes, you may need to update:
1. Any new README files with repository URLs
2. New chart dependencies in Chart.yaml and Chart.lock files
3. New documentation links
4. Chart.yaml files if new charts are added
5. New workflow files that reference repositories
6. CODEOWNERS if new charts are added

## Notes

- Historical links to upstream issues and PRs in UPGRADING.md files have been preserved and marked with "(upstream)"
- The upstream repository is still referenced in sources and for historical context
- This fork maintains compatibility with the upstream charts while being published under the Liteverge organization
