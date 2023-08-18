import { FyAdminApi } from "@/services/fyAdminApi";

export const useApiClient = () =>
  new FyAdminApi({
    BASE: `${window.ADMIN_API_ENDPOINT}`,
    WITH_CREDENTIALS: true,
    HEADERS: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
  });
