OPENTELEMETRY_CHART = ./charts/opentelemetry-collector
EXAMPLES_DIRECTORY = ./examples/opentelemetry-collector
EXAMPLES = $(notdir $(shell find $(EXAMPLES_DIRECTORY) -type d -maxdepth 1 -mindepth 1))
TMP_DIRECTORY = ./tmp

.PHONY: generate-examples
generate-examples:
	for example in $(EXAMPLES); do \
		rm -rf "${EXAMPLES_DIRECTORY}/$${example}/manifest"; \
		helm template example $(OPENTELEMETRY_CHART) --values "${EXAMPLES_DIRECTORY}/$${example}/values.yaml" --output-dir "${EXAMPLES_DIRECTORY}/$${example}/manifest"; \
		mv ${EXAMPLES_DIRECTORY}/$${example}/manifest/opentelemetry-collector/templates/* "${EXAMPLES_DIRECTORY}/$${example}/manifest"; \
		rm -rf ${EXAMPLES_DIRECTORY}/$${example}/manifest/opentelemetry-collector; \
	done

.PHONY: check-examples
check-examples:
	for example in $(EXAMPLES); do \
		echo "Checking example: $${example}"; \
		helm template example $(OPENTELEMETRY_CHART) --values "${EXAMPLES_DIRECTORY}/$${example}/values.yaml" --output-dir "${TMP_DIRECTORY}/$${example}"; \
		if diff "${EXAMPLES_DIRECTORY}/$${example}/manifest" "${TMP_DIRECTORY}/$${example}/opentelemetry-collector/templates" > /dev/null; then \
			echo "Passed $${example}"; \
		else \
			echo "Failed $${example}. run 'make generate-examples' to re-render the example with the latest $${example}/values.yaml"; \
			rm -rf ${TMP_DIRECTORY}; \
			exit 1; \
		fi; \
		rm -rf ${TMP_DIRECTORY}; \
	done

