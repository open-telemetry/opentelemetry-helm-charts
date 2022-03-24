TMP_DIRECTORY = ./tmp
CHARTS ?= opentelemetry-collector opentelemetry-operator

.PHONY: generate-examples
generate-examples: 
	for chart_name in $(CHARTS); do \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \;); \
		for example in $${EXAMPLES}; do \
			rm -rf "$${EXAMPLES_DIR}/$${example}/rendered"; \
			helm template example charts/$${chart_name} --values "$${EXAMPLES_DIR}/$${example}/values.yaml" --output-dir "$${EXAMPLES_DIR}/$${example}/rendered"; \
			mv $${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}/templates/* "$${EXAMPLES_DIR}/$${example}/rendered"; \
			rm -rf $${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}; \
		done; \
	done

.PHONY: check-examples
check-examples:
	for chart_name in $(CHARTS); do \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \;); \
		for example in $${EXAMPLES}; do \
			echo "Checking example: $${example}"; \
			helm template example charts/$${chart_name} --values "$${EXAMPLES_DIR}/$${example}/values.yaml" --output-dir "${TMP_DIRECTORY}/$${example}"; \
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
