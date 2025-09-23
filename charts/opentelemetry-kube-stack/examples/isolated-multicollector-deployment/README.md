# Isolated Multi-Collector Deployment example

This configuration involves deploying multiple OpenTelemetry collectors which potentially could be placed on the same node, each serving different purposes while maintaining complete storage and resource isolation:

- **Agent Collector** - handles telemetry (primarily logs) collection from applications and infrastructure in the cluster
- **Gateway Collector** - manages aggregation, processing, and forwarding of telemetry data to external systems for retention, audit etc.
- **Ingress Collector** - responsible for receiving and processing external telemetry data from remote sources or third-party systems tied to workloads in the cluster

Each collector operates with its own dedicated queue storage paths and configuration files to prevent conflicts and ensure independent operation. 

> [!WARNING]
> While it's recommended to use Persistent Volume Claims (PVC) for deployment collectors in production environments, this scenario uses node local storage to simplify the configuration example and demonstrate how the storage paths would be structured across multiple collector instances. The key requirement is ensuring proper separation of file storage directories and processing resources to avoid data corruption or operational interference between collector instances.
