ifeq ($(findstring _,$(MAKECMDGOALS)),_)
$(error target $(MAKECMDGOALS) is private)
endif

COLLECTOR_CHART = ./charts/opentelemetry-collector
COLLECTOR_EXAMPLES_DIR = ${COLLECTOR_CHART}/examples
COLLECTOR_EXAMPLES = $(notdir $(shell find $(COLLECTOR_EXAMPLES_DIR) -type d -maxdepth 1 -mindepth 1))

OPERATOR_CHART = ./charts/opentelemetry-operator
OPERATOR_EXAMPLES_DIR = ${OPERATOR_CHART}/examples
OPERATOR_EXAMPLES = $(notdir $(shell find $(OPERATOR_EXAMPLES_DIR) -type d -maxdepth 1 -mindepth 1))

TMP_DIRECTORY = ./tmp

.PHONY: generate-examples
generate-examples: 
	$(MAKE) generate-collector-examples 
	$(MAKE) generate-operator-examples

.PHONY: generate-collector-examples
generate-collector-examples: CHART=${COLLECTOR_CHART}
generate-collector-examples: EXAMPLES_DIR=${COLLECTOR_EXAMPLES_DIR}
generate-collector-examples: EXAMPLES=${COLLECTOR_EXAMPLES}
generate-collector-examples: CHART_NAME=opentelemetry-collector
generate-collector-examples: _generate-examples-helper

.PHONY: generate-operator-examples
generate-operator-examples: CHART=${OPERATOR_CHART}
generate-operator-examples: EXAMPLES_DIR=${OPERATOR_EXAMPLES_DIR}
generate-operator-examples: EXAMPLES=${OPERATOR_EXAMPLES}
generate-operator-examples: CHART_NAME=opentelemetry-operator
generate-operator-examples: _generate-examples-helper

.PHONY: _generate-examples-helper
_generate-examples-helper:
	for example in $(EXAMPLES); do \
		rm -rf "${EXAMPLES_DIR}/$${example}/rendered"; \
		helm template example $(CHART) --values "${EXAMPLES_DIR}/$${example}/values.yaml" --output-dir "${EXAMPLES_DIR}/$${example}/rendered"; \
		mv ${EXAMPLES_DIR}/$${example}/rendered/${CHART_NAME}/templates/* "${EXAMPLES_DIR}/$${example}/rendered"; \
		rm -rf ${EXAMPLES_DIR}/$${example}/rendered/${CHART_NAME}; \
	done

.PHONY: check-examples
check-examples: 
	$(MAKE) check-collector-examples 
	$(MAKE) check-operator-examples

.PHONY: check-collector-examples
check-collector-examples: CHART=${COLLECTOR_CHART}
check-collector-examples: EXAMPLES_DIR=${COLLECTOR_EXAMPLES_DIR}
check-collector-examples: EXAMPLES=${COLLECTOR_EXAMPLES}
check-collector-examples: CHART_NAME=opentelemetry-collector
check-collector-examples: _check-examples-helper

.PHONY: check-operator-examples
check-operator-examples: CHART=${OPERATOR_CHART}
check-operator-examples: EXAMPLES_DIR=${OPERATOR_EXAMPLES_DIR}
check-operator-examples: EXAMPLES=${OPERATOR_EXAMPLES}
check-operator-examples: CHART_NAME=opentelemetry-operator
check-operator-examples: _check-examples-helper

.PHONY: check-collector-examples
_check-examples-helper:
	for example in $(EXAMPLES); do \
		echo "Checking example: $${example}"; \
		helm template example $(CHART) --values "${EXAMPLES_DIR}/$${example}/values.yaml" --output-dir "${TMP_DIRECTORY}/$${example}"; \
		if diff "${EXAMPLES_DIR}/$${example}/rendered" "${TMP_DIRECTORY}/$${example}/${CHART_NAME}/templates" > /dev/null; then \
			echo "Passed $${example}"; \
		else \
			echo "Failed $${example}. run 'make generate-examples' to re-render the example with the latest $${example}/values.yaml"; \
			rm -rf ${TMP_DIRECTORY}; \
			exit 1; \
		fi; \
		rm -rf ${TMP_DIRECTORY}; \
	done
