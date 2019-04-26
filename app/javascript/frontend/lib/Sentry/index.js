import Vue from 'vue'
import * as Sentry from '@sentry/browser'
import * as Integrations from '@sentry/integrations'

Sentry.init({
  release: window.APP_VERSION,
  dsn: window.SENTRY_DSN,
  integrations: [new Integrations.Vue({
    Vue,
    attachProps: true,
  })],
})

Sentry.configureScope((scope) => {
  scope.setTag('appVersion', window.APP_VERSION)
  scope.setTag('appCodename', window.APP_CODENAME)
  scope.setTag('storeVersion', window.STORE_VERSION)
})
