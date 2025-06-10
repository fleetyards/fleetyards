import type { App } from "vue";
import type { Router } from "vue-router";
import * as Sentry from "@sentry/vue";

export default {
  install: (app: App<Element>, router: Router) => {
    if (window.SENTRY_DSN) {
      Sentry.init({
        app,
        environment: window.NODE_ENV,
        release: window.GIT_REVISION,
        dsn: window.SENTRY_DSN,
        integrations: [
          new Sentry.BrowserTracing({
            routingInstrumentation: Sentry.vueRouterInstrumentation(router),
          }),
          new Sentry.Replay(),
        ],
        tracePropagationTargets: [
          "localhost",
          /^https:\/\/fleetyards\.dev/,
          /^https:\/\/fleetyards\.net/,
        ],
        tracesSampleRate: 0.2,
        trackComponents: true,
        replaysSessionSampleRate: 0.1,
        replaysOnErrorSampleRate: 1.0,
      });

      Sentry.configureScope((scope) => {
        scope.setTag("version", window.APP_VERSION);
        scope.setTag("codename", window.APP_CODENAME);
        scope.setTag("store-version", window.STORE_VERSION);
      });
    }
  },
};
