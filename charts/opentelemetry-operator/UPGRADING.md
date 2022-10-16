# Upgrade guidelines

## 0.13.0 to 0.14.0

[Allow byo webhooks and cert](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/411)

The ability to use admission webhooks has been moved from `admissionWebhooks.enabled` to `admissionWebhooks.create` as it now supports more use cases.

In order to completely disable admission webhooks you need to explicitly set the environment variable `ENABLE_WEBHOOKS: "false"` in `.Values.manager.env` .
