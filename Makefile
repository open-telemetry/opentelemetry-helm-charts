TMP_DIRECTORY = ./tmp
CHARTS ?= opentelemetry-collector opentelemetry-operator opentelemetry-demo opentelemetry-ebpf opentelemetry-kube-stack opentelemetry-target-allocator opentelemetry-ebpf-instrumentation opentelemetry-otap-dataflow
OPERATOR_APP_VERSION ?= "$(shell cat ./charts/opentelemetry-operator/Chart.yaml | sed -nr 's/appVersion: ([0-9]+\.[0-9]+\.[0-9]+)/\1/p')"
KUBE_STACK_OPERATOR_APP_VERSION ?= $(shell cat ./charts/opentelemetry-kube-stack/Chart.yaml | sed -nr 's/appVersion: ([0-9]+\.[0-9]+\.[0-9]+)/\1/p')
DEMO_APP_VERSION ?= $(shell cat ./charts/opentelemetry-demo/Chart.yaml | sed -nr 's/appVersion: ([0-9]+\.[0-9]+\.[0-9]+)/\1/p')

KUBE_VERSION ?= 1.29
OPERATOR_SCHEMA = ./charts/opentelemetry-operator/values.schema.json
OPERATOR_FEATUREGATE_URL = https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/pkg/featuregate/featuregate.go
DEMO_AGENT_FIXTURES_URL = https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/$(DEMO_APP_VERSION)/src/agent/fixtures/vcr_cassettes
DEMO_FIXTURES_DIR = ./charts/opentelemetry-demo/agent-fixtures
DEMO_POSTGRESQL_INIT_URL = https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/$(DEMO_APP_VERSION)/src/postgresql/init.sql
DEMO_POSTGRESQL_INIT = ./charts/opentelemetry-demo/postgresql/init.sql
DEMO_DASHBOARDS_SOURCE_PATH = src/grafana/provisioning/dashboards/demo
DEMO_DASHBOARD_FILES_URL = https://api.github.com/repos/open-telemetry/opentelemetry-demo/contents/$(DEMO_DASHBOARDS_SOURCE_PATH)?ref=$(DEMO_APP_VERSION)
DEMO_DASHBOARDS_DIR = ./charts/opentelemetry-demo/grafana/provisioning/dashboards

.PHONY: generate-examples
generate-examples:
	for chart_name in $(CHARTS); do \
		helm dependency build charts/$${chart_name}; \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename \{\} \;); \
		for example in $${EXAMPLES}; do \
			echo "Generating example: $${example}"; \
			VALUES=$$(find $${EXAMPLES_DIR}/$${example} -name *values.yaml); \
			rm -rf "$${EXAMPLES_DIR}/$${example}/rendered"; \
			for value in $${VALUES}; do \
				helm template example charts/$${chart_name} --namespace default --values $${value} --kube-version $(KUBE_VERSION) --output-dir "$${EXAMPLES_DIR}/$${example}/rendered"; \
				mv $${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}/templates/* "$${EXAMPLES_DIR}/$${example}/rendered"; \
				SUBCHARTS_DIR=$${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}/charts; \
				if [ -d "$${SUBCHARTS_DIR}" ]; then \
					SUBCHARTS=$$(find $${SUBCHARTS_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename \{\} \;); \
					for subchart in $${SUBCHARTS}; do \
						mkdir -p "$${EXAMPLES_DIR}/$${example}/rendered/$${subchart}"; \
						mv $${SUBCHARTS_DIR}/$${subchart}/templates/* "$${EXAMPLES_DIR}/$${example}/rendered/$${subchart}"; \
					done; \
				fi; \
				rm -rf $${EXAMPLES_DIR}/$${example}/rendered/$${chart_name}; \
			done; \
			find "$${EXAMPLES_DIR}/$${example}/rendered" -type f -exec perl -i -0777 -pe 's/[ \t\n]+(?=\n---\n)//g; s/[ \t\n]+\z/\n/' {} +; \
		done; \
	done

.PHONY: check-examples
check-examples:
	for chart_name in $(CHARTS); do \
		helm dependency build charts/$${chart_name}; \
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename \{\} \;); \
		for example in $${EXAMPLES}; do \
			echo "Checking example: $${example}"; \
			VALUES=$$(find $${EXAMPLES_DIR}/$${example} -name *values.yaml); \
			for value in $${VALUES}; do \
				helm template example charts/$${chart_name} --namespace default --values $${value} --kube-version $(KUBE_VERSION) --output-dir "${TMP_DIRECTORY}/$${example}"; \
				SUBCHARTS_DIR=${TMP_DIRECTORY}/$${example}/$${chart_name}/charts; \
				SUBCHARTS=$$(find $${SUBCHARTS_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename \{\} \;); \
				for subchart in $${SUBCHARTS}; do \
					mkdir -p "${TMP_DIRECTORY}/$${example}/$${chart_name}/templates/$${subchart}"; \
					mv ${TMP_DIRECTORY}/$${example}/$${chart_name}/charts/$${subchart}/templates/* "${TMP_DIRECTORY}/$${example}/$${chart_name}/templates/$${subchart}"; \
				done; \
			done; \
			find "${TMP_DIRECTORY}/$${example}/$${chart_name}/templates" -type f -exec perl -i -0777 -pe 's/[ \t\n]+(?=\n---\n)//g; s/[ \t\n]+\z/\n/' {} +; \
			if diff -r -I 'checksum/config' -I 'helm\.sh/chart' "$${EXAMPLES_DIR}/$${example}/rendered" "${TMP_DIRECTORY}/$${example}/$${chart_name}/templates" > /dev/null; then \
				echo "Passed $${example}"; \
			else \
				diff -r -I 'checksum/config' -I 'helm\.sh/chart' "$${EXAMPLES_DIR}/$${example}/rendered" "${TMP_DIRECTORY}/$${example}/$${chart_name}/templates"; \
				echo "Failed $${example}. run 'make generate-examples' to re-render the example with the latest $${example}/values.yaml"; \
				rm -rf ${TMP_DIRECTORY}; \
				exit 1; \
			fi; \
			rm -rf ${TMP_DIRECTORY}; \
		done; \
	done

.PHONY: update-operator-crds
update-operator-crds:
	$(call get-crd,./charts/opentelemetry-operator/conf/crds/crd-opentelemetrycollector.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/bundle/community/manifests/opentelemetry.io_opentelemetrycollectors.yaml)
	$(call get-crd,./charts/opentelemetry-operator/conf/crds/crd-opentelemetryinstrumentation.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/bundle/community/manifests/opentelemetry.io_instrumentations.yaml)
	$(call get-crd,./charts/opentelemetry-operator/conf/crds/crd-opentelemetry.io_opampbridges.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/bundle/community/manifests/opentelemetry.io_opampbridges.yaml)
	$(call get-crd,./charts/opentelemetry-operator/conf/crds/crd-opentelemetry.io_targetallocators.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/bundle/community/manifests/opentelemetry.io_targetallocators.yaml)
	$(call get-clusterobservability-crd,./charts/opentelemetry-operator/conf/crds/crd-opentelemetry.io_clusterobservabilities.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/config/crd/bases/opentelemetry.io_clusterobservabilities.yaml)

.PHONY: check-operator-crds
check-operator-crds:
	mkdir -p ${TMP_DIRECTORY}/crds
	$(call get-crd,${TMP_DIRECTORY}/crds/crd-opentelemetrycollector.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/bundle/community/manifests/opentelemetry.io_opentelemetrycollectors.yaml)
	$(call get-crd,${TMP_DIRECTORY}/crds/crd-opentelemetryinstrumentation.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/bundle/community/manifests/opentelemetry.io_instrumentations.yaml)
	$(call get-crd,${TMP_DIRECTORY}/crds/crd-opentelemetry.io_opampbridges.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/bundle/community/manifests/opentelemetry.io_opampbridges.yaml)
	$(call get-crd,${TMP_DIRECTORY}/crds/crd-opentelemetry.io_targetallocators.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/bundle/community/manifests/opentelemetry.io_targetallocators.yaml)
	$(call get-clusterobservability-crd,${TMP_DIRECTORY}/crds/crd-opentelemetry.io_clusterobservabilities.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/config/crd/bases/opentelemetry.io_clusterobservabilities.yaml)

	if diff ${TMP_DIRECTORY}/crds ./charts/opentelemetry-operator/conf/crds > /dev/null; then \
		echo "Passed"; \
		rm -rf ${TMP_DIRECTORY}; \
	else \
		echo "Failed. run 'make update-operator-crds' to update the crds"; \
		rm -rf ${TMP_DIRECTORY}; \
		exit 1; \
	fi

.PHONY: check-opentelemetry-kube-stack-crds
check-opentelemetry-kube-stack-crds:
	mkdir -p $(TMP_DIRECTORY)/otel-crds
	$(call get-base-crd,${TMP_DIRECTORY}/otel-crds/opentelemetry.io_instrumentations.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(KUBE_STACK_OPERATOR_APP_VERSION)/config/crd/bases/opentelemetry.io_instrumentations.yaml)
	$(call get-base-crd,${TMP_DIRECTORY}/otel-crds/opentelemetry.io_opampbridges.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(KUBE_STACK_OPERATOR_APP_VERSION)/config/crd/bases/opentelemetry.io_opampbridges.yaml)
	$(call get-base-crd,${TMP_DIRECTORY}/otel-crds/opentelemetry.io_opentelemetrycollectors.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(KUBE_STACK_OPERATOR_APP_VERSION)/config/crd/bases/opentelemetry.io_opentelemetrycollectors.yaml)
	$(call get-base-crd,${TMP_DIRECTORY}/otel-crds/opentelemetry.io_targetallocators.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(KUBE_STACK_OPERATOR_APP_VERSION)/config/crd/bases/opentelemetry.io_targetallocators.yaml)

	if diff ${TMP_DIRECTORY}/otel-crds ./charts/opentelemetry-kube-stack/charts/otel-crds/crds > /dev/null; then \
		echo "Passed"; \
		rm -rf ${TMP_DIRECTORY}; \
	else \
		echo "Failed otel-crds. run 'make update-opentelemetry-kube-stack-crds' to update the otel-crds"; \
		rm -rf ${TMP_DIRECTORY}; \
		exit 1; \
	fi

.PHONY: update-opentelemetry-kube-stack-crds
update-opentelemetry-kube-stack-crds:
	$(call get-base-crd,./charts/opentelemetry-kube-stack/charts/otel-crds/crds/opentelemetry.io_instrumentations.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(KUBE_STACK_OPERATOR_APP_VERSION)/config/crd/bases/opentelemetry.io_instrumentations.yaml)
	$(call get-base-crd,./charts/opentelemetry-kube-stack/charts/otel-crds/crds/opentelemetry.io_opampbridges.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(KUBE_STACK_OPERATOR_APP_VERSION)/config/crd/bases/opentelemetry.io_opampbridges.yaml)
	$(call get-base-crd,./charts/opentelemetry-kube-stack/charts/otel-crds/crds/opentelemetry.io_opentelemetrycollectors.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(KUBE_STACK_OPERATOR_APP_VERSION)/config/crd/bases/opentelemetry.io_opentelemetrycollectors.yaml)
	$(call get-base-crd,./charts/opentelemetry-kube-stack/charts/otel-crds/crds/opentelemetry.io_targetallocators.yaml,https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(KUBE_STACK_OPERATOR_APP_VERSION)/config/crd/bases/opentelemetry.io_targetallocators.yaml)

.PHONY: check-operator-feature-gates
check-operator-feature-gates:
	mkdir -p ${TMP_DIRECTORY}
	@curl -s $(OPERATOR_FEATUREGATE_URL) | awk '/MustRegister\(/{blk=1;id="";st="";next} blk&&id==""&&match($$0,/"[^"]*"/){id=substr($$0,RSTART+1,RLENGTH-2);next} blk&&st==""&&/featuregate\.Stage/&&match($$0,/Stage(Alpha|Beta|Stable|Deprecated)/){st=substr($$0,RSTART+5,RLENGTH-5)} blk&&/^[ \t]*\)/{if(st=="Alpha"||st=="Beta")print id;blk=0}' | sort > ${TMP_DIRECTORY}/operator-feature-gates.txt
	@jq -r '.properties.manager.properties.featureGatesMap.properties | keys[]' $(OPERATOR_SCHEMA) | sort > ${TMP_DIRECTORY}/schema-feature-gates.txt
	if [ ! -s ${TMP_DIRECTORY}/operator-feature-gates.txt ]; then \
		echo "Failed. Could not read feature gates from the operator (v$(OPERATOR_APP_VERSION))."; \
		rm -rf ${TMP_DIRECTORY}; \
		exit 1; \
	fi; \
	missing=$$(comm -23 ${TMP_DIRECTORY}/operator-feature-gates.txt ${TMP_DIRECTORY}/schema-feature-gates.txt); \
	extra=$$(comm -13 ${TMP_DIRECTORY}/operator-feature-gates.txt ${TMP_DIRECTORY}/schema-feature-gates.txt); \
	rm -rf ${TMP_DIRECTORY}; \
	if [ -z "$$missing" ] && [ -z "$$extra" ]; then \
		echo "Passed"; \
	else \
		echo "Failed. manager.featureGatesMap in charts/opentelemetry-operator/values.schema.json is out of sync with operator v$(OPERATOR_APP_VERSION)."; \
		if [ -n "$$missing" ]; then echo "Add these feature gates to the schema:"; echo "$$missing" | sed 's/^/  /'; fi; \
		if [ -n "$$extra" ]; then echo "Remove these feature gates from the schema:"; echo "$$extra" | sed 's/^/  /'; fi; \
		exit 1; \
	fi

.PHONY: update-demo-agent-fixtures
update-demo-agent-fixtures:
	@TMP_DEMO_DIR=$$(mktemp -d); \
	trap "rm -rf $$TMP_DEMO_DIR" EXIT; \
	curl --fail --silent --show-error --location --max-time 30 -o $$TMP_DEMO_DIR/azure_gpt-5.5_cassette.yaml $(DEMO_AGENT_FIXTURES_URL)/azure_gpt-5.5_cassette.yaml && \
	curl --fail --silent --show-error --location --max-time 30 -o $$TMP_DEMO_DIR/claude-opus-4-7_cassette.yaml $(DEMO_AGENT_FIXTURES_URL)/claude-opus-4-7_cassette.yaml && \
	cp $$TMP_DEMO_DIR/azure_gpt-5.5_cassette.yaml $(DEMO_FIXTURES_DIR)/azure_gpt-5.5_cassette.yaml && \
	cp $$TMP_DEMO_DIR/claude-opus-4-7_cassette.yaml $(DEMO_FIXTURES_DIR)/claude-opus-4-7_cassette.yaml

.PHONY: update-demo-dashboards
update-demo-dashboards:
	@TMP_DEMO_DIR=$$(mktemp -d); \
	trap "rm -rf $$TMP_DEMO_DIR" EXIT; \
	curl --fail --silent --show-error --location --max-time 30 -o $$TMP_DEMO_DIR/manifest "$(DEMO_DASHBOARD_FILES_URL)" || { echo "Failed to list demo dashboards for appVersion $(DEMO_APP_VERSION)" >&2; exit 1; }; \
	jq -e 'type == "array"' $$TMP_DEMO_DIR/manifest > /dev/null || { echo "Invalid dashboard listing for demo appVersion $(DEMO_APP_VERSION)" >&2; exit 1; }; \
	jq -r '.[] | select(.type == "file" and (.name | endswith(".json"))) | .name' $$TMP_DEMO_DIR/manifest > $$TMP_DEMO_DIR/files; \
	test -s $$TMP_DEMO_DIR/files || { echo "No dashboard JSON files found for demo appVersion $(DEMO_APP_VERSION)" >&2; exit 1; }; \
	mkdir $$TMP_DEMO_DIR/source; \
	while IFS= read -r dashboard; do \
		curl --fail --silent --show-error --location --max-time 30 -o "$$TMP_DEMO_DIR/source/$$dashboard" "https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/$(DEMO_APP_VERSION)/$(DEMO_DASHBOARDS_SOURCE_PATH)/$$dashboard" || { echo "Failed to download demo dashboard $$dashboard for appVersion $(DEMO_APP_VERSION)" >&2; exit 1; }; \
		test -s "$$TMP_DEMO_DIR/source/$$dashboard" || { echo "Downloaded demo dashboard $$dashboard for appVersion $(DEMO_APP_VERSION) is empty" >&2; exit 1; }; \
	done < $$TMP_DEMO_DIR/files; \
	for dashboard in $(DEMO_DASHBOARDS_DIR)/*.json; do \
		[ -f "$$dashboard" ] || continue; \
		if [ ! -f "$$TMP_DEMO_DIR/source/$${dashboard##*/}" ]; then rm "$$dashboard"; fi; \
	done; \
	cp $$TMP_DEMO_DIR/source/*.json $(DEMO_DASHBOARDS_DIR)/

.PHONY: check-demo-dashboards
check-demo-dashboards:
	@TMP_DEMO_DIR=$$(mktemp -d); \
	trap "rm -rf $$TMP_DEMO_DIR" EXIT; \
	curl --fail --silent --show-error --location --max-time 30 -o $$TMP_DEMO_DIR/manifest "$(DEMO_DASHBOARD_FILES_URL)" || { echo "Failed to list demo dashboards for appVersion $(DEMO_APP_VERSION)" >&2; exit 1; }; \
	jq -e 'type == "array"' $$TMP_DEMO_DIR/manifest > /dev/null || { echo "Invalid dashboard listing for demo appVersion $(DEMO_APP_VERSION)" >&2; exit 1; }; \
	jq -r '.[] | select(.type == "file" and (.name | endswith(".json"))) | .name' $$TMP_DEMO_DIR/manifest > $$TMP_DEMO_DIR/files; \
	test -s $$TMP_DEMO_DIR/files || { echo "No dashboard JSON files found for demo appVersion $(DEMO_APP_VERSION)" >&2; exit 1; }; \
	mkdir $$TMP_DEMO_DIR/source; \
	while IFS= read -r dashboard; do \
		curl --fail --silent --show-error --location --max-time 30 -o "$$TMP_DEMO_DIR/source/$$dashboard" "https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/$(DEMO_APP_VERSION)/$(DEMO_DASHBOARDS_SOURCE_PATH)/$$dashboard" || { echo "Failed to download demo dashboard $$dashboard for appVersion $(DEMO_APP_VERSION)" >&2; exit 1; }; \
		test -s "$$TMP_DEMO_DIR/source/$$dashboard" || { echo "Downloaded demo dashboard $$dashboard for appVersion $(DEMO_APP_VERSION) is empty" >&2; exit 1; }; \
	done < $$TMP_DEMO_DIR/files; \
	if diff -r $$TMP_DEMO_DIR/source $(DEMO_DASHBOARDS_DIR) > /dev/null 2>&1; then \
		echo "Passed: demo dashboards are in sync with upstream appVersion $(DEMO_APP_VERSION)"; \
	else \
		echo "Failed: demo dashboards are out of sync with upstream appVersion $(DEMO_APP_VERSION)"; \
		echo "Run 'make update-demo-dashboards' to update the dashboards"; \
		exit 1; \
	fi

.PHONY: check-demo-agent-fixtures
check-demo-agent-fixtures:
	@TMP_DEMO_DIR=$$(mktemp -d); \
	trap "rm -rf $$TMP_DEMO_DIR" EXIT; \
	curl --fail --silent --show-error --location --max-time 30 -o $$TMP_DEMO_DIR/azure_gpt-5.5_cassette.yaml $(DEMO_AGENT_FIXTURES_URL)/azure_gpt-5.5_cassette.yaml && \
	curl --fail --silent --show-error --location --max-time 30 -o $$TMP_DEMO_DIR/claude-opus-4-7_cassette.yaml $(DEMO_AGENT_FIXTURES_URL)/claude-opus-4-7_cassette.yaml && \
	if diff -r $$TMP_DEMO_DIR $(DEMO_FIXTURES_DIR) > /dev/null 2>&1; then \
		echo "Passed: demo agent fixtures are in sync with upstream $(DEMO_APP_VERSION)"; \
	else \
		echo "Failed: demo agent fixtures are out of sync with upstream $(DEMO_APP_VERSION)"; \
		echo "Run 'make update-demo-agent-fixtures' to update the cassettes"; \
		exit 1; \
	fi

.PHONY: update-demo-postgresql-init
update-demo-postgresql-init:
	@TMP_DEMO_DIR=$$(mktemp -d); \
	trap "rm -rf $$TMP_DEMO_DIR" EXIT; \
	curl --fail --silent --show-error --location --max-time 30 -o $$TMP_DEMO_DIR/init.sql $(DEMO_POSTGRESQL_INIT_URL) && \
	test -s $$TMP_DEMO_DIR/init.sql && \
	cp $$TMP_DEMO_DIR/init.sql $(DEMO_POSTGRESQL_INIT)

.PHONY: check-demo-postgresql-init
check-demo-postgresql-init:
	@TMP_DEMO_DIR=$$(mktemp -d); \
	trap "rm -rf $$TMP_DEMO_DIR" EXIT; \
	curl --fail --silent --show-error --location --max-time 30 -o $$TMP_DEMO_DIR/init.sql $(DEMO_POSTGRESQL_INIT_URL) && \
	test -s $$TMP_DEMO_DIR/init.sql && \
	if diff $$TMP_DEMO_DIR/init.sql $(DEMO_POSTGRESQL_INIT) > /dev/null 2>&1; then \
		echo "Passed: demo postgresql init.sql is in sync with upstream $(DEMO_APP_VERSION)"; \
	else \
		echo "Failed: demo postgresql init.sql is out of sync with upstream $(DEMO_APP_VERSION)"; \
		echo "Run 'make update-demo-postgresql-init' to update init.sql"; \
		exit 1; \
	fi

define get-crd
$(call get-base-crd,$(1),$(2))
@sed -i '\#controller-gen.kubebuilder.io/version:#a\    {{- with .Values.crds.annotations }}\n    {{- toYaml . | nindent 4 }}\n    {{- end }}' $(1)
@sed -i '\#path: /convert#a {{ if .caBundle }}{{ cat "caBundle:" .caBundle | indent 8 }}{{ end }}' $(1)
@sed -i 's#opentelemetry-operator-system/opentelemetry-operator-serving-cert#{{ include "opentelemetry-operator.webhookCertAnnotation" . }}#g' $(1)
@sed -i 's/opentelemetry-operator-system/{{ template "opentelemetry-operator.namespace" . }}/g' $(1)
@sed -i 's/opentelemetry-operator-webhook-service/{{ template "opentelemetry-operator.fullname" . }}-webhook/g' $(1)
@sed -i '1s/^/{{- if .Values.crds.create }}\n/' $(1)
@sed -i 's#\(.*\)path: /convert#&\n\1port: {{ .Values.admissionWebhooks.servicePort }}#' $(1)
@sed -i 's#\(.*\)conversion:#{{- if .Values.admissionWebhooks.create }}\n&#' $(1)
@sed -i 's#\(.*\)- v1beta1#&\n{{- end }}#' $(1)
@echo '{{- end }}' >> $(1)
endef

define get-base-crd
@curl -s -o $(1) $(2)
endef

define get-clusterobservability-crd
$(call get-base-crd,$(1),$(2))
@sed -i '\#controller-gen.kubebuilder.io/version:#a\    {{- with .Values.crds.annotations }}\n    {{- toYaml . | nindent 4 }}\n    {{- end }}' $(1)
@sed -i '1s/^---/{{- if .Values.crds.create }}/' $(1)
@sed -i '1a{{- if get .Values.manager.featureGatesMap "operator.clusterobservability" }}' $(1)
@echo '{{- end }}\n{{- end }}' >> $(1)
endef
