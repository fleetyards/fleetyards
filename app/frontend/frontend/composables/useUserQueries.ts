import { useApiClient } from "@/frontend/composables/useApiClient";
import { type HangarQuery } from "@/services/fyApi";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  PUBLIC_HANGAR = "publicHangar",
}

export const usePublicHangarQueries = (username: string) => {
  const { publicHangar: publicHangarService } = useApiClient();

  const queryClient = useQueryClient();

  const publicHangarQuery = ({
    page,
    perPage,
    filters,
  }: {
    page: ComputedRef<string>;
    perPage: ComputedRef<string | undefined>;
    filters: ComputedRef<HangarQuery | undefined>;
  }) => {
    return useQuery(
      {
        refetchOnWindowFocus: false,
        queryKey: [
          QueryKeysEnum.PUBLIC_HANGAR,
          username,
          page,
          perPage,
          filters,
        ],
        queryFn: () => {
          return publicHangarService.publicHangar({
            username,
            page: page.value,
            perPage: perPage.value,
            q: filters.value,
          });
        },
      },
      queryClient,
    );
  };

  return {
    publicHangarQuery,
  };
};
