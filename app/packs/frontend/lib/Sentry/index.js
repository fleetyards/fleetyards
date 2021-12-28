import Vue from 'vue'
import * as Sentry from '@sentry/browser'
import * as Integrations from '@sentry/integrations'

if (window.SENTRY_DSN) {
  Sentry.init({
    environment: window.NODE_ENV,
    release: window.GIT_REVISION,
    dsn: window.SENTRY_DSN,
    integrations: [
      new Integrations.Vue({
        Vue,
        attachProps: true,
      }),
    ],
  })

  Sentry.configureScope((scope) => {
    scope.setTag('version', window.APP_VERSION)
    scope.setTag('codename', window.APP_CODENAME)
    scope.setTag('store-version', window.STORE_VERSION)
  })
}
