PORT=8270
DOMAIN=fleetyards.test
SHORT_DOMAIN=fltyrd.test
ON_SUBDOMAIN=true
MAILER_DEFAULT_FROM=info@fleetyards.test
DISCORD__CLIENT_ID=op://Fleetyards/DISCORD_OAUTH/client_id
DISCORD__OAUTH_SECRET=op://Fleetyards/DISCORD_OAUTH/credential
# Discord bot token lives alongside it in Rails credentials under
# discord.bot_token; client_id is shared with OAuth login since it's
# the same Discord application.
GITHUB__OAUTH_CLIENT_ID=op://Fleetyards/GITHUB_OAUTH/client_id
GITHUB__OAUTH_SECRET=op://Fleetyards/GITHUB_OAUTH/credential
TWITCH__OAUTH_CLIENT_ID=op://Fleetyards/TWITCH_OAUTH/client_id
TWITCH__OAUTH_SECRET=op://Fleetyards/TWITCH_OAUTH/credential
GOOGLE__OAUTH_CLIENT_ID=op://Fleetyards/GOOGLE_OAUTH/client_id
GOOGLE__OAUTH_SECRET=op://Fleetyards/GOOGLE_OAUTH/credential
CITIZENID__OAUTH_CLIENT_ID=op://Fleetyards/CITIZENID_OAUTH/client_id
