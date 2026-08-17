# Fleetyards.net

A Ship Database and Web API based on the official [Star Citizen Ship Matrix](https://robertsspaceindustries.com/ship-specs).

Powered by [Ruby on Rails 6.x](https://rubyonrails.org/) and [VueJS 2.x](https://vuejs.org/)

[![GPLv3 License](https://img.shields.io/badge/License-GPL%20v3-yellow.svg)](https://opensource.org/licenses/) [![Main](https://github.com/fleetyards/fleetyards/actions/workflows/main.yml/badge.svg)](https://github.com/fleetyards/fleetyards/actions/workflows/main.yml) [![Depfu](https://badges.depfu.com/badges/6bd2aaec84d0fb22bd1fb30d0b810ee2/status.svg)](https://depfu.com)

## Feedback

If you have any feedback, please reach out on the [Fleetyards.net Discord](https://discord.gg/YdeAdEaTpb) or contact me via info@fleetyards.net
  
## License

[GPLv3](https://choosealicense.com/licenses/gpl-3.0/)
  
## Development Setup

### Prerequisites

- [1Password CLI](https://developer.1password.com/docs/cli/get-started/) (`brew install 1password-cli`)
- Access to the **Fleetyards** vault in 1Password

### Getting Started

```bash
bin/setup
bin/dev
```

Secrets are injected at runtime via `op run` from `.env.tpl` — nothing is written to disk. Worktree overrides (ports, DB suffix) go in `.env.local`.

### Editing Rails Credentials

```bash
bin/credentials production
bin/credentials staging
```

### Optional Integrations

#### Patreon Supporter Sync

A nightly Sidekiq job (`PatreonSupporterSyncJob`, 04:17 UTC) imports active
Patreon patrons into the `supporter_contributions` table so the public progress
bar reflects ongoing pledges. Imported rows default to `anonymous: true` until an
admin flips them after getting the supporter's consent. Admins can also trigger
an immediate run via the "Sync from Patreon" button on the admin Supporter
Contributions page.

The integration is one-way (Patreon → FleetYards) and disabled until the
following credentials are set:

```yaml
patreon:
  access_token: <creator-access-token> # from your Patreon creator dashboard
  campaign_id: <campaign-id>           # GET /api/oauth2/v2/identity?include=campaign
```

USD pledge amounts are converted to EUR at sync time using the free
[Frankfurter](https://frankfurter.app) ECB rate, cached for 12h and snapshotted
to the `exchange_rates` table as a fallback when the rate API is unreachable. No
extra credentials are required for the exchange-rate lookup.

When a sync creates a brand-new active patron, the team is notified by email
(super admins) and via a Discord webhook. The Discord post is sent to an internal
channel and is skipped unless its webhook is configured:

```yaml
discord_admin_endpoint: <discord-webhook-url>
```

The email always sends; only the Discord half depends on this credential.

## Authors and Acknowledgement

- [@mortik](https://www.github.com/mortik) for development and design.

## Support

- [Buy me a Coffee](https://www.buymeacoffee.com/mortik)
- [Patreon](https://www.patreon.com/fleetyards)
- [PayPal](https://paypal.me/pools/c/83jQLadz60)
