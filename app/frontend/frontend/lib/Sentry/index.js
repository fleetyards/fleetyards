import Vue from 'vue'
import * as Sentry from '@sentry/browser'
import * as Integrations from '@sentry/integrations'

if (window.SENTRY_DSN) {
  Sentry.init({
    dsn: window.SENTRY_DSN,
    environment: window.NODE_ENV,
    integrations: [
      new Integrations.Vue({
        attachProps: true,
        Vue,
      }),
    ],
    release: window.GIT_REVISION,
  })

  Sentry.configureScope((scope) => {
    scope.setTag('version', window.APP_VERSION)
    scope.setTag('codename', window.APP_CODENAME)
    scope.setTag('store-version', window.STORE_VERSION)
  })
}
