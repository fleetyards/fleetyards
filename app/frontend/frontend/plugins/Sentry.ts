import { BrowserTracing } from "@sentry/browser";
import * as Sentry from "@sentry/vue";
import type { App } from "vue";
import type { Router } from "vue-router";

const setupSentry = (app: App, router: Router) => {
  if (window.SENTRY_DSN) {
    Sentry.init({
      app,
      environment: window.NODE_ENV,
      release: window.GIT_REVISION,
      dsn: window.SENTRY_DSN,
      integrations: [
        new BrowserTracing({
          routingInstrumentation: Sentry.vueRouterInstrumentation(router),
          tracingOrigins: [
            "localhost",
            "fleetyards.test",
            "stage.fleetyards.net",
            "fleetyards.net",
            /^\//,
          ],
        }),
      ],
    });

    Sentry.configureScope((scope) => {
      scope.setTag("version", window.APP_VERSION);
      scope.setTag("codename", window.APP_CODENAME);
      scope.setTag("store-version", window.STORE_VERSION);
    });
  }
};

export default setupSentry;
