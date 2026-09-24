# Kamal Secrets from 1Password

**Date:** 2026-09-24

Deploy secrets are read from 1Password by `op read` inside `.kamal/secrets-common`, `.kamal/secrets.live` and `.kamal/secrets.stage`; CI holds only a 1Password service-account token. These are the traps hit while setting that up, which are not obvious from the Kamal or 1Password docs.

## Kamal parses secrets files with Dotenv, not bash

The secrets files look like shell, but Kamal loads them with Dotenv. Command substitution (`$(op read ...)`) works; the shell environment does not. In particular `$DESTINATION` is not available, so a shared file cannot branch per environment.

Per-environment values therefore go in `secrets.live` / `secrets.stage`, and `secrets-common` holds only what is genuinely identical everywhere (the S3 credentials). Values derived from other secrets, such as `DATABASE_URL` and `REDIS_URL`, are computed in the per-environment file.

## Expand `${DESTINATION}_user`, not `$DESTINATION_user`

Where a variable is expanded (the CI shell, helper scripts), `$DESTINATION_user` is parsed as one variable named `DESTINATION_user` and expands to nothing. Brace it: `${DESTINATION}_user`.

## 1Password field names must not clash with built-in fields

Some item categories come with built-in fields. A "Login" item already has `username` (and `password`); adding a custom field with the same label makes `op://vault/item/username` ambiguous, and `op read` fails with an ambiguity error instead of picking one. Give custom fields distinct labels, or use the built-in field.

## `HCLOUD_TOKEN` must be exported before `kamal` runs

`config/deploy*.yml` is ERB, and it shells out to `.kamal/server-ips`, which calls `hcloud` to resolve server addresses. Kamal evaluates that ERB before it loads any secrets file, so an `HCLOUD_TOKEN` defined in `secrets.*` is not yet set when `hcloud` runs. The deploy workflow exports it with `op read` in the shell first, then invokes `kamal`; the local `bin/*-live` / `bin/setup-*` wrappers do the same. Any new entry point that runs `kamal` needs that export too.
