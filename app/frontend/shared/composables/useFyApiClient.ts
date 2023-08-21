import { FyApi } from "@/services/fyApi";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export const useFyApiClient = (
  currentLocale: I18nPluginOptions["currentLocale"]
) =>
  new FyApi({
    BASE: `${window.API_ENDPOINT}`,
    WITH_CREDENTIALS: true,
    HEADERS: () =>
      new Promise((resolve) => {
        resolve({
          "Accept-Language": `${currentLocale()},en;q=0.8`,
          Accept: "application/json",
          "Content-Type": "application/json",
        });
      }),
  });
