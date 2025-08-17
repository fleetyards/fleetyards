import type { App } from "vue";
import * as Sentry from "@sentry/vue";

export default {
  install: (app: App<Element>) => {
    if (window.SENTRY_DSN) {
      Sentry.init({
        app,
        environment: window.NODE_ENV,
        release: window.GIT_REVISION,
        dsn: window.SENTRY_DSN,
        integrations: [
          Sentry.browserTracingIntegration(),
          Sentry.replayIntegration(),
        ],
        tracePropagationTargets: [
          "localhost",
          /^https:\/\/fleetyards\.dev/,
          /^https:\/\/fleetyards\.net/,
        ],
        tracesSampleRate: 0.2,
        replaysSessionSampleRate: 0.1,
        replaysOnErrorSampleRate: 1.0,
      });

      Sentry.getCurrentScope().setTag("version", window.APP_VERSION);
      Sentry.getCurrentScope().setTag("codename", window.APP_CODENAME);
      Sentry.getCurrentScope().setTag("store-version", window.STORE_VERSION);
    }
  },
};
