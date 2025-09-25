# Contributing Guide

🎉 Welcome to the OpenTelemetry Helm Charts Repository! 🎉

## Introduction

This repository hosts Helm charts for deploying OpenTelemetry components in Kubernetes. Your contributions help improve observability for everyone! Whether you’re fixing a configuration, adding a new feature, or improving documentation, we appreciate your effort!

We'd love your help!

## Pre-requisites

To work with this repository, ensure you have:

- Helm 3.8+

- chart-testing (ct) 3.7+

- Kubernetes CLI (kubectl)

- make (for automation)

- [pre-commit](https://pre-commit.com/) (for commit validation)

### Platform Notes

Docker or Kubernetes cluster access (for testing chart installations)

## Workflow

1. Fork this repository
1. Develop, and test your changes
1. Submit a pull request

Remember to always work in a branch of your local copy, as you might otherwise
have to contend with conflicts in master.

Please also see [GitHub
workflow](https://github.com/open-telemetry/community/blob/main/CONTRIBUTING.md#github-workflow)
section of general project contributing guide.

Local Run/Build

TBD

Testing

TBD

## Technical Requirements

* Must follow [Charts best practices](https://helm.sh/docs/topics/chart_best_practices/)
* Must pass CI jobs for linting and installing changed charts with the
  [chart-testing](https://github.com/helm/chart-testing) tool
* Any change to a chart requires a version bump following
  [semver](https://semver.org/) principles. See [Immutability](#immutability)
  and [Versioning](#versioning) below

Once changes have been merged, the release job will automatically run to package
and release changed charts.

## Immutability

Chart releases must be immutable. Any change to a chart warrants a chart version
bump even if it is only changed to the documentation.

## Versioning

The chart `version` should follow [semver](https://semver.org/).

All changes to a chart require a version bump, following semvar.

Any breaking (backwards incompatible) changes to a chart should:
1. Bump the MINOR version
2. In the README, under a section called "Upgrading", describe the manual steps
   necessary to upgrade to the new (specified) MAJOR version

## Examples

All charts maintain examples for the current version. After updating the version, examples must be updated with the `make generate-examples` target.

The default `generate-examples` command will update all charts.  In order generate a chart's examples you must have the chart's dependencies added to your helm repo.

If you need update a single chart's examples you can use the `CHARTS` variable.  For example, if you want to update only the collector chart's examples you can run `make generate-examples CHARTS=opentelemetry-collector`

New examples should be added as independent folders in the respective chart's `examples` folder.  Examples should always contain a `values.yaml` and a `rendered` folder.

### SemVer label and generated examples

- For trivial changes that do not affect templating, you do not need to commit rendered outputs. If your change affects chart functionality or templating logic, please run `make generate-examples` so reviewers can see the impact clearly. The final rendering is handled by the merge train and may include changes from other PRs.
- When your PR enters the Mergify train, CI will bump chart versions first (based on your label) and then regenerate all examples and commit those changes on the train branch. The final merge to `main` will therefore include version bumps and regenerated examples.

We post a comment on each PR included in a train run linking to the train commit where latest render
Helm chart template examples were generated. This keeps PRs informed about the final rendered outputs.

### Roles and responsibilities

- Contributors: open PRs and respond to reviews. Contributors cannot apply labels. The repository automatically applies exactly one `chart:*` label when your PR touches files under a single chart.
- Approvers: can approve PRs and Mergify trains; can apply labels (`chart:*`, `semvertype:*`).
- Maintainers: can do everything Approvers can, and can merge trains.
- The person applying labels is responsible for ensuring train items do not conflict (e.g., two PRs that imply incompatible changes). If conflicts arise, adjust labels/queues or re-queue as needed.

### Labeling charts

Label your PR with exactly one chart label:

- `chart:opentelemetry-collector`
- `chart:opentelemetry-operator`
- `chart:opentelemetry-demo`
- `chart:opentelemetry-ebpf`
- `chart:opentelemetry-kube-stack`
- `chart:opentelemetry-target-allocator`

And one semver label: `semvertype:patch` | `semvertype:minor` | `semvertype:major`.

### Merge train strategy (text diagram)

```
PRs ──► label with chart:* and semvertype:* ──► Mergify queue (per chart×semver)
                                        └──► Train branch (mergify/<queue>/pr-...)
                                                            │
                                                            ▼
                     CI (train): bump Chart.yaml first, then make generate-examples
                                                            │
                                                            ▼
                                       Commit bot "ci: bump ... and regenerate examples"
                                                            │
                                                            ▼
                                         Required checks pass ► Merged to main
```

### Releases and release notes

Releases may include multiple commits because the train appends a final "bump and generate examples" commit before merging. The release workflow publishes any chart that had changes and whose `Chart.yaml` version changed. Release notes are auto-generated and may reference multiple PRs included in the train cycle.

## Further Help

- Join [#helm-charts](https://cloud-native.slack.com/archives/C03HVLM8LAH) on OpenTelemetry Slack.

### Chart-specific Contributing Guides

- [opentelemetry-collector](./charts/opentelemetry-collector/CONTRIBUTING.md)
- [opentelemetry-operator](./charts/opentelemetry-operator/CONTRIBUTING.md)
