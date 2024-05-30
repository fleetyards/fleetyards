import { FyApi } from "@/services/fyApi";

export const useApiClient = () =>
  new FyApi({
    BASE: `${window.API_ENDPOINT}`,
    HEADERS: () =>
      new Promise((resolve) => {
        resolve({
          Accept: "application/json",
          "Content-Type": "application/json",
        });
      }),
  });
