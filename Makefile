TMP_DIRECTORY = ./tmp
CHARTS ?= opentelemetry-collector opentelemetry-operator opentelemetry-demo

.PHONY: generate-examples
generate-examples: 
	for chart_name in $(CHARTS); do \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \;); \
		for example in $${EXAMPLES}; do \
			VALUES=$$(find $${EXAMPLES_DIR}/$${example} -name *values.yaml); \
			rm -rf "$${EXAMPLES_DIR}/$${example}/rendered"; \
			for value in $${VALUES}; do \
				helm template example charts/$${chart_name} --values $${value} --output-dir "$${EXAMPLES_DIR}/$${example}/rendered"; \
				mv $${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}/templates/* "$${EXAMPLES_DIR}/$${example}/rendered"; \
				rm -rf $${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}; \
			done; \
		done; \
	done

.PHONY: check-examples
check-examples:
	for chart_name in $(CHARTS); do \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \;); \
		for example in $${EXAMPLES}; do \
			echo "Checking example: $${example}"; \
			VALUES=$$(find $${EXAMPLES_DIR}/$${example} -name *values.yaml); \
			for value in $${VALUES}; do \
				helm template example charts/$${chart_name} --values $${value} --output-dir "${TMP_DIRECTORY}/$${example}"; \
			done; \
			if diff "$${EXAMPLES_DIR}/$${example}/rendered" "${TMP_DIRECTORY}/$${example}/$${chart_name}/templates" > /dev/null; then \
				echo "Passed $${example}"; \
			else \
				echo "Failed $${example}. run 'make generate-examples' to re-render the example with the latest $${example}/values.yaml"; \
				rm -rf ${TMP_DIRECTORY}; \
				exit 1; \
			fi; \
			rm -rf ${TMP_DIRECTORY}; \
		done; \
	done

.PHONY: update-crds
update-crds:
	APP_VERSION=$$(cat ./charts/opentelemetry-operator/Chart.yaml | sed -nr 's/appVersion: ([0-9]+\.[0-9]+\.[0-9]+)/\1/p') ; \
	curl -s -o ./charts/opentelemetry-operator/crds/crd-opentelemetrycollector.yaml https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$${APP_VERSION}/config/crd/bases/opentelemetry.io_opentelemetrycollectors.yaml ; \
	curl -s -o ./charts/opentelemetry-operator/crds/crd-opentelemetryinstrumentation.yaml https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$${APP_VERSION}/config/crd/bases/opentelemetry.io_instrumentations.yaml

.PHONY: check-crds
check-crds:
	APP_VERSION=$$(cat ./charts/opentelemetry-operator/Chart.yaml | sed -nr 's/appVersion: ([0-9]+\.[0-9]+\.[0-9]+)/\1/p'); \
	mkdir -p ${TMP_DIRECTORY}/crds; \
	curl -s -o "${TMP_DIRECTORY}/crds/crd-opentelemetrycollector.yaml" https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$${APP_VERSION}/config/crd/bases/opentelemetry.io_opentelemetrycollectors.yaml; \
	curl -s -o "${TMP_DIRECTORY}/crds/crd-opentelemetryinstrumentation.yaml" https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$${APP_VERSION}/config/crd/bases/opentelemetry.io_instrumentations.yaml; \
	if diff ${TMP_DIRECTORY}/crds ./charts/opentelemetry-operator/crds > /dev/null; then \
		echo "Passed"; \
		rm -rf ${TMP_DIRECTORY}; \
	else \
		echo "Failed. run 'make update-crds' to update the crds"; \
		rm -rf ${TMP_DIRECTORY}; \
		exit 1; \
	fi; \
