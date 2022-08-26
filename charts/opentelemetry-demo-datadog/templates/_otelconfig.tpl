{{- define "otel-demo.otelcol.config" -}}
 receivers:
      prometheus:
        config:
          scrape_configs:
          - job_name: 'otelcol'
            scrape_interval: 10s
            static_configs:
            - targets: ['0.0.0.0:8888']
            metric_relabel_configs:
            - source_labels: [ __name__ ]
              regex: '.*grpc_io.*'
              action: drop
      k8s_cluster:
        collection_interval: 10s
      hostmetrics:
        collection_interval: 10s
        scrapers:
          paging:
            metrics:
              system.paging.utilization:
                enabled: true
              system.paging.usage:
                enabled: true
          cpu:
            metrics:
              system.cpu.utilization:
                enabled: true
          disk:
          filesystem:
            metrics:
              system.filesystem.utilization:
                enabled: true
          load:
          memory:
            metrics:
              system.memory.utilization:
                enabled: true
          network:
            metrics:
              system.network.io.receive:
                enabled: true
              system.network.io.transmit:
                enabled: true
          processes:
      otlp:
        protocols:
          grpc:
          http:
exporters:
    datadog:
        api:
          key: ${DD_API_KEY}  
processors:
  resourcedetection:
    # ensures host.name and other important resource tags
    # get picked up
    detectors: [system, env]
    timeout: 5s
    override: false
  # adds various tags related to k8s
  k8sattributes:
  batch:
    send_batch_max_size: 1000
    send_batch_size: 100
    timeout: 10s
  metricstransform:
    transforms:
      - include: system.cpu.load_average.1m
        match_type: strict
        action: insert
        new_name: system.load.1
        operations:
          action: add_label
          new_label: dd_dupe_metric
          new_value: true
      - include: system.cpu.load_average.5m
        match_type: strict
        action: insert
        new_name: system.load.5
        operations:
          action: add_label
          new_label: dd_dupe_metric
          new_value: true
      - include: system.cpu.load_average.15m
        match_type: strict
        action: insert
        new_name: system.load.15
        operations:
          action: add_label
          new_label: dd_dupe_metric
          new_value: true
      - include: system.cpu.utilization
        experimental_match_labels: {"state": "idle"}
        match_type: strict
        action: insert
        new_name: system.cpu.idle
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
          - action: experimental_scale_value
            experimental_scale: 100
      - include: system.cpu.utilization
        experimental_match_labels: {"state": "user"}
        match_type: strict
        action: insert
        new_name: system.cpu.user
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
          - action: experimental_scale_value
            experimental_scale: 100
      - include: system.cpu.utilization
        experimental_match_labels: {"state": "wait"}
        match_type: strict
        action: insert
        new_name: system.cpu.iowait
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
          - action: experimental_scale_value
            experimental_scale: 100
      - include: system.cpu.utilization
        experimental_match_labels: {"state": "steal"}
        match_type: strict
        action: insert
        new_name: system.cpu.stolen
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
          - action: experimental_scale_value
            experimental_scale: 100
      - include: system.memory.usage
        match_type: strict
        action: insert
        new_name: system.mem.total
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
          - action: experimental_scale_value
            experimental_scale: 0.000001
      - include: system.memory.usage
        experimental_match_labels: {"state": "free"}
        match_type: strict
        action: insert
        new_name: system.mem.usable
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
      - include: system.memory.usage
        experimental_match_labels: {"state": "cached"}
        match_type: strict
        action: insert
        new_name: system.mem.usable
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
      - include: system.memory.usage
        experimental_match_labels: {"state": "buffered"}
        match_type: strict
        action: insert
        new_name: system.mem.usable
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
      - include: system.mem.usable
        match_type: strict
        action: update
        operations:
          - action: aggregate_label_values
            label: state
            aggregated_values: [ "free", "cached", "buffered" ]
            new_value: usable
            aggregation_type: sum
          - action: experimental_scale_value
            experimental_scale: 0.000001
      - include: system.network.io
        experimental_match_labels: {"direction": "receive"}
        match_type: strict
        action: insert
        new_name: system.net.bytes_rcvd
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
          - action: experimental_scale_value
            experimental_scale: 0.001
      - include: system.network.io
        experimental_match_labels: {"direction": "transmit"}
        match_type: strict
        action: insert
        new_name: system.net.bytes_sent
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
          - action: experimental_scale_value
            experimental_scale: 0.001
      - include: system.filesystem.utilization
        match_type: strict
        action: insert
        new_name: system.disk.in_use
        operations:
          - action: add_label
            new_label: dd_dupe_metric
            new_value: true
service:
  telemetry:
    logs:
        level: debug
  pipelines:
    metrics:
      receivers: [otlp,k8s_cluster,hostmetrics, prometheus]
      processors: [ resourcedetection, k8sattributes, metricstransform, batch]
      exporters: [datadog]
    traces:
      receivers: [otlp]
      processors: [resourcedetection, k8sattributes, batch]
      exporters: [datadog]
{{- end }}
