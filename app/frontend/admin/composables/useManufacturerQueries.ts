import { useApiClient } from "@/admin/composables/useApiClient";
import {
  type ApiError,
  type Manufacturers,
  type Manufacturer,
  type ManufacturerQuery,
} from "@/services/fyAdminApi";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  MANUFACTURERS = "manufacturers",
  MANUFACTURER = "manufacturer",
}

export const useManufacturerQueries = () => {
  const { manufacturers: manufacturersService } = useApiClient();

  const queryClient = useQueryClient();

  const manufacturersQuery = ({
    page,
    perPage,
    filters,
    sorts,
  }: {
    page: ComputedRef<string>;
    perPage: ComputedRef<string | undefined>;
    filters: ComputedRef<ManufacturerQuery | undefined>;
    sorts: ComputedRef<string[] | undefined>;
  }) => {
    return useQuery<Manufacturers, ApiError>(
      {
        queryKey: [QueryKeysEnum.MANUFACTURERS],
        queryFn: () =>
          manufacturersService.manufacturers({
            page: page.value,
            perPage: perPage.value,
            q: filters.value,
            s: sorts.value,
          }),
      },
      queryClient,
    );
  };

  const manufacturerQuery = ({ id }: { id: string }) => {
    return useQuery<Manufacturer, ApiError>(
      {
        queryKey: [QueryKeysEnum.MANUFACTURER, id],
        queryFn: () =>
          manufacturersService.manufacturer({
            id,
          }),
      },
      queryClient,
    );
  };
  return {
    manufacturersQuery,
    manufacturerQuery,
  };
};
