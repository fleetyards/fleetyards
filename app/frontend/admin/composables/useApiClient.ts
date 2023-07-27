import { FyAdminApi } from "@/services/fyAdminApi";
import { useI18n } from "@/admin/composables/useI18n";
import { csrfToken } from "@/shared/utils/Meta";

const languageHeader = () => {
  const { currentLocale } = useI18n();

  return {
    "Accept-Language": `${currentLocale()},en;q=0.8`,
  };
};

export const useApiClient = () =>
  new FyAdminApi({
    BASE: `${window.API_ENDPOINT}`,
    WITH_CREDENTIALS: true,
    HEADERS: () => {
      return new Promise((resolve) => {
        resolve({
          ...languageHeader(),
          "X-CSRF-Token": csrfToken(),
          Accept: "application/json",
          "Content-Type": "application/json",
        });
      });
    },
  });
