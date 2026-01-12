# Liteverge Setup Guide for OpenTelemetry Helm Charts

This guide explains how to complete the setup of this forked repository for Liteverge.

## 1. Update Team Information

### Update CODEOWNERS

Edit `.github/CODEOWNERS` and replace:
```
* @liteverge/helm-maintainers
```

With either:
- Your GitHub team: `@liteverge/your-actual-team-name`
- Individual maintainers: `@username1 @username2 @username3`

### Update Artifact Hub Configuration

Edit `artifacthub-repo.yml`:
1. Register your repository at https://artifacthub.io/
2. Replace `UPDATE_WITH_LITEVERGE_REPOSITORY_ID` with your repository ID
3. Replace `UPDATE_WITH_LITEVERGE_EMAIL` with your team's contact email

## 2. Enable GitHub Pages

### Step 1: Configure Repository Settings

1. Go to **Settings** → **Pages** in your GitHub repository
2. Under "Build and deployment":
   - Source: **Deploy from a branch**
   - Branch: **gh-pages** / (root)
3. Click **Save**

### Step 2: Set Workflow Permissions

1. Go to **Settings** → **Actions** → **General**
2. Under "Workflow permissions":
   - Select **Read and write permissions**
   - Check **Allow GitHub Actions to create and approve pull requests**
3. Click **Save**

### Step 3: Enable GitHub Packages (Optional)

The release workflow also pushes charts to GitHub Container Registry (ghcr.io). This should work automatically, but if you encounter issues:

1. Go to **Settings** → **Actions** → **General**
2. Ensure "Workflow permissions" includes **packages: write**

## 3. Verify Workflows

### Check Workflow Files

All workflow files have been updated to use Liteverge repositories:

- ✅ `.github/workflows/release.yaml` - Publishes charts on push to main
- ✅ `.github/workflows/lint.yaml` - Lints PRs before merge
- ✅ `.github/workflows/demo-test.yaml` - Tests demo chart
- ✅ `.github/workflows/operator-test.yaml` - Tests operator chart
- ✅ `.github/workflows/sync-readme.yaml` - Syncs README to gh-pages

### Test the Release Workflow

To trigger the release workflow:

```bash
# Make a small change and push to main
git add .
git commit -m "chore: trigger initial release"
git push origin main
```

The workflow will:
1. Package all charts
2. Create GitHub releases for new chart versions
3. Update the Helm repository index on gh-pages branch
4. Push charts to ghcr.io/liteverge/opentelemetry-helm-charts

## 4. Update Chart Dependencies

After GitHub Pages is published and working:

```bash
# Update dependencies to use your published charts
helm dependency update charts/opentelemetry-demo
helm dependency update charts/opentelemetry-kube-stack

# Commit the updated Chart.lock files
git add charts/*/Chart.lock
git commit -m "chore: update chart dependencies"
git push origin main
```

## 5. Verify Installation

After release workflow completes successfully:

```bash
# Add your Helm repository
helm repo add liteverge-opentelemetry https://liteverge.github.io/opentelemetry-helm-charts
helm repo update

# Search for charts
helm search repo liteverge-opentelemetry

# Test installation (in a test cluster)
helm install test-collector liteverge-opentelemetry/opentelemetry-collector \
  --set mode=deployment \
  --set image.repository="ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-k8s"
```

## 6. Using Charts from GitHub Container Registry (OCI)

Charts are also available as OCI artifacts:

```bash
# Install directly from GHCR
helm install my-collector oci://ghcr.io/liteverge/opentelemetry-helm-charts/opentelemetry-collector \
  --version 0.143.0 \
  --set mode=deployment \
  --set image.repository="ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-k8s"
```

## 7. Troubleshooting

### Workflow Fails with Permission Errors

- Ensure workflow permissions are set to "Read and write"
- Check that GITHUB_TOKEN has necessary scopes

### Charts Not Appearing in Helm Repo

- Verify gh-pages branch exists and contains index.yaml
- Check GitHub Pages is enabled and deployed
- Wait a few minutes for GitHub Pages to update

### Dependencies Fail to Resolve

- Ensure your charts are published before updating dependencies
- Check that Chart.yaml points to the correct repository URL
- Run `helm repo update` before building dependencies

### CODEOWNERS Validation Fails

- Ensure the team or users exist in your organization
- Use valid GitHub usernames with @ prefix
- Make the CODEOWNERS file public (not in a private path)

## 8. Next Steps

1. **Documentation**: Update any internal documentation with new Helm repository URLs
2. **CI/CD**: Update your deployment pipelines to use the new repository
3. **Team Training**: Inform team members about the new repository location
4. **Monitoring**: Set up alerts for workflow failures
5. **Dependencies**: Consider setting up Dependabot for chart dependencies

## 9. Maintenance

### Syncing with Upstream

Periodically sync with the upstream repository:

```bash
# Add upstream if not already added
git remote add upstream https://github.com/open-telemetry/opentelemetry-helm-charts.git

# Fetch and merge updates
git fetch upstream
git checkout main
git merge upstream/main

# Review changes and update any new references
# Then push to trigger release
git push origin main
```

### Updating Chart Versions

When making changes to charts:

1. Update the `version` field in the chart's `Chart.yaml`
2. Follow [semantic versioning](https://semver.org/)
3. Update `UPGRADING.md` if there are breaking changes
4. Commit and push to main to trigger release

## Support

For issues related to:
- **This fork setup**: Check `FORK_CHANGES.md` or create an issue in this repository
- **Upstream charts**: Refer to https://github.com/open-telemetry/opentelemetry-helm-charts
- **OpenTelemetry**: Visit https://opentelemetry.io/docs/
