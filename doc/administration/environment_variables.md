---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Environment variables **(FREE SELF)**

GitLab exposes certain environment variables which can be used to override
their defaults values.

People usually configure GitLab with `/etc/gitlab/gitlab.rb` for Omnibus
installations, or `gitlab.yml` for installations from source.

You can use the following environment variables to override certain values:

## Supported environment variables

| Variable                                   | Type    | Description                                                                                             |
|--------------------------------------------|---------|---------------------------------------------------------------------------------------------------------|
| `DATABASE_URL`                             | string  | The database URL; is of the form: `postgresql://localhost/blog_development`.                            |
| `ENABLE_BOOTSNAP`                          | string  | Toggles [Bootsnap](https://github.com/Shopify/bootsnap) for speeding up initial Rails boot. Enabled by default for non-production environments. Set to `0` to disable. |
| `EXTERNAL_URL`                             | string  | Specify the external URL at the [time of installation](https://docs.gitlab.com/omnibus/settings/configuration.html#specifying-the-external-url-at-the-time-of-installation). |
| `EXTERNAL_VALIDATION_SERVICE_TIMEOUT`      | integer | Timeout, in seconds, for an [external CI/CD pipeline validation service](external_pipeline_validation.md). Default is `5`. |
| `EXTERNAL_VALIDATION_SERVICE_URL`          | string  | URL to an [external CI/CD pipeline validation service](external_pipeline_validation.md).                |
| `EXTERNAL_VALIDATION_SERVICE_TOKEN`        | string  | The `X-Gitlab-Token` for authentication with an [external CI/CD pipeline validation service](external_pipeline_validation.md). |
| `GITLAB_CDN_HOST`                          | string  | Sets the base URL for a CDN to serve static assets (for example, `https://mycdnsubdomain.fictional-cdn.com`). |
| `GITLAB_EMAIL_DISPLAY_NAME`                | string  | The name used in the **From** field in emails sent by GitLab.                                           |
| `GITLAB_EMAIL_FROM`                        | string  | The email address used in the **From** field in emails sent by GitLab.                                  |
| `GITLAB_EMAIL_REPLY_TO`                    | string  | The email address used in the **Reply-To** field in emails sent by GitLab.                              |
| `GITLAB_EMAIL_SUBJECT_SUFFIX`              | string  | The email subject suffix used in emails sent by GitLab.                                                 |
| `GITLAB_HOST`                              | string  | The full URL of the GitLab server (including `http://` or `https://`).                                  |
| `GITLAB_MARKUP_TIMEOUT`                    | string  | Timeout, in seconds, for `rest2html` and `pod2html` commands executed by the [`gitlab-markup` gem](https://gitlab.com/gitlab-org/gitlab-markup/). Default is `10`. |
| `GITLAB_ROOT_PASSWORD`                     | string  | Sets the password for the `root` user on installation.                                                  |
| `GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN` | string  | Sets the initial registration token used for runners.                                                   |
| `RAILS_ENV`                                | string  | The Rails environment; can be one of `production`, `development`, `staging`, or `test`.                 |
| `UNSTRUCTURED_RAILS_LOG`                   | string  | Enables the unstructured log in addition to JSON logs (defaults to `true`).                             |
| `GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS` | integer | The default TTL used for entries stored in the Rails-cache. Default is `28800`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95042) in 15.3. |

## Adding more variables

We welcome merge requests to make more settings configurable by using variables.
Make changes to the `config/initializers/1_settings.rb` file, and use the
naming scheme `GITLAB_#{name in 1_settings.rb in upper case}`.

## Omnibus configuration

To set environment variables, follow [these instructions](https://docs.gitlab.com/omnibus/settings/environment-variables.html).

It's possible to preconfigure the GitLab Docker image by adding the environment
variable `GITLAB_OMNIBUS_CONFIG` to the `docker run` command.
For more information, see the [Pre-configure Docker container](https://docs.gitlab.com/omnibus/docker/#pre-configure-docker-container)
section of the Omnibus GitLab documentation.
