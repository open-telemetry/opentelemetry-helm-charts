package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"reflect"
	"strings"

	"gopkg.in/yaml.v3"
)

const (
	operatorChartPath = ".."
	appVersion        = "appVersion"
)

// getTemplates renders all the template files in this Helm chart and stores them into a map whose keys are the
// Kubernetes resource kind plus name and values are the Kubernetes resource itself.
func getTemplates() (map[string]K8sObject, error) {
	templates := make(map[string]K8sObject)

	// Use `helm template` command to render all the template files.
	cmd := exec.Command("helm", "template", operatorChartPath)
	out, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	// Process all the YAML files and store the key-value pairs into templates map.
	rawYAMLFiles := strings.Split(string(out), "---\n")
	for _, rawYAMLFile := range rawYAMLFiles {
		var curObject K8sObject
		err = yaml.Unmarshal([]byte(rawYAMLFile), &curObject)
		if err != nil {
			return nil, err
		}
		templates[fmt.Sprintf("%s#%v", curObject.Kind, curObject.Metadata["name"])] = curObject
	}

	return templates, nil
}

// updateCRD writes the latest OpenTelemetry Collector CRD template file to the Helm chart's Collector CRD file.
func updateCRD(object K8sObject, collectorCRDPath string) error {
	out, err := yaml.Marshal(object)
	if err != nil {
		return err
	}

	err = os.WriteFile(collectorCRDPath, out, 0644)
	if err != nil {
		return err
	}

	return nil
}

// updateImageTags retrieves the latest image tags and update the values.yaml and Chart.yaml respectively.
func updateImageTags(object K8sObject, valuesYAMLPath string, chartYAMLPath string) error {
	// Retrieve the latest image repository and tag of the two container images.
	containers := object.Spec["template"].(map[string]interface{})["spec"].(map[string]interface{})["containers"].([]interface{})
	var managerImage, kubeRBACProxyImage []string
	for i := range containers {
		image := containers[i].(map[string]interface{})["image"].(string)
		switch containers[i].(map[string]interface{})["name"].(string) {
		case "manager":
			managerImage = strings.Split(image, ":")
		case "kube-rbac-proxy":
			kubeRBACProxyImage = strings.Split(image, ":")
		}
	}

	// Replace the image tags in values.yaml with the latest ones.
	valuesFile, err := os.ReadFile(valuesYAMLPath)
	if err != nil {
		return err
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
		return err
	}

	// Update the appVersion in Chart.yaml.
	if err = updateAPPVersion(managerImage[1][1:], chartYAMLPath); err != nil {
		return err
	}

	return nil
}

// updateAPPVersion is a helper function of updateImageTags. It updates the appVersion in Chart.yaml with the given version.
func updateAPPVersion(version string, chartYAMLPath string) error {
	chartFile, err := os.ReadFile(chartYAMLPath)
	if err != nil {
		return err
	}

	chartFileLines := strings.Split(string(chartFile), "\n")
	for i, line := range chartFileLines {
		if strings.Contains(line, appVersion) {
			chartFileLines[i] = appVersion + ": " + version
		}
	}

	chartFileOutput := strings.Join(chartFileLines, "\n")
	err = os.WriteFile(chartYAMLPath, []byte(chartFileOutput), 0644)
	if err != nil {
		return err
	}

	return nil
}

// checkTemplate checks if a given Kubernetes resource has a corresponding template file in this chart or not. If a counterpart exists,
// it will also check if the two configuration files are the same.
func checkTemplate(curObject K8sObject, templates map[string]K8sObject) bool {
	// Get the template file in this chart.
	templateObject := templates[fmt.Sprintf("%s#%v", curObject.Kind, curObject.Metadata["name"])]

	if !reflect.DeepEqual(curObject, templateObject) {
		var filename string

		switch curObject.Kind {
		case "Certificate", "Issuer":
			filename = "certmanager.yaml"
		default:
			filename = strings.ToLower(curObject.Kind) + ".yaml"
		}

		if templateObject.Kind == "" {
			log.Printf("ATTENTION: %v configuration doesn't exist. Please create it in the file: %s", curObject.Metadata["name"], filename)
		} else {
			log.Printf("ATTENTION: %s file needs to be updated", filename)
		}

		return true
	}

	return false
}
