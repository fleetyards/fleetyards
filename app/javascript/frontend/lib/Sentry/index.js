import * as Sentry from '@sentry/browser'

Sentry.init({
  release: window.APP_VERSION,
  dsn: window.SENTRY_DSN,
  integrations: [new Sentry.Integrations.Vue()],
})

Sentry.configureScope((scope) => {
  scope.setTag('appVersion', window.APP_VERSION)
  scope.setTag('appCodename', window.APP_CODENAME)
  scope.setTag('storeVersion', window.STORE_VERSION)
})
