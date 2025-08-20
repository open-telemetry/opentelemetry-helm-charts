
---

# Jaeger Helm-chart Documentation

## Overview
This documentation provides step-by-step setup and configuration instructions for running Jaeger in various modes, with sections for both the `all-in-one` mode and the `Elasticsearch` configuration, followed by details on optional `--set` flags for custom configurations.

---

### 1. Jaeger All-in-One Mode

Jaeger’s all-in-one mode combines the Jaeger Agent, Collector, and Query into a single pod for simplicity. Use this mode for testing or lightweight deployments.

#### **Command to Run All-in-One**

```bash
helm install <chart_name> charts/jaeger \
    --set-file userconfig=path/to/configfile.yaml # Optional: user-specific config
```

- **Flags Explained**:
  - `provisionDataStore.cassandra=false`: Disable Cassandra provision.
  - `storage.type=memory`: Use in-memory storage (non-persistent).
  - `allInOne.enabled=true`: Enable the all-in-one Jaeger setup.
  - `agent.enabled=false`, `collector.enabled=false`, `query.enabled=false`: Disable separate components since they’re embedded in all-in-one.
  - `userconfig`: Optional file for additional configuration.


---

### 2. Elasticsearch Mode with Provisioned Data Store

This mode configures Jaeger to store trace data in an Elasticsearch backend, suitable for production-level usage. 

#### **Command to Run with Elasticsearch**

1. **Single Master Node Configuration**  
   For a basic setup with only one Elasticsearch master node, use this command:

   ```bash
   helm install <chart_name> charts/jaeger \
       --set provisionDataStore.elasticsearch=true \
       --set allInOne.enabled=false \
       --set storage.type=elasticsearch \
       --set elasticsearch.master.masterOnly=false \
       --set elasticsearch.master.replicaCount=1 \
       --set elasticsearch.data.replicaCount=0 \
       --set elasticsearch.coordinating.replicaCount=0 \
       --set elasticsearch.ingest.replicaCount=0
       --set agent.enabled=true \
       --set collector.enabled=true \
       --set query.enabled=true
       --set-file userconfig=path/to/configfile.yaml # Optional: user-specific config
   ```

2. **Default Configuration**  
   For a more straightforward setup with default Elasticsearch configuration, use:

   ```bash
   helm install <chart_name> charts/jaeger \
       --set provisionDataStore.elasticsearch=true \
       --set allInOne.enabled=false \
       --set storage.type=elasticsearch \
       --set agent.enabled=true \
       --set collector.enabled=true \
       --set query.enabled=true
       --set-file userconfig=path/to/configfile.yaml # Optional: user-specific config
   ```

- **Flags Explained**:
  - `provisionDataStore.cassandra=false`: Disable Cassandra provision.
  - `provisionDataStore.elasticsearch=true`: Enable Elasticsearch as the storage.
  - `storage.type=elasticsearch`: Use Elasticsearch for storage.
  - **Single Master Node Settings** (optional for simplified configuration):
    - `elasticsearch.master.masterOnly=false`
    - `elasticsearch.master.replicaCount=1`
    - `elasticsearch.data.replicaCount=0`
    - `elasticsearch.coordinating.replicaCount=0`
    - `elasticsearch.ingest.replicaCount=0`
  - `userconfig`: Optional file for additional configuration.

--- 


### 3. Additional `--set` Configuration Options

For custom configurations, the following flags are commonly used. These cover primary Elasticsearch storage settings and additional archive configurations.

#### **Primary Storage Settings**
- `.Values.config.extensions.jaeger_storage.backends.primary_store.elasticsearch.index_prefix`: Set the prefix for Elasticsearch indices.
- `.Values.config.extensions.jaeger_storage.backends.primary_store.elasticsearch.host`: Specify the Elasticsearch host.
- `.Values.config.extensions.jaeger_storage.backends.primary_store.elasticsearch.user`: Username for Elasticsearch authentication.
- `.Values.config.extensions.jaeger_storage.backends.primary_store.elasticsearch.password`: Password for Elasticsearch authentication.

Here’s the updated documentation with the archive storage settings referenced and with similar flags specified for archive configurations.


#### **Archive Storage Settings**
- Similar flags for archive configurations can be used to manage archived trace data. 

The `values.yaml` file shows archive configurations under `jaeger_storage` with the `archive_store` section for Elasticsearch. You can configure these with the following flags:

- `.Values.config.extensions.jaeger_storage.backends.archive_store.elasticsearch.index_prefix`
- `.Values.config.extensions.jaeger_storage.backends.archive_store.elasticsearch.server_urls`
- `.Values.config.extensions.jaeger_storage.backends.archive_store.elasticsearch.username`
- `.Values.config.extensions.jaeger_storage.backends.archive_store.elasticsearch.password`

---
