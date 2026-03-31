import {
  useCreateVehicle as useCreateVehicleMutation,
  useCreateBulkVehicle as useCreateBulkVehicleMutation,
  useUpdateVehicle as useUpdateVehicleMutation,
  useDestroyVehicle as useDestroyVehicleMutation,
  useUpdateBulkVehicle as useUpdateBulkVehicleMutation,
  useDestroyBulkVehicle as useDestroyBulkVehicleMutation,
  getHangarQueryKey,
  getWishlistQueryKey,
} from "@/services/fyApi";
import { type Hangar, type Vehicle } from "@/services/fyApi";
import { QueryKey, useQueryClient } from "@tanstack/vue-query";
import { type ComputedRef } from "vue";
import { getPreviousQueryData } from "@/shared/utils/QueryData";

export const useVehicleMutations = () => {
  const queryClient = useQueryClient();

  const useCreateMutation = () => {
    return useCreateVehicleMutation({
      mutation: {
        onSettled: () => {
          void invalidateHangarQueries();
        },
      },
    });
  };

  const useCreateBulkMutation = () => {
    return useCreateBulkVehicleMutation({
      mutation: {
        onSettled: () => {
          void invalidateHangarQueries();
        },
      },
    });
  };

  const useUpdateMutation = (vehicle: ComputedRef<Vehicle>) => {
    if (!vehicle) throw new Error("vehicle is required");

    return useUpdateVehicleMutation({
      mutation: {
        onMutate: async ({ data }) => {
          const vehicleForMutation = unref(vehicle);

          const updatedVehicle = {
            ...vehicleForMutation,
            ...data,
          };

          const queryData = await getPreviousHangarQueryData();

          if (!queryData?.length) {
            return;
          }

          queryData.forEach((query) => {
            const [queryKey, previousVehicles] = query as [QueryKey, Hangar];

            if (!previousVehicles?.items) {
              return;
            }

            queryClient.setQueryData(queryKey, {
              ...previousVehicles,
              items: previousVehicles.items.map((vehicle) => {
                if (vehicle.id === updatedVehicle.id) {
                  return updatedVehicle;
                }

                return vehicle;
              }),
            });
          });

          return { queryData };
        },
        onError: (_error, _variables, context) => {
          if (!context?.queryData) {
            return;
          }

          context.queryData.forEach((query) => {
            const [queryKey, previousVehicles] = query as [QueryKey, Hangar];

            queryClient.setQueryData(queryKey, previousVehicles);
          });
        },
        onSettled: () => {
          void invalidateHangarQueries();
        },
      },
    });
  };

  const useUpdateBulkMutation = () => {
    return useUpdateBulkVehicleMutation({
      mutation: {
        onSettled: () => {
          void invalidateHangarQueries();
        },
      },
    });
  };

  const useDestroyMutation = (vehicle: ComputedRef<Vehicle>) => {
    if (!vehicle) throw new Error("vehicle is required");

    return useDestroyVehicleMutation({
      mutation: {
        onMutate: async () => {
          const vehicleForMutation = unref(vehicle);

          const queryData = await getPreviousHangarQueryData();

          if (!queryData?.length) {
            return;
          }

          queryData.forEach((query) => {
            const [queryKey, previousVehicles] = query as [QueryKey, Hangar];

            if (!previousVehicles?.items) {
              return;
            }

            queryClient.setQueryData(queryKey, {
              ...previousVehicles,
              items: previousVehicles.items.filter((item) => {
                return item.id !== vehicleForMutation.id;
              }),
            });
          });

          return { queryData };
        },
        onError: (_error, _variables, context) => {
          if (!context?.queryData) {
            return;
          }

          context.queryData.forEach((query) => {
            const [queryKey, previousVehicles] = query as [QueryKey, Hangar];

            queryClient.setQueryData(queryKey, previousVehicles);
          });
        },
        onSettled: () => {
          void invalidateHangarQueries();
        },
      },
    });
  };

  const useDestroyBulkMutation = () => {
    return useDestroyBulkVehicleMutation({
      mutation: {
        onSettled: () => {
          void invalidateHangarQueries();
        },
      },
    });
  };

  const invalidateHangarQueries = async () => {
    await Promise.all([
      queryClient.invalidateQueries({
        queryKey: getHangarQueryKey(),
      }),
      queryClient.invalidateQueries({
        queryKey: getWishlistQueryKey(),
      }),
    ]);
  };

  const getPreviousHangarQueryData = async () => {
    await Promise.all([
      queryClient.cancelQueries({
        queryKey: getHangarQueryKey(),
      }),
      queryClient.cancelQueries({
        queryKey: getWishlistQueryKey(),
      }),
    ]);

    return getPreviousQueryData(queryClient, [
      getHangarQueryKey(),
      getWishlistQueryKey(),
    ]);
  };

  return {
    useCreateMutation,
    useCreateBulkMutation,
    useUpdateMutation,
    useDestroyMutation,
    useUpdateBulkMutation,
    useDestroyBulkMutation,
  };
};
