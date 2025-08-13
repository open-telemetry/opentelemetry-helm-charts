TMP_DIRECTORY = ./tmp
CHARTS ?= opentelemetry-collector opentelemetry-operator opentelemetry-demo opentelemetry-ebpf
MAX_PARALLEL_EXAMPLES ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Reusable parallel execution with ordered logging utility
define run_parallel_with_logging
	RUNNING_JOBS=0; \
	EXAMPLE_ORDER=""; \
	mkdir -p $(TMP_DIRECTORY)/logs; \
	for example in $(1); do \
		while [ $$RUNNING_JOBS -ge $(MAX_PARALLEL_EXAMPLES) ]; do \
			wait -n 2>/dev/null || true; \
			RUNNING_JOBS=$$(($$RUNNING_JOBS - 1)); \
		done; \
		EXAMPLE_ORDER="$${EXAMPLE_ORDER} $${example}"; \
		{ \
			LOG_FILE="$(TMP_DIRECTORY)/logs/$(2)-$${example}.log"; \
			{ $(3); } > "$${LOG_FILE}" 2>&1; \
		} & \
		RUNNING_JOBS=$$(($$RUNNING_JOBS + 1)); \
	done; \
	wait; \
	for example in $${EXAMPLE_ORDER}; do \
		LOG_FILE="$(TMP_DIRECTORY)/logs/$(2)-$${example}.log"; \
		if [ -f "$${LOG_FILE}" ]; then \
			cat "$${LOG_FILE}"; \
			echo "--------------------------------"; \
			rm -f "$${LOG_FILE}"; \
		fi; \
	done; \
	rm -rf $(TMP_DIRECTORY)/logs
endef

.PHONY: generate-examples
generate-examples:
	for chart_name in $(CHARTS); do \
		echo "Processing chart: $${chart_name} (max $(MAX_PARALLEL_EXAMPLES) parallel examples)"; \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \;); \
		helm dependency build charts/$${chart_name}; \
		$(call run_parallel_with_logging,$${EXAMPLES},$${chart_name}, \
			echo "Generating example: $${example}"; \
			VALUES=$$(find $${EXAMPLES_DIR}/$${example} -name *values.yaml); \
			rm -rf "$${EXAMPLES_DIR}/$${example}/rendered"; \
			for value in $${VALUES}; do \
				helm template example charts/$${chart_name} --namespace default --values $${value} --output-dir "$${EXAMPLES_DIR}/$${example}/rendered" | sed '/^$$/d'; \
				mv $${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}/templates/* "$${EXAMPLES_DIR}/$${example}/rendered"; \
				SUBCHARTS_DIR=$${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}/charts; \
				if [ -d "$${SUBCHARTS_DIR}" ]; then \
					SUBCHARTS=$$(find $${SUBCHARTS_DIR} -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \; 2>/dev/null || true); \
					for subchart in $${SUBCHARTS}; do \
						mkdir -p "$${EXAMPLES_DIR}/$${example}/rendered/$${subchart}"; \
						mv $${SUBCHARTS_DIR}/$${subchart}/templates/* "$${EXAMPLES_DIR}/$${example}/rendered/$${subchart}" 2>/dev/null || true; \
					done; \
				fi; \
				rm -rf $${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}; \
			done; \
			printf "Completed example: $${example}\n" \
		); \
		echo "Completed chart: $${chart_name}"; \
	done

.PHONY: check-examples
check-examples:
	for chart_name in $(CHARTS); do \
		echo "Checking chart: $${chart_name} (max $(MAX_PARALLEL_EXAMPLES) parallel examples)"; \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \;); \
		helm dependency build charts/$${chart_name}; \
		EXIT_CODE=0; \
		$(call run_parallel_with_logging,$${EXAMPLES},$${chart_name}, \
			echo "Checking example: $${example}"; \
			EXAMPLE_TMP="${TMP_DIRECTORY}/check-$${chart_name}-$${example}"; \
			VALUES=$$(find $${EXAMPLES_DIR}/$${example} -name *values.yaml); \
			for value in $${VALUES}; do \
				helm template example charts/$${chart_name} --namespace default --values $${value} --output-dir "$${EXAMPLE_TMP}" | sed '/^$$/d'; \
				SUBCHARTS_DIR=$${EXAMPLE_TMP}/$${chart_name}/charts; \
				if [ -d "$${SUBCHARTS_DIR}" ]; then \
					SUBCHARTS=$$(find $${SUBCHARTS_DIR} -type d -maxdepth 1 -mindepth 1 -exec basename \{\} \; 2>/dev/null || true); \
					for subchart in $${SUBCHARTS}; do \
						mkdir -p "$${EXAMPLE_TMP}/$${chart_name}/templates/$${subchart}"; \
						mv $${SUBCHARTS_DIR}/$${subchart}/templates/* "$${EXAMPLE_TMP}/$${chart_name}/templates/$${subchart}" 2>/dev/null || true; \
					done; \
				fi; \
			done; \
			if diff -r "$${EXAMPLES_DIR}/$${example}/rendered" "$${EXAMPLE_TMP}/$${chart_name}/templates" > /dev/null 2>&1; then \
				printf "Passed $${example}\n"; \
			else \
				printf "Failed $${example}. run 'make generate-examples' to re-render the example with the latest $${example}/values.yaml\n"; \
				EXIT_CODE=1; \
			fi; \
			rm -rf "$${EXAMPLE_TMP}" \
		); \
		if [ $$EXIT_CODE -ne 0 ]; then \
			echo "Some examples failed for chart: $${chart_name}"; \
			exit 1; \
		fi; \
		echo "All examples passed for chart: $${chart_name}"; \
	done

.PHONY: update-operator-crds
update-operator-crds:
	APP_VERSION=$$(cat ./charts/opentelemetry-operator/Chart.yaml | sed -nr 's/appVersion: ([0-9]+\.[0-9]+\.[0-9]+)/\1/p') ; \
	curl -s -o ./charts/opentelemetry-operator/crds/crd-opentelemetrycollector.yaml https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$${APP_VERSION}/config/crd/bases/opentelemetry.io_opentelemetrycollectors.yaml ; \
	curl -s -o ./charts/opentelemetry-operator/crds/crd-opentelemetryinstrumentation.yaml https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$${APP_VERSION}/config/crd/bases/opentelemetry.io_instrumentations.yaml ; \
	curl -s -o ./charts/opentelemetry-operator/crds/crd-opentelemetry.io_opampbridges.yaml https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$${APP_VERSION}/config/crd/bases/opentelemetry.io_opampbridges.yaml

.PHONY: check-operator-crds
check-operator-crds:
	APP_VERSION=$$(cat ./charts/opentelemetry-operator/Chart.yaml | sed -nr 's/appVersion: ([0-9]+\.[0-9]+\.[0-9]+)/\1/p'); \
	mkdir -p ${TMP_DIRECTORY}/crds; \
	curl -s -o "${TMP_DIRECTORY}/crds/crd-opentelemetrycollector.yaml" https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$${APP_VERSION}/config/crd/bases/opentelemetry.io_opentelemetrycollectors.yaml; \
	curl -s -o "${TMP_DIRECTORY}/crds/crd-opentelemetryinstrumentation.yaml" https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$${APP_VERSION}/config/crd/bases/opentelemetry.io_instrumentations.yaml; \
	curl -s -o "${TMP_DIRECTORY}/crds/crd-opentelemetry.io_opampbridges.yaml" https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$${APP_VERSION}/config/crd/bases/opentelemetry.io_opampbridges.yaml; \
	if diff ${TMP_DIRECTORY}/crds ./charts/opentelemetry-operator/crds > /dev/null; then \
		echo "Passed"; \
		rm -rf ${TMP_DIRECTORY}; \
	else \
		echo "Failed. run 'make update-operator-crds' to update the crds"; \
		rm -rf ${TMP_DIRECTORY}; \
		exit 1; \
	fi; \

.PHONY: validate-examples
validate-examples:
	cd charts/opentelemetry-collector && ./validate-configs.sh