import { useApiClient } from "@/frontend/composables/useApiClient";
import {
  type Hangar,
  type Vehicle,
  type VehicleCreateInput,
  type VehicleUpdateInput,
  type VehicleBulkUpdateInput,
  type VehicleBulkDestroyInput,
} from "@/services/fyApi";
import { useMutation, useQuery, useQueryClient } from "@tanstack/vue-query";
import { QueryKeysEnum as HangarQueryKeysEnum } from "@/frontend/composables/useHangarQueries";

export enum QueryKeysEnum {
  VEHICLE = "vehicle",
  FILTERS_BOUGHT_VIA = "filtersBoughtVia",
}

export const useVehicleQueries = (vehicle?: Vehicle) => {
  const { vehicles: vehiclesService } = useApiClient();

  const queryClient = useQueryClient();

  const createMutation = () => {
    return useMutation(
      {
        mutationFn: (requestBody: VehicleCreateInput) => {
          return vehiclesService.vehicleCreate({ requestBody });
        },
        onSettled: () => {
          queryClient.invalidateQueries({
            queryKey: [HangarQueryKeysEnum.HANGAR],
          });
          queryClient.invalidateQueries({
            queryKey: ["wishlist"],
          });
        },
      },
      queryClient,
    );
  };

  const createBulkMutation = () => {
    return useMutation(
      {
        mutationFn: (requestBody: VehicleCreateInput[]) => {
          if (requestBody.length === 0) {
            return Promise.resolve();
          }

          return new Promise((resolve, reject) => {
            const promises = requestBody.map((vehicle) => {
              return vehiclesService.vehicleCreate({ requestBody: vehicle });
            });

            Promise.all(promises)
              .then(() => {
                resolve(undefined);
              })
              .catch((error) => {
                reject(error);
              });
          });
        },
        onSettled: () => {
          queryClient.invalidateQueries({
            queryKey: [HangarQueryKeysEnum.HANGAR],
          });
          queryClient.invalidateQueries({
            queryKey: ["wishlist"],
          });
        },
      },
      queryClient,
    );
  };

  const updateMutation = () => {
    if (!vehicle) throw new Error("vehicle is required");

    return useMutation(
      {
        mutationFn: (requestBody: VehicleUpdateInput) => {
          return vehiclesService.vehicleUpdate({
            id: vehicle.id,
            requestBody,
          });
        },
        onMutate: async (input: VehicleUpdateInput) => {
          const updatedVehicle = {
            ...vehicle,
            ...input,
          };
          await queryClient.cancelQueries({
            queryKey: [HangarQueryKeysEnum.HANGAR],
          });

          const previousVehicles = queryClient.getQueryData([
            HangarQueryKeysEnum.HANGAR,
          ]) as Hangar;

          queryClient.setQueryData([HangarQueryKeysEnum.HANGAR], {
            ...previousVehicles,
            items: previousVehicles.items.map((vehicle) => {
              if (vehicle.id === updatedVehicle.id) {
                return updatedVehicle;
              }

              return vehicle;
            }),
          });

          return { previousVehicles };
        },
        onError: (_error, _updatedVehicle, context) => {
          queryClient.setQueryData(
            [HangarQueryKeysEnum.HANGAR],
            context?.previousVehicles,
          );
        },
        onSettled: (updatedVehicle) => {
          queryClient.invalidateQueries({
            queryKey: [QueryKeysEnum.VEHICLE, updatedVehicle?.id],
          });
          queryClient.invalidateQueries({
            queryKey: [HangarQueryKeysEnum.HANGAR],
          });
          queryClient.invalidateQueries({
            queryKey: ["wishlist"],
          });
        },
      },
      queryClient,
    );
  };

  const boughtViaFiltersQuery = () => {
    return useQuery(
      {
        queryKey: [QueryKeysEnum.FILTERS_BOUGHT_VIA],
        queryFn: async () => {
          return vehiclesService.boughtViaFilters();
        },
      },
      queryClient,
    );
  };

  const updateBulkMutation = () => {
    return useMutation(
      {
        mutationFn: (requestBody: VehicleBulkUpdateInput) => {
          return vehiclesService.vehicleUpdateBulk({ requestBody });
        },
        onSettled: () => {
          queryClient.invalidateQueries({
            queryKey: [HangarQueryKeysEnum.HANGAR],
          });
          queryClient.invalidateQueries({
            queryKey: ["wishlist"],
          });
        },
      },
      queryClient,
    );
  };

  const destroyBulkMutation = () => {
    return useMutation(
      {
        mutationFn: (requestBody: VehicleBulkDestroyInput) => {
          return vehiclesService.vehicleDestroyBulk({ requestBody });
        },
        onSettled: () => {
          queryClient.invalidateQueries({
            queryKey: [HangarQueryKeysEnum.HANGAR],
          });
          queryClient.invalidateQueries({
            queryKey: ["wishlist"],
          });
        },
      },
      queryClient,
    );
  };

  return {
    createMutation,
    createBulkMutation,
    updateMutation,
    boughtViaFiltersQuery,
    updateBulkMutation,
    destroyBulkMutation,
  };
};
