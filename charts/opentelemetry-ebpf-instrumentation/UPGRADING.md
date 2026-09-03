# Upgrade guidelines

These upgrade guidelines only contain instructions for version upgrades which require manual modifications on the user's side.
If the version you want to upgrade to is not listed here, then there is nothing to do for you.
Just upgrade and enjoy.

## 0.9.3 to 0.9.4

The `tpl` function has been added to `.Values.config.data`. If you are currently using any `{{ }}` syntax in `.Values.config.data` it will now be rendered. To escape existing instances of `{{ }}`, use ``` {{` <original content> `}} ```. For example, `{{ REDACTED_EMAIL }}` becomes ``` {{` {{ REDACTED_EMAIL }} `}} ```.
