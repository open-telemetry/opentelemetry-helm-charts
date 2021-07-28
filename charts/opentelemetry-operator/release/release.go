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
	appVersion = "appVersion"
)

func getTemplates() (map[string]K8sObject, error) {
	var curObject K8sObject
	templates := make(map[string]K8sObject)

	cmd := exec.Command("helm", "template", operatorChartPath)
	out, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	rawYAMLFiles := strings.Split(string(out), "---\n")
	for _, rawYAMLFile := range rawYAMLFiles {
		err = yaml.Unmarshal([]byte(rawYAMLFile), &curObject)
		if err != nil {
			return nil, err
		}
		templates[fmt.Sprintf("%v", curObject.Metadata["name"])] = curObject
	}

	return templates, nil
}

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

func updateImageTags(object K8sObject, valuesYAMLPath string, chartYAMLPath string) error {
	// Retrieve the latest image repository and tag of the two container images.
	managerImage := strings.Split(object.Spec["template"].(map[string]interface{})["spec"].(map[string]interface{})["containers"].([]interface{})[0].(map[string]interface{})["image"].(string), ":")
	kubeRBACProxyImage := strings.Split(object.Spec["template"].(map[string]interface{})["spec"].(map[string]interface{})["containers"].([]interface{})[1].(map[string]interface{})["image"].(string), ":")

	// Replace the image tags in values.yaml and appVersion in Chart.yaml with the latest ones.
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

	if err = updateAPPVersion(managerImage[1][1:], chartYAMLPath); err != nil {
		return err
	}

	return nil
}

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

func checkTemplate(curObject K8sObject, templates map[string]K8sObject) bool {
	templateObject := templates[fmt.Sprintf("%v", curObject.Metadata["name"])]

	if !reflect.DeepEqual(curObject, templateObject) {
		var filename string

		switch curObject.Kind {
		case "Certificate", "Issuer":
			filename = "certmanager.yaml"
		default:
			filename = curObject.Kind + ".yaml"
		}

		if templateObject.Kind == "" {
			log.Printf("%v configuration doesn't exist. Please create it in the file: %s", curObject.Metadata["name"], filename)
		} else {
			log.Printf("ATTENTION: %s file needs to be updated", filename)
		}

		return true
	}

	return false
}

func compare(o1 K8sObject, o2 K8sObject) bool {
	// compare apiVersion and kind
	if o1.ApiVersion != o2.ApiVersion || o1.Kind != o2.Kind {
		return false
	}

	// compare metadata, spec and status
	return reflect.DeepEqual(o1.Metadata, o2.Metadata) && reflect.DeepEqual(o1.Spec, o2.Spec) && reflect.DeepEqual(o1.Status, o2.Status)
}
