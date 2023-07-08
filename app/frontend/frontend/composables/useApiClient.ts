import { FyApi } from "@/services/fyApi";
import { useI18n } from "@/frontend/composables/useI18n";

const languageHeader = () => {
  const { I18n } = useI18n();

  return {
    "Accept-Language": `${I18n.currentLocale()},en;q=0.8`,
  };
};

export const useApiClient = () =>
  new FyApi({
    BASE: `${window.API_ENDPOINT}`,
    WITH_CREDENTIALS: true,
    HEADERS: () =>
      new Promise((resolve) => {
        resolve({
          ...languageHeader(),
        });
      }),
  });
