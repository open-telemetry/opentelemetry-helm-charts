package main

import (
	"errors"
	"gopkg.in/yaml.v3"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
)

const (
	operatorManifestURL   = "https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml"
	collectorCRDPath      = "../crds/crd-opentelemetrycollector.yaml"
	valuesYAMLPath        = "../values.yaml"
	chartYAMLPath         = "../Chart.yaml"
	operatorRepoPath      = "repository: quay.io/opentelemetry/opentelemetry-operator"
	kubeRBACProxyRepoPath = "repository: gcr.io/kubebuilder/kube-rbac-proxy"
	appVersion            = "appVersion"
)

// K8sObject describes the values a Kubernetes object typically has.
type K8sObject struct {
	ApiVersion string                      `yaml:"apiVersion"`
	Kind       string                      `yaml:"kind"`
	Metadata   map[interface{}]interface{} `yaml:"metadata"`
	Spec       map[interface{}]interface{} `yaml:"spec"`
	Status     map[interface{}]interface{} `yaml:"status"`
}

// The main keeps the OpenTelemetry Operator (OTEL Operator) Helm chart configurations up-to-date with the upstream automatically.
// First, it scrapes the latest OTEL Operator manifest from the OTEL Operator github:
// https://github.com/open-telemetry/opentelemetry-operator.
// Then, it will update the OpenTelemetry Collector CRD YAML file, which is the only CRD at this point.
// At last, it will retrieve the latest image tag from the OTEL Operator manifest and update the values.yaml and Chart.yaml.
func main() {
	// Get the OTEL Operator manifest data.
	resp, err := http.Get(operatorManifestURL)
	if err != nil {
		panic(err)
	}

	// Parse the manifest.
	dc := yaml.NewDecoder(resp.Body)

	for {
		var curObject K8sObject
		err := dc.Decode(&curObject)
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			panic(err)
		}

		switch curObject.Kind {
		case "CustomResourceDefinition":
			// Update the OTEL Collector CRD YAML file.
			out, err := yaml.Marshal(curObject)
			if err != nil {
				panic(err)
			}
			err = os.WriteFile(collectorCRDPath, out, 0644)
			if err != nil {
				panic(err)
			}
			log.Println("The OpenTelemetry Collector CRD update finished. It's up-to-date now.")

		case "Deployment":
			// Retrieve the latest image repository and tag of the two container images.
			managerImage := strings.Split(curObject.Spec["template"].(map[string]interface{})["spec"].(map[string]interface{})["containers"].([]interface{})[0].(map[string]interface{})["image"].(string), ":")
			kubeRBACProxyImage := strings.Split(curObject.Spec["template"].(map[string]interface{})["spec"].(map[string]interface{})["containers"].([]interface{})[1].(map[string]interface{})["image"].(string), ":")

			// Replace the image tags in values.yaml and appVersion in Chart.yaml with the latest ones.
			valuesFile, err := os.ReadFile(valuesYAMLPath)
			if err != nil {
				panic(err)
			}

			valuesFileLines := strings.Split(string(valuesFile), "\n")
			for i, line := range valuesFileLines {
				if strings.Contains(line, operatorRepoPath) {
					valuesFileLines[i+1] = "    tag: " + managerImage[1]
				} else if strings.Contains(line, kubeRBACProxyRepoPath) {
					valuesFileLines[i+1] = "    tag: " + kubeRBACProxyImage[1]
				}
			}

			valuesFileOutput := strings.Join(valuesFileLines, "\n")
			err = os.WriteFile(valuesYAMLPath, []byte(valuesFileOutput), 0644)
			if err != nil {
				panic(err)
			}

			chartFile, err := os.ReadFile(chartYAMLPath)
			if err != nil {
				panic(err)
			}

			chartFileLines := strings.Split(string(chartFile), "\n")
			for i, line := range chartFileLines {
				if strings.Contains(line, appVersion) {
					chartFileLines[i] = appVersion + ": " + managerImage[1][1:]
				}
			}

			chartFileOutput := strings.Join(chartFileLines, "\n")
			err = os.WriteFile(chartYAMLPath, []byte(chartFileOutput), 0644)
			if err != nil {
				panic(err)
			}

			log.Println("The values.yaml and Chart.yaml update finished. They are up-to-date now.")

		default:
			continue
		}
	}
}
