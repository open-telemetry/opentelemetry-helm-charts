# Prerequisite

- [ ] Make sure you have installed Kuttl which will be used to do the smoke tests later. See [Kuttl website](https://kuttl.dev/docs/)
  for installation information.
- [ ] Make sure you have cloned the [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) in your workspace

# Checklist

- [ ] Change directory to `opentelemetry-helm-charts/charts/opentelemetry-operator`. `cd ./charts/opentelemetry-operator` should be helpful.
- [ ] Run the command `go run main.go` to update the OTEL Collector CRD and get the latest tags of the two images which
  the Operator will be using. Then update the corresponding values in the `values.yaml` (e.g., change the `manager.image.tag` value to `"v0.29.0"` or latest version).
- [ ] Update `appVersion` value in the `Chart.yaml` if a new version of `manager.image.tag` is released
- [ ] Download the latest OTEL Operator manifest from this [link](https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml).
  As you can see, there are several YAML files in this manifest separated by `---`.
- [ ] Starting from the third YAML file, compare the YAML files in the manifest and the ones in the `charts/opentelemetry-operator/templates` directory.
  The names of YAML files under `templates` directory are the same as the value of key `kind` of the YAML files in the manifest.
- [ ] Update our template YAML files to maintain consistency with the ones in the manifest (especially be careful with `role.yaml` and `clusterrole.yaml`).
  Create a new YAML file under `templates` directory if it doesn't exist.
  Use `{{ template "opentelemetry-operator.name" . }}` to represent the name of OTEL Operator which probably is `opentelemetry-operator` in the manifest.
  Use `{{ template "opentelemetry-operator.namespace" . }}` to represent the namespace which probably is `opentelemetry-operator-system` in the manifest.
- [ ] Test the Operator Helm chart locally:
  - [ ] Install cert-manager in your Kubernetes cluster: `kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml`
  - [ ] Install the Helm chart: `helm install my-op . -n opentelemetry-operator-system --create-namespace`
  - [ ] Run the Helm tests: `helm test my-op -n opentelemetry-operator-system --debug`
  - [ ] Change directory to the OpenTelemetry Operator
  - [ ] Run the Kuttl smoke tests: `kubectl kuttl test ./tests/e2e`
  - [ ] Make sure all the Helm tests and Kuttl smoke tests pass
- [ ] Update `README` if there is a breaking change in the Operator Helm chart

# Additional Context

- `values.yaml` stores the default values passed into the chart.
- `Chart.yaml` contains all the basic information of the Helm chart.
- `role.yaml` and `clusterrole.yaml` define what types of actions will be permitted.
