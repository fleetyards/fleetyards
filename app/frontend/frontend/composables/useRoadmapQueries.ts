import { useApiClient } from "@/frontend/composables/useApiClient";
import { RoadmapItem, type RoadmapItemQuery } from "@/services/fyApi";
import {
  type QueryObserverOptions,
  useQuery,
  useQueryClient,
} from "@tanstack/vue-query";

export enum QueryKeysEnum {
  ROADMAP = "roadmap",
  ROADMAP_CHANGES = "roadmap-changes",
  ROADMAP_SHIPS = "roadmap-ships",
  ROADMAP_WEEK_FILTERS = "roadmap-week-filters",
}

export const useRoadmapQueries = () => {
  const { roadmap: roadmapService } = useApiClient();

  const queryClient = useQueryClient();

  const listQuery = (filters: Ref<RoadmapItemQuery>) => {
    return useQuery(
      {
        queryKey: [QueryKeysEnum.ROADMAP, filters],
        queryFn: () =>
          roadmapService.roadmapItems({
            q: filters.value,
          }),
      },
      queryClient,
    );
  };

  const changesQuery = (
    filters: Ref<RoadmapItemQuery | undefined>,
    opts?: Partial<QueryObserverOptions<RoadmapItem[], Error>>,
  ) => {
    return useQuery(
      {
        queryKey: [QueryKeysEnum.ROADMAP_CHANGES],
        queryFn: () =>
          roadmapService.roadmapItems({
            q: filters.value,
          }),
        ...opts,
      },
      queryClient,
    );
  };

  const weeksFilterQuery = () => {
    return useQuery(
      {
        queryKey: [QueryKeysEnum.ROADMAP_WEEK_FILTERS],
        queryFn: () => roadmapService.roadmapWeeks(),
      },
      queryClient,
    );
  };

  return {
    listQuery,
    changesQuery,
    weeksFilterQuery,
  };
};
