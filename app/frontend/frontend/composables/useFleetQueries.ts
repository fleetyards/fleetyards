import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  FLEET = "fleet",
}

export const useFleetQueries = (slug: string) => {
  const { fleets: fleetsService } = useApiClient();

  const queryClient = useQueryClient();

  const fleetQuery = () => {
    return useQuery(
      {
        queryKey: [QueryKeysEnum.FLEET, slug],
        queryFn: () => fleetsService.fleet({ slug }),
        retry: false,
      },
      queryClient,
    );
  };

  return { fleetQuery };
};
