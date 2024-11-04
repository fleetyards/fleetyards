import { FyApi } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import axios from "axios";
import { useSessionStore } from "@/frontend/stores/session";

const languageHeader = () => {
  const { currentLocale } = useI18n();

  return {
    "Accept-Language": `${currentLocale()},en;q=0.8`,
  };
};

axios.interceptors.response.use(
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

const apiClient = new FyApi({
  BASE: `${window.API_ENDPOINT}`,
  WITH_CREDENTIALS: true,
  HEADERS: () =>
    new Promise((resolve) => {
      resolve({
        ...languageHeader(),
        Accept: "application/json",
        "Content-Type": "application/json",
      });
    }),
});

export const useApiClient = () => apiClient;
