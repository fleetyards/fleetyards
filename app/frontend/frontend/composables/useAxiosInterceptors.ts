import { useSessionStore } from "@/frontend/stores/session";
import { AXIOS_INSTANCE } from "@/services/axiosClient";
import { useI18n } from "@/shared/composables/useI18n";
import { csrfToken } from "@/shared/utils/Meta";

export const useAxiosInterceptors = () => {
  const { currentLocale } = useI18n();

  AXIOS_INSTANCE.interceptors.request.use((config) => {
    config.headers.set("Accept-Language", `${currentLocale()},en;q=0.8`);
    config.headers.set("X-CSRF-Token", csrfToken());

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
        sessionStore.isAuthenticated
      ) {
        // Only drop the local state. Calling logout() here would send
        // DELETE /sessions, which authenticates via the remember-me cookie before
        // signing out -- so a single stray 401 would consume that cookie and take
        // remember-me with it.
        sessionStore.clearSession();
      }

      return Promise.reject(error);
    },
  );
};
