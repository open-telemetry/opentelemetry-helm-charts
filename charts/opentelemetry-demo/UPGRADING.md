# Upgrade guidelines

## To 0.23

The Prometheus sub-chart dependency made updates to pod labels. You may need to
use the `--force` option with your Helm upgrade command, or delete the release
and re-install it.

## To 0.22

This release moves to using the `connectors` functionality in the OpenTelemetry
Collector. The `spanmetrics` processor has been moved to use `connectors`
which results in an additional required exporter in the `traces` pipeline.
Existing releases that override `exporters` in the `traces` pipeline, will
need to add `spanmetrics` to the list of exporters before upgrading. The
OpenTelemetry Collector will fail to start otherwise.

## To 0.21

The deployment labelSelector `app.kubernetes.io/name` has been renamed to
individual workload naming. If you upgrade it from charts <= 0.20, you
will have to delete all existing opentelemetry-demo deployments before running
`helm upgrade` command.

## To 0.20

The `observability.<sub chart>.enabled` parameters have been moved to an
`enabled` parameter within the sub chart itself. If you had changes to these
parameters, you will need to update your changes to work with the new structure.

## To 0.18

The `serviceType` and `servicePort` parameters have been moved under a `service`
parameter with names of `type` and `port` respectively. If you had changes to
these parameters for any demo component, you will need to update your changes
to work with the new structure for the `service` parameter.

## To 0.13

Jaeger was moved to a Helm sub-chart instead of a local chart deployment. If you
had changes specified to the `observability.jaeger` parameter, those changes
will need to be re-implemented as sub-chart parameters under the top level
`jaeger` parameter instead.
