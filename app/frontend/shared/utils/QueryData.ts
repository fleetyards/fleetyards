import { type QueryClient } from "@tanstack/vue-query";

/* eslint-disable @typescript-eslint/no-explicit-any */
export const getPreviousQueryData = (
  queryClient: QueryClient,
  queryKeys: any[],
) => {
  return queryKeys
    .map((queryKey) => {
      return queryClient.getQueriesData({
        queryKey,
      });
    })
    .flat();
};
/* eslint-enable @typescript-eslint/no-explicit-any */
