import router from "@/frontend/lib/Router";
import { BrowserTracing } from "@sentry/tracing";
import * as Sentry from "@sentry/vue";
import Vue from "vue";

if (window.SENTRY_DSN) {
  Sentry.init({
    Vue,
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
          "fleetyards.dev",
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
