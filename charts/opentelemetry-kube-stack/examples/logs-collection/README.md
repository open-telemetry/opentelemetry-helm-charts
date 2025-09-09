# Logs Collection example
This configuration enables collection of Kubernetes Events and container logs with offset tracking (stored on the node) using an OpenTelemetry Collector deployed as a DaemonSet, excluding the Collector's own logs to prevent recursive ingestion, redacting sensitive data like passwords (skipping 'null' and 'none') and JWT tokens, and sending logs to a Loki for ingestion.
