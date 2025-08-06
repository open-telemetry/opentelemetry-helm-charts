# No leader election extension example
This example contains files to allow a user to use 2 different collectors to monitor the cluster metrics and k8s api info when leader election extension is not an option (because the collector compillation doesn't include it or because of RBAC limitations). 
This can be done configuring a second collector to host the receivers and setting `disableLeaderElection: true` for `kubernetesEvents` and `clusterMetrics` presets.

**Disclaimer**: This setup is functional but k8s API metrics and events receivers **ARE NOT in a High Availability** configuration as both run as part of a second collector deployed as `deployment` with single replica to avoid the necessity of using leader election in any way.