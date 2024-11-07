import { useApiClient } from "@/admin/composables/useApiClient";
import {
  type ApiError,
  type Vehicles,
  type VehicleQuery,
} from "@/services/fyAdminApi";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  VEHICLES = "vehicles",
}

export const useVehicleQueries = () => {
  const { vehicles: vehiclesService } = useApiClient();

  const queryClient = useQueryClient();

  const vehiclesQuery = ({
    page,
    perPage,
    filters,
    sorts,
  }: {
    page: ComputedRef<string>;
    perPage: ComputedRef<string | undefined>;
    filters: ComputedRef<VehicleQuery | undefined>;
    sorts: ComputedRef<string[] | undefined>;
  }) => {
    return useQuery<Vehicles, ApiError>(
      {
        queryKey: [QueryKeysEnum.VEHICLES],
        queryFn: () =>
          vehiclesService.vehicles({
            page: page.value,
            perPage: perPage.value,
            q: filters.value,
            s: sorts.value,
          }),
      },
      queryClient,
    );
  };

  return {
    vehiclesQuery,
  };
};
