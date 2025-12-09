# syntax=docker/dockerfile:1

# renovate: datasource=github-releases packageName=helm/chart-testing
ARG CHART_TESTING_VERSION='3.14.0'
# renovate: datasource=github-releases packageName=helm/helm
ARG HELM_VERSION='3.19.2'
# renovate: datasource=github-releases packageName=kubernetes-sigs/kind
ARG KIND_VERSION='0.30.0'
# renovate: datasource=github-tags depName=kubectl packageName=kubernetes/kubectl extractVersion=^kubernetes-(?<version>.+)$
ARG KUBECTL_VERSION='1.34.2'
# renovate: datasource=github-releases packageName=aquasecurity/trivy
ARG TRIVY_VERSION='0.68.1'
# # renovate: datasource=github-releases packageName=pre-commit/pre-commit
# ARG PRE_COMMIT_VERSION='4.5.0'

FROM mcr.microsoft.com/devcontainers/python:3.14-bookworm AS base
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]
ARG TARGETPLATFORM

RUN <<EOT
	if [ "${TARGETPLATFORM}" != 'linux/amd64' ] && [ "${TARGETPLATFORM}" != 'linux/arm64' ]; then
		echo "Platform ${TARGETPLATFORM} currently not supported!" >&2
		exit 2
	fi
	mkdir -p /tmp/output-bin/
EOT

FROM base AS tools-misc
ARG TARGETARCH
ARG TRIVY_VERSION PRE_COMMIT_VERSION

RUN <<EOF

	arch="$(echo "${TARGETARCH}" | sed s/arm64/ARM/ | sed s/amd64/64bit/)"
	curl -fsSL -o /tmp/trivy.tar.gz "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${arch}.tar.gz"
	tar -xzf /tmp/trivy.tar.gz -C /tmp/output-bin/ --no-same-owner trivy
	rm -f /tmp/trivy.tar.gz
	/tmp/output-bin/trivy --version
EOF

FROM base AS tools-k8s
ARG KUBECTL_VERSION KIND_VERSION HELM_VERSION CHART_TESTING_VERSION
ARG TARGETARCH

RUN <<EOF
	mkdir -p /tmp/output-bin/
	wget -qO /tmp/output-bin/kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl"
	chmod +x /tmp/output-bin/kubectl
	/tmp/output-bin/kubectl version --client

	wget -qO /tmp/helm.tar.gz "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz"
	tar -xzf /tmp/helm.tar.gz -C /tmp/output-bin/ "linux-${TARGETARCH}/helm" --strip-components=1
	rm /tmp/helm.tar.gz
	/tmp/output-bin/helm version

	wget -qO /tmp/output-bin/kind "https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-${TARGETARCH}"
	chmod +x /tmp/output-bin/kind
	/tmp/output-bin/kind version

	wget -qO /tmp/chart-testing.tar.gz "https://github.com/helm/chart-testing/releases/download/v${CHART_TESTING_VERSION}/chart-testing_${CHART_TESTING_VERSION}_linux_${TARGETARCH}.tar.gz"
	tar -xzf /tmp/chart-testing.tar.gz -C /tmp/output-bin/ --no-same-owner ct
	rm -f /tmp/chart-testing.tar.gz
	/tmp/output-bin/ct version
EOF

FROM base AS development-base

RUN <<EOF
	packages=(
		# General
		file
		iputils-ping
		dnsutils
		# IntelliJ requirements
		libxtst6
		libxrender1
		libfontconfig1
		libxi6
		libgtk-3-0
	)
	apt-get update
	apt-get install -y --no-install-recommends "${packages[@]}"
	apt-get clean
	rm -rf /var/lib/apt/lists/*

	pip install pre-commit
	pre-commit -V
EOF

FROM development-base AS development

COPY --from=tools-k8s /tmp/output-bin /usr/local/bin/
COPY --from=tools-misc /tmp/output-bin /usr/local/bin/
