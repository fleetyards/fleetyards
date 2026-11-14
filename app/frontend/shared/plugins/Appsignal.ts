import Appsignal from "@appsignal/javascript";
import { errorHandler } from "@appsignal/vue";
import axios from "axios";
import type { App } from "vue";

let appsignal: Appsignal | null = null;

// A fragment, as three prefixes the message and words it per failure.
const IGNORED_MESSAGES = [/Error creating WebGL context/];

function shouldIgnore(error: unknown): boolean {
  if (axios.isCancel(error)) return true;

  if (axios.isAxiosError(error)) {
    if (error.code === "ERR_CANCELED" || error.code === "ECONNABORTED") {
      return true;
    }
  }

  return false;
}

// Chrome's translator marks the root, Edge's every node it rewrote. A
// translated page has its text swapped under Vue, whose next patch then fails
// on nodes that are gone.
const pageTranslated = () =>
  /\btranslated-(ltr|rtl)\b/.test(document.documentElement.className) ||
  !!document.querySelector("[_msttexthash]");

const routeName = (app: App<Element>) =>
  String(app.config.globalProperties.$router?.currentRoute.value.name ?? "");

export function setupAppsignal(app: App<Element>) {
  if (window.APPSIGNAL_KEY) {
    appsignal = new Appsignal({
      key: window.APPSIGNAL_KEY,
      revision: window.GIT_REVISION,
      ignoreErrors: IGNORED_MESSAGES,
    });

    appsignal.addDecorator((span) =>
      span.setTags({
        route: routeName(app),
        page_translated: String(pageTranslated()),
      }),
    );

    const defaultHandler = errorHandler(appsignal, app);

    app.config.errorHandler = (error, vm, info) => {
      if (shouldIgnore(error)) return;

      if (appsignal && axios.isAxiosError(error)) {
        const method = error.config?.method?.toUpperCase() ?? "?";
        const url = error.config?.url ?? "unknown";
        void appsignal.sendError(error, (span) => {
          span.setAction(`${method} ${url}`);
          span.setTags({
            request_method: method,
            request_url: url,
            request_base_url: error.config?.baseURL ?? "",
            response_status: String(error.response?.status ?? ""),
            error_code: error.code ?? "",
            vue_info: info,
          });
        });
        return;
      }

      defaultHandler(error, vm, info);
    };
  }
}

// For failures a component handles itself, which never reach the error handler.
export function reportError(error: unknown, action?: string) {
  if (shouldIgnore(error)) return;

  if (!appsignal) {
    console.error(error);
    return;
  }

  const reported = error instanceof Error ? error : new Error(String(error));

  void appsignal.sendError(reported, (span) => {
    if (action) span.setAction(action);
  });
}
