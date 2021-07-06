package main

import (
	"errors"
	"fmt"
	"gopkg.in/yaml.v3"
	"io"
	"net/http"
	"os"
	"strings"
)

const (
	operatorManifestURL = "https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml"
	collectorCRDPath = "./crds/crd-opentelemetrycollector.yaml"
)

// K8sObject describes the values a Kubernetes object typically has.
type K8sObject struct {
	ApiVersion string `yaml:"apiVersion"`
	Kind string `yaml:"kind"`
	Metadata map[interface{}]interface{} `yaml:"metadata"`
	Spec map[interface{}]interface{} `yaml:"spec"`
	Status map[interface{}]interface{} `yaml:"status"`
}

// The main keeps the OpenTelemetry Operator (OTEL Operator) Helm chart configurations up-to-date with the upstream semi-automatically.
// First, it scrapes the latest OTEL Operator manifest from the OTEL Operator github:
// https://github.com/open-telemetry/opentelemetry-operator.
// Then, it will automatically update the OpenTelemetry Collector CRD YAML file, which is the only CRD at this point.
// At last, it will retrieve the latest image tag from the OTEL Operator manifest. But it won't update values.yaml automatically since
// this will damage the comments and the configuration order of the values.yaml. Maintainers need to update the values.yaml manually.
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
			fmt.Println("The OpenTelemetry Collector CRD update finished. It's up-to-date now.")
		case "Deployment":
			// Retrieve the latest image repository and tag of the two container images.
			managerImage := strings.Split(curObject.Spec["template"].(map[string]interface{})["spec"].
				(map[string]interface{})["containers"].([]interface{})[0].(map[string]interface{})["image"].(string), ":")
			kubeRBACProxyImage := strings.Split(curObject.Spec["template"].(map[string]interface{})["spec"].
				(map[string]interface{})["containers"].([]interface{})[1].(map[string]interface{})["image"].(string), ":")
			fmt.Printf("The latest manager image repository is %s, tag is %s\n", managerImage[0], managerImage[1])
			fmt.Printf("The latest kube-rbac-proxy image repository is %s, tag is %s\n", kubeRBACProxyImage[0], kubeRBACProxyImage[1])
			fmt.Printf("Please update these values in values.yaml.\n")
		default:
			continue
		}
	}
}
