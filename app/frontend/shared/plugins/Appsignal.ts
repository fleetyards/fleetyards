import Appsignal from "@appsignal/javascript";
import { errorHandler } from "@appsignal/vue";
import type { App } from "vue";

let appsignal: Appsignal | null = null;

export function setupAppsignal(app: App<Element>) {
  if (window.APPSIGNAL_KEY) {
    appsignal = new Appsignal({
      key: window.APPSIGNAL_KEY,
      revision: window.GIT_REVISION,
    });

    app.config.errorHandler = errorHandler(appsignal, app);
  }
}
