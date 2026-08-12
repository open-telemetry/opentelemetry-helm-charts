TMP_DIRECTORY = ./tmp
CHARTS ?= opentelemetry-collector opentelemetry-operator opentelemetry-demo opentelemetry-ebpf opentelemetry-kube-stack opentelemetry-target-allocator opentelemetry-ebpf-instrumentation
OPERATOR_APP_VERSION ?= "$(shell cat ./charts/opentelemetry-operator/Chart.yaml | sed -nr 's/appVersion: ([0-9]+\.[0-9]+\.[0-9]+)/\1/p')"
KUBE_VERSION ?= 1.29
OPERATOR_SCHEMA = ./charts/opentelemetry-operator/values.schema.json
OPERATOR_FEATUREGATE_URL = https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v$(OPERATOR_APP_VERSION)/pkg/featuregate/featuregate.go

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
		EXAMPLES_DIR=charts/$${chart_name}/examples; \
		EXAMPLES=$$(find $${EXAMPLES_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename \{\} \;); \
		for example in $${EXAMPLES}; do \
			echo "Checking example: $${example}"; \
			VALUES=$$(find $${EXAMPLES_DIR}/$${example} -name *values.yaml); \
			for value in $${VALUES}; do \
				helm dependency build charts/$${chart_name}; \
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
	fi; \

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

define get-crd
@curl -s -o $(1) $(2)
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

define get-clusterobservability-crd
@curl -s -o $(1) $(2)
@sed -i '\#controller-gen.kubebuilder.io/version:#a\    {{- with .Values.crds.annotations }}\n    {{- toYaml . | nindent 4 }}\n    {{- end }}' $(1)
@sed -i '1s/^---/{{- if .Values.crds.create }}/' $(1)
@sed -i '1a{{- if get .Values.manager.featureGatesMap "operator.clusterobservability" }}' $(1)
@echo '{{- end }}\n{{- end }}' >> $(1)
endef
