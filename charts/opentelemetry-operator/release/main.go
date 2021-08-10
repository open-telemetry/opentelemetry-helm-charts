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
	ApiVersion string                        `yaml:"apiVersion"`
	Kind       string                        `yaml:"kind"`
	Metadata   map[interface{}]interface{}   `yaml:"metadata"`
	Spec       map[interface{}]interface{}   `yaml:"spec"`
	Status     map[interface{}]interface{}   `yaml:"status"`
	Rules      []map[interface{}]interface{} `yaml:"rules"`
	RoleRef    map[interface{}]interface{}   `yaml:"roleRef"`
	Subjects   []map[interface{}]interface{} `yaml:"subjects"`
	Webhooks   []map[interface{}]interface{} `yaml:"webhooks"`
}

// The main keeps the OpenTelemetry Operator (OTEL Operator) Helm chart configurations up-to-date with the upstream automatically.
// First, it scrapes the latest OTEL Operator manifest from the OTEL Operator github:
// https://github.com/open-telemetry/opentelemetry-operator.
// Then, it will update the OpenTelemetry Collector CRD YAML file, which is the only CRD at this point.
// Next, it will retrieve the latest image tag from the OTEL Operator manifest and update the values.yaml and Chart.yaml.
// At last, it will check if every template file is up-to-date with the manifest. If not, it will notify the Helm chart maintainers.
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
		// current Kubernetes resource from the upstream manifest
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
			// Update the collector CRD template file.
			err = updateCRD(curObject, collectorCRDPath)
			if err != nil {
				panic(err)
			}

			log.Println("The OpenTelemetry Collector CRD update finished. It's up-to-date now.")

		case "Deployment":
			// Update the values.yaml and Chart.yaml with the latest image tags.
			err = updateImageTags(curObject, valuesYAMLPath, chartYAMLPath)
			if err != nil {
				panic(err)
			}

			log.Println("The values.yaml and Chart.yaml update finished. They are up-to-date now.")

			// Update the templates since we have made changes to values.yaml.
			templates, err = getTemplates()
			if err != nil {
				panic(err)
			}

			needUpdate = checkTemplate(curObject, templates) || needUpdate

		default:
			needUpdate = checkTemplate(curObject, templates) || needUpdate
		}
	}

	if !needUpdate {
		log.Println("All the template files are up-to-date.")
	}
}
