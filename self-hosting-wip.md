# Run Fleetyards your self WIP

## Services and Tools Needed

### PostgreSQL Database

Version: >= 10.x

### Redis

Version: >= 6

### Elasticsearch

Version: >= 7

### Memcache

### Any S3 compatible Cloud Storage for Uploads

ENV Variables:

- CARRIERWAVE_CLOUD_KEY
- CARRIERWAVE_CLOUD_SECRET
- CARRIERWAVE_CLOUD_REGION
- CARRIERWAVE_CLOUD_ENDPOINT
- CARRIERWAVE_CLOUD_SPACE
- CARRIERWAVE_CLOUD_CDN_ENDPOINT

### Additional ENV Variables

#### Secrets ideally long random strings ;)

- SECRET_KEY_BASE
- DEVISE_SECRET

#### Contact information used for Mails and Imprint

- MAILER_DEFAULT_FROM

#### Mail Adress to receive Admin Mails

- MAILER_DEFAULT_ADMIN_TO

#### Maintainer Information

- MAINTAINER_NAME
- MAINTAINER_MAIL
- MAINTAINER_ADDRESS_STREET
- MAINTAINER_ADDRESS_POSTALCODE
- MAINTAINER_ADDRESS_CITY
- MAINTAINER_ADDRESS_COUNTRY

#### under which domain should your Fleetyards run? Domain only without protocol - for example fleetyards.net

- DOMAIN

#### Frontend endpoint - basically the domain with protocol - for example https://fleetyards.net

- FRONTEND_ENDPOINT

#### Mailer Settings - best buy an external service for this.

- SMTP_HOST
- SMTP_PORT
- SMTP_USER
- SMTP_PASSWORD

#### Endpoint for the Fleetyards API used by the frontend and third parties for example https://api.fleetyards.net/v1

- API_ENDPOINT

#### Endpoint for the Admin UI - for example: https://admin.fleetyards.net

- ADMIN_ENDPOINT

#### Endpoint for the Admin API - for example: https://admin.fleetyards.net/api/v1

- ADMIN_API_ENDPOINT

#### Endpoint for Websockets like wss://api.fleetyards.net/cable

- CABLE_ENDPOINT

#### your VAT added on sales for the RSI Pledge Store, just leave it blank if there is no VAT added in your country

- RSI_VAT_PERCENT

#### Sentry Bugtracker

- SENTRY_DSN
- SENTRY_FRONTEND_DSN
- SENTRY_CSP_URI
