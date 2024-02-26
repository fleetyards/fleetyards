import { useApiClient } from "@/frontend/composables/useApiClient";
import { type HangarQuery } from "@/services/fyApi";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export const useHangarQueries = () => {
  const {
    hangar: hangarService,
    hangarStats: hangarStatsService,
    hangarGroups: hangarGroupsService,
  } = useApiClient();

  const queryClient = useQueryClient();

  const hangarQuery = (
    filters: Ref<HangarQuery>,
    page: Ref<string>,
    perPage: Ref<string | undefined>,
  ) => {
    return useQuery(
      {
        refetchOnWindowFocus: false,
        queryKey: ["vehicles"],
        queryFn: () => {
          return hangarService.hangar({
            q: filters.value,
            page: page.value,
            perPage: perPage.value,
          });
        },
      },
      queryClient,
    );
  };

  const statsQuery = (filters: Ref<HangarQuery>) => {
    return useQuery(
      {
        queryKey: ["hangarStats"],
        queryFn: () =>
          hangarStatsService.hangarStats({
            q: filters.value,
          }),
      },
      queryClient,
    );
  };

  const groupsQuery = () => {
    return useQuery(
      {
        queryKey: ["hangarGroups"],
        queryFn: () => hangarGroupsService.hangarGroups(),
      },
      queryClient,
    );
  };

  return {
    hangarQuery,
    statsQuery,
    groupsQuery,
  };
};
