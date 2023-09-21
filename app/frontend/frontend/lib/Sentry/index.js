import Vue from "vue";
import * as Sentry from "@sentry/vue";
import router from "@/frontend/lib/Router";

if (window.SENTRY_DSN) {
  Sentry.init({
    Vue,
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
