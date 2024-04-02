import { useApiClient } from "@/frontend/composables/useApiClient";
import {
  type FilterOption,
  type HangarGroup,
  type HangarQuery,
} from "@/services/fyApi";
import { type FilterGroupParams } from "@/shared/components/base/FilterGroup/index.vue";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  HANGAR = "hangar",
  HANGAR_STATS = "hangarStats",
  HANGAR_GROUPS = "hangarGroups",
}

export const useHangarQueries = () => {
  const {
    hangar: hangarService,
    hangarStats: hangarStatsService,
    hangarGroups: hangarGroupsService,
    vehicles: vehiclesService,
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
        queryKey: [QueryKeysEnum.HANGAR, page],
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
        queryKey: [QueryKeysEnum.HANGAR_STATS],
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
        queryKey: [QueryKeysEnum.HANGAR_GROUPS],
        queryFn: () => hangarGroupsService.hangarGroups(),
      },
      queryClient,
    );
  };

  const groupsFilterQuery = (_params: FilterGroupParams) => {
    return hangarGroupsService.hangarGroups();
  };

  const groupsFilterFormatter = (groups: HangarGroup[]) => {
    return groups.map((group) => ({
      label: group.name,
      value: group.id,
    }));
  };

  const boughtViaFilterQuery = (_params: FilterGroupParams) => {
    return vehiclesService.boughtViaFilters();
  };

  return {
    hangarQuery,
    statsQuery,
    groupsQuery,
    groupsFilterQuery,
    groupsFilterFormatter,
    boughtViaFilterQuery,
  };
};
