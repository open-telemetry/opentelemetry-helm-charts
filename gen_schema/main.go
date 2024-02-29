package main

import (
	"encoding/json"
	"fmt"
	"github.com/invopop/jsonschema"
	// "github.com/ghodss/yaml"
	"github.com/open-telemetry/opentelemetry-operator/apis/v1alpha1"
)

func main() {
	s := jsonschema.Reflect(&v1alpha1.OpAMPBridgeSpec{})
	data, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		panic(err.Error())
	}
	fmt.Println(string(data))
}
