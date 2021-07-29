package main

import (
	"github.com/stretchr/testify/assert"
	"gopkg.in/yaml.v3"
	"os"
	"strings"
	"testing"
)

func TestCheckTemplate(t *testing.T) {
	templates, err := getTemplates()
	if err != nil {
		t.Errorf("Cannot get template files")
	}

	var randomObject K8sObject
	for _, object := range templates {
		randomObject = object
	}

	type args struct {
		curObject K8sObject
		templates map[string]K8sObject
	}
	tests := []struct {
		name string
		args args
		want bool
	}{
		{
			name: "Check nil object",
			args: args{
				curObject: K8sObject{},
				templates: templates,
			},
			want: false,
		}, {
			name: "Check new object",
			args: args{
				curObject: K8sObject{
					ApiVersion: "newApiVersion",
					Kind:       "newKind",
				},
				templates: templates,
			},
			want: true,
		}, {
			name: "Check existing object",
			args: args{
				curObject: randomObject,
				templates: templates,
			},
			want: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := checkTemplate(tt.args.curObject, tt.args.templates); got != tt.want {
				t.Errorf("checkTemplate() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestGetTemplates(t *testing.T) {
	t.Run("", func(t *testing.T) {
		_, err := getTemplates()
		if err != nil {
			t.Errorf("getTemplates() error = %v", err)
			return
		}
	})
}

func TestUpdateAPPVersion(t *testing.T) {
	mockChartFilePath := "./mockChart.yaml"
	chartFile, err := os.ReadFile(chartYAMLPath)
	if err != nil {
		t.Errorf("Cannot read Chart.yaml file: %v", err)
	}

	err = os.WriteFile(mockChartFilePath, chartFile, 0644)
	if err != nil {
		t.Errorf("Cannot write to mockChart.yaml file: %v", err)
	}

	type args struct {
		version       string
		chartYAMLPath string
	}
	tests := []struct {
		name    string
		args    args
		wantErr bool
	}{
		{
			name: "Cannot find file",
			args: args{
				version:       "v1.0.0",
				chartYAMLPath: "../aa/bb/cc",
			},
			wantErr: true,
		}, {
			name: "Mock update",
			args: args{
				version:       "testVersion",
				chartYAMLPath: mockChartFilePath,
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := updateAPPVersion(tt.args.version, tt.args.chartYAMLPath); (err != nil) != tt.wantErr {
				t.Errorf("updateAPPVersion() error = %v, wantErr %v", err, tt.wantErr)
			}
			if !tt.wantErr {
				mockChartFile, err := os.ReadFile(mockChartFilePath)
				if err != nil {
					t.Errorf("Cannot read mockChart.yaml file: %v", err)
				}
				mockChartFileLines := strings.Split(string(mockChartFile), "\n")
				for _, line := range mockChartFileLines {
					if strings.Contains(line, appVersion) && line != appVersion+": testVersion" {
						t.Errorf("updateAPPVersion() is not working as expected")
					}
				}
			}
		})
	}

	err = os.Remove(mockChartFilePath)
	if err != nil {
		t.Errorf("Cannot delete mockChart.yaml file: %v", err)
	}
}

func TestUpdateCRD(t *testing.T) {
	mockCRDFilePath := "./mockCRD.yaml"
	collectorCRDFile, err := os.ReadFile(collectorCRDPath)
	if err != nil {
		t.Errorf("Cannot read crd-opentelemetrycollector.yaml file: %v", err)
	}

	err = os.WriteFile(mockCRDFilePath, collectorCRDFile, 0644)
	if err != nil {
		t.Errorf("Cannot write to mockCRD.yaml file: %v", err)
	}

	type args struct {
		object           K8sObject
		collectorCRDPath string
	}
	tests := []struct {
		name    string
		args    args
		wantErr bool
	}{
		{
			name: "Cannot find file",
			args: args{
				object:           K8sObject{},
				collectorCRDPath: "./aa/bb/cc",
			},
			wantErr: true,
		}, {
			name: "Write a test CRD object",
			args: args{
				object: K8sObject{
					ApiVersion: "testApiVersion",
					Kind:       "testKind",
				},
				collectorCRDPath: mockCRDFilePath,
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := updateCRD(tt.args.object, tt.args.collectorCRDPath); (err != nil) != tt.wantErr {
				t.Errorf("updateCRD() error = %v, wantErr %v", err, tt.wantErr)
			}
			if !tt.wantErr {
				mockCRDFile, err := os.ReadFile(mockCRDFilePath)
				if err != nil {
					t.Errorf("Cannot read mockCRD.yaml file: %v", err)
				}
				assert.Equal(t, "apiVersion: testApiVersion\nkind: testKind\nmetadata: {}\nspec: {}\nstatus: {}\n", string(mockCRDFile))
			}
		})
	}

	err = os.Remove(mockCRDFilePath)
	if err != nil {
		t.Errorf("Cannot delete mockCRD.yaml file: %v", err)
	}
}

func TestUpdateImageTags(t *testing.T) {
	mockValuesFilePath := "./mockValues.yaml"
	mockValuesContent := "repository: quay.io/opentelemetry/opentelemetry-operator\n    tag: \"v0.29.0\""

	mockChartFilePath := "./mockChart.yaml"
	chartFile, err := os.ReadFile(chartYAMLPath)
	if err != nil {
		t.Errorf("Cannot read Chart.yaml file: %v", err)
	}

	err = os.WriteFile(mockChartFilePath, chartFile, 0644)
	if err != nil {
		t.Errorf("Cannot write to mockChart.yaml file: %v", err)
	}

	err = os.WriteFile(mockValuesFilePath, []byte(mockValuesContent), 0644)
	if err != nil {
		t.Errorf("Cannot write to mockValues.yaml file: %v", err)
	}

	var mockObject K8sObject
	mockDeploymentFile, err := os.ReadFile("./testdata/mockDeployment.yaml")
	if err != nil {
		t.Errorf("Cannot read mockDeployment.yaml file: %v", err)
	}

	err = yaml.Unmarshal(mockDeploymentFile, &mockObject)
	if err != nil {
		t.Errorf("Cannot unmarshal mockDeployment.yaml file: %v", err)
	}

	type args struct {
		object         K8sObject
		valuesYAMLPath string
		chartYAMLPath  string
	}
	tests := []struct {
		name    string
		args    args
		wantErr bool
	}{
		{
			name: "Mock update image",
			args: args{
				object:         mockObject,
				valuesYAMLPath: mockValuesFilePath,
				chartYAMLPath:  mockChartFilePath,
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := updateImageTags(tt.args.object, tt.args.valuesYAMLPath, tt.args.chartYAMLPath); (err != nil) != tt.wantErr {
				t.Errorf("updateImageTags() error = %v, wantErr %v", err, tt.wantErr)
			}
			mockValuesFile, err := os.ReadFile(mockValuesFilePath)
			if err != nil {
				t.Errorf("Cannot read mockValues.yaml file: %v", err)
			}
			assert.Equal(t, "repository: quay.io/opentelemetry/opentelemetry-operator\n    tag: v1.1.1", string(mockValuesFile))
		})
	}

	err = os.Remove(mockValuesFilePath)
	if err != nil {
		t.Errorf("Cannot delete mockValues.yaml file: %v", err)
	}

	err = os.Remove(mockChartFilePath)
	if err != nil {
		t.Errorf("Cannot delete mockChart.yaml file: %v", err)
	}
}
