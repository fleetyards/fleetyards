import Vue from "vue";
import * as Sentry from "@sentry/vue";

if (window.SENTRY_DSN) {
  Sentry.init({
    Vue,
    environment: window.NODE_ENV,
    release: window.GIT_REVISION,
    dsn: window.SENTRY_DSN,
    integrations: [
      Sentry.browserTracingIntegration(),
      Sentry.consoleLoggingIntegration({ levels: ["log", "warn", "error"] }),
    ],
    tracePropagationTargets: [
      "localhost",
      /^https:\/\/fleetyards\.dev/,
      /^https:\/\/fleetyards\.net/,
    ],
    tracesSampleRate: 0.2,
    trackComponents: true,
    enableLogs: true,
    initialScope: {
      tags: {
        version: window.APP_VERSION,
        codename: window.APP_CODENAME,
        "store-version": window.STORE_VERSION,
      },
    },
  });
}
