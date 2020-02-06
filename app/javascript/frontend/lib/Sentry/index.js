import Vue from 'vue'
import * as Sentry from '@sentry/browser'
import * as Integrations from '@sentry/integrations'
import Store from 'frontend/lib/Store'

if (window.SENTRY_DSN) {
  Sentry.init({
    environment: window.NODE_ENV,
    release: window.APP_VERSION,
    dsn: window.SENTRY_DSN,
    integrations: [
      new Integrations.Vue({
        Vue,
        attachProps: true,
      }),
    ],
    beforeSend(event) {
      Store.dispatch('sentry/add', event)
    },
  })

  Sentry.configureScope(scope => {
    scope.setTag('appVersion', window.APP_VERSION)
    scope.setTag('appCodename', window.APP_CODENAME)
    scope.setTag('storeVersion', window.STORE_VERSION)
  })
}
