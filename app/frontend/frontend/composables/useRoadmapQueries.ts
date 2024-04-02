import { useApiClient } from "@/frontend/composables/useApiClient";
import { type RoadmapItemQuery } from "@/services/fyApi";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  ROADMAP = "roadmap",
  ROADMAP_SHIPS = "roadmap-ships",
}

export const useRoadmapQueries = () => {
  const { roadmap: roadmapService } = useApiClient();

  const queryClient = useQueryClient();

  const listQuery = (filters: Ref<RoadmapItemQuery>) => {
    return useQuery(
      {
        queryKey: [QueryKeysEnum.ROADMAP],
        queryFn: () =>
          roadmapService.roadmapItems({
            q: filters.value,
          }),
      },
      queryClient,
    );
  };

  return {
    listQuery,
  };
};
