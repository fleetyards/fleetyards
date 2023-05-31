// import type { App } from "vue"; only available in Vue 3
import router from "@/frontend/lib/Router";
import { BrowserTracing } from "@sentry/tracing";
import * as Sentry from "@sentry/vue";

const setupSentry = (app: any) => {
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
