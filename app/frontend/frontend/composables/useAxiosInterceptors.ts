import { useSessionStore } from "@/frontend/stores/session";
import { AXIOS_INSTANCE } from "@/services/axiosClient";
import { useI18n } from "@/shared/composables/useI18n";
import { csrfToken } from "@/shared/utils/Meta";

export const useAxiosInterceptors = () => {
  const { currentLocale } = useI18n();

  AXIOS_INSTANCE.interceptors.request.use((config) => {
    config.headers["common"] = {
      ...config.headers["common"],
      "Accept-Language": `${currentLocale()},en;q=0.8`,
      "X-CSRF-Token": csrfToken(),
    };

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
        sessionStore.logout();
      }

      return Promise.reject(error);
    },
  );
};
