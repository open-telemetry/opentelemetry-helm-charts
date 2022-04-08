# Upgrade guidelines

## 0.13.0 to 0.14.0

[Remove two-deployment mode](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/159)

The ability to install both the agent and standalone collectors simultaneous with the chart has been removed.  Instead, to install the collector as both a daemonset and deployment you will need to install twice.  `agentCollector` and `standloneCollector` have also be deprecated, but backwords compatibility has been maintained.

If you currently install both version of the collector simultaneously:

1. 
