# Prerequisites

- [ ] Make sure you have installed Helm v3 or later versions. See [Helm website](https://helm.sh/docs/helm/helm_install/)
  for installation information.

# Checklist

- [ ] Change directory to `opentelemetry-helm-charts/charts/opentelemetry-operator/release`. `cd ./charts/opentelemetry-operator/release` should be helpful.
- [ ] Run the command `go run main.go` to update the OTEL Collector CRD, `values.yaml` and `Chart.yaml`and detect if any template file needs to be updated
- [ ] If you see any template files need to be updated, update them to maintain consistency with the ones in the manifest (especially be careful with `role.yaml` and `clusterrole.yaml`).  \
  Create a new YAML file under `templates` directory if it doesn't exist.
  Use `{{ template "opentelemetry-operator.name" . }}` to represent the name of OTEL Operator which probably is `opentelemetry-operator` in the manifest.
  Use `{{ template "opentelemetry-operator.namespace" . }}` to represent the namespace which probably is `opentelemetry-operator-system` in the manifest.
- [ ] Test the Operator Helm chart locally:
  - [ ] Change directory to the OpenTelemetry Operator
  - [ ] Run the KUTTL smoke tests: `kubectl kuttl test ./tests/e2e`
  - [ ] Make sure all KUTTL smoke tests pass
- [ ] Update `README` if there is a breaking change in the Operator Helm chart

# Additional Context

- `values.yaml` stores the default values passed into the chart.
- `Chart.yaml` contains all the basic information of the Helm chart.
- `role.yaml` and `clusterrole.yaml` define what types of actions will be permitted.
