import { FyApi } from "@/services/fyApi";
// import { useI18n } from "@/embed/composables/useI18n";

// const languageHeader = () => {
//   const { i18n } = useI18n();

//   return {
//     "Accept-Language": `${i18n.locale},en;q=0.8`,
//   };
// };

export const useApiClient = () =>
  new FyApi({
    BASE: `${window.API_ENDPOINT}`,
    HEADERS: () =>
      new Promise((resolve) => {
        resolve({
          // ...languageHeader(),
          Accept: "application/json",
          "Content-Type": "application/json",
        });
      }),
  });
