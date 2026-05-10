import Appsignal from "@appsignal/javascript";
import { errorHandler } from "@appsignal/vue";
import axios from "axios";
import type { App } from "vue";

let appsignal: Appsignal | null = null;

const IGNORED_MESSAGES = new Set(["Error creating WebGL context."]);

function shouldIgnore(error: unknown): boolean {
  if (axios.isCancel(error)) return true;

  if (axios.isAxiosError(error)) {
    if (error.code === "ERR_CANCELED" || error.code === "ECONNABORTED") {
      return true;
    }
  }

  if (error instanceof Error && IGNORED_MESSAGES.has(error.message)) {
    return true;
  }

  return false;
}

export function setupAppsignal(app: App<Element>) {
  if (window.APPSIGNAL_KEY) {
    appsignal = new Appsignal({
      key: window.APPSIGNAL_KEY,
      revision: window.GIT_REVISION,
    });

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
