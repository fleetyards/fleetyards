import { useQuery } from "@tanstack/vue-query";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useI18n } from "@/frontend/composables/useI18n";

export const useFleetQuery = (fleetSlug: string) => {
  const { currentLocale } = useI18n();

  const { fleets: fleetsService } = useApiClient();

  const { data: fleet, ...asyncStatus } = useQuery({
    queryKey: ["fleet", fleetSlug],
    retry: false,
    queryFn: () =>
      fleetsService.fleet({
        slug: fleetSlug,
      }),
  });

  return {
    fleet,
    asyncStatus,
  };
};
