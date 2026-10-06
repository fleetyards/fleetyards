import {
  currentSessionEpoch,
  useSessionStore,
} from "@/frontend/stores/session";
import { AXIOS_INSTANCE } from "@/services/axiosClient";
import { useI18n } from "@/shared/composables/useI18n";
import { csrfToken } from "@/shared/utils/Meta";

declare module "axios" {
  interface InternalAxiosRequestConfig {
    sessionEpoch?: number;
  }
}

export const useAxiosInterceptors = () => {
  const { currentLocale } = useI18n();

  AXIOS_INSTANCE.interceptors.request.use((config) => {
    config.headers.set("Accept-Language", `${currentLocale()},en;q=0.8`);
    config.headers.set("X-CSRF-Token", csrfToken());
    config.sessionEpoch = currentSessionEpoch();

    return config;
  });

  AXIOS_INSTANCE.interceptors.response.use(
    (response) => {
      return response;
    },
    (error) => {
      const sessionStore = useSessionStore();

      if (
        error.response &&
        error.response.status === 401 &&
        sessionStore.isAuthenticated &&
        error.config?.sessionEpoch === currentSessionEpoch()
      ) {
        // Only drop the local state. Calling logout() here would send
        // DELETE /sessions, which authenticates via the remember-me cookie before
        // signing out -- so a single stray 401 would consume that cookie and take
        // remember-me with it.
        //
        // A 401 for a request sent under an earlier session says nothing about
        // this one: an expired session's requests still in flight when the user
        // signs in would otherwise throw them straight back to the login page.
        sessionStore.clearSession();
      }

      return Promise.reject(error);
    },
  );
};
