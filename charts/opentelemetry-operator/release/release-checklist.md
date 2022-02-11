# Prerequisites

- [ ] Make sure you have installed Helm v3 or later versions. See [Helm website](https://helm.sh/docs/helm/helm_install/)
  for installation information.

# Checklist

- [ ] Change directory to `opentelemetry-helm-charts/charts/opentelemetry-operator/release`. `cd ./charts/opentelemetry-operator/release` should be helpful.
- [ ] Run the command `go run .` to update the OTEL Collector CRD, `values.yaml` and `Chart.yaml`and detect if any template file needs to be updated
- [ ] If you see any template files need to be updated, update them to maintain consistency with the ones in the manifest (especially be careful with `role.yaml` and `clusterrole.yaml`).  \
  Create a new YAML file under `templates` directory if it doesn't exist.
  Use `{{ template "opentelemetry-operator.name" . }}` to represent the name of OTEL Operator which probably is `opentelemetry-operator` in the manifest.
  Use `{{ .Release.Namespace }}` to represent the namespace.
- [ ] Update `README` if there is a breaking change in the Operator Helm chart
- [ ] Bump chart version in `Chart.yaml`

# Additional Context

- `values.yaml` stores the default values passed into the chart.
- `Chart.yaml` contains all the basic information of the Helm chart.
- `role.yaml` and `clusterrole.yaml` define what types of actions will be permitted.
- `main.go` contains the release process code, `release.go` contains all the release functions
