# Prometheus Replacement example
This example contains files to allow a user to replace an installation of kube-prometheus-stack. The opentelemetry-kube-stack chart aims to make the replacement process straightforward by utilizing the target allocator to pull any servicemonitors and podmonitors.

> [!INFO]
> This chart has most of the same configurations as the kube-prometheus-stack chart, but requires that kubelet monitoring is done via a manual scrape config. This is because of how the prometheus-operator manages endpoints for the Kubelet service. If you'd like to avoid a scrape-config altogether, it's recommended to use the kubelet receiver in the opentelemetry collector.
