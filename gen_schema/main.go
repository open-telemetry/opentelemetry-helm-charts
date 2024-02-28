package main

import (
	// "encoding/json"
	"fmt"
	// "github.com/invopop/jsonschema"
	"github.com/ghodss/yaml"
	"github.com/open-telemetry/opentelemetry-operator/apis/v1alpha1"
)

// func main() {
// 	s := jsonschema.Reflect(&v1alpha1.OpenTelemetryCollectorSpec{})
// 	data, err := json.MarshalIndent(s, "", "  ")
// 	if err != nil {
// 		panic(err.Error())
// 	}
// 	fmt.Println(string(data))
// }


func main() {
	// Marshal a Person struct to YAML.
	oc := v1alpha1.OpenTelemetryCollectorSpec{}
	y, err := yaml.Marshal(oc)
	if err != nil {
		fmt.Printf("err: %v\n", err)
		return
	}
	fmt.Println(string(y))
	/* Output:
	age: 30
	name: John
	*/

}
