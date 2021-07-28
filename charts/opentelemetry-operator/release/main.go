package main

import (
	"errors"
	"io"
	"log"
	"net/http"

	"gopkg.in/yaml.v3"
)

const (
	operatorManifestURL   = "https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml"
	collectorCRDPath      = "../crds/crd-opentelemetrycollector.yaml"
	valuesYAMLPath        = "../values.yaml"
	chartYAMLPath         = "../Chart.yaml"
	operatorRepoPath      = "repository: quay.io/opentelemetry/opentelemetry-operator"
	kubeRBACProxyRepoPath = "repository: gcr.io/kubebuilder/kube-rbac-proxy"
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
	// Get all the templates of the OTEL Operator Helm chart.
	templates, err := getTemplates()
	if err != nil {
		panic(err)
	}

	// needUpdate records if there is any template file needs to be updated.
	needUpdate := false

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
			err = updateCRD(curObject, collectorCRDPath)
			if err != nil {
				panic(err)
			}

			log.Println("The OpenTelemetry Collector CRD update finished. It's up-to-date now.")

		case "Deployment":
			err = updateImageTags(curObject, valuesYAMLPath, chartYAMLPath)
			if err != nil {
				panic(err)
			}

			log.Println("The values.yaml and Chart.yaml update finished. They are up-to-date now.")

			needUpdate = needUpdate || checkTemplate(curObject, templates)

		default:
			needUpdate = needUpdate || checkTemplate(curObject, templates)
		}
	}

	if !needUpdate {
		log.Println("All the template files are up-to-date.")
	}
}
