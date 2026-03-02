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
        onSettled: async () => {
          await invalidateHangarQueries();
        },
      },
    });
  };

  const useCreateBulkMutation = () => {
    return useCreateBulkVehicleMutation({
      mutation: {
        onSettled: async () => {
          await invalidateHangarQueries();
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

            queryClient.setQueryData([queryKey], previousVehicles);
          });
        },
        onSettled: async (_updatedVehicle) => {
          await invalidateHangarQueries();
        },
      },
    });
  };

  const useUpdateBulkMutation = () => {
    return useUpdateBulkVehicleMutation({
      mutation: {
        onSettled: async () => {
          await invalidateHangarQueries();
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

            queryClient.setQueryData(queryKey, {
              ...previousVehicles,
              items: (previousVehicles.items || []).filter((item) => {
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

            queryClient.setQueryData([queryKey], previousVehicles);
          });
        },
        onSettled: async () => {
          await invalidateHangarQueries();
        },
      },
    });
  };

  const useDestroyBulkMutation = () => {
    return useDestroyBulkVehicleMutation({
      mutation: {
        onSettled: async () => {
          await invalidateHangarQueries();
        },
      },
    });
  };

  const invalidateHangarQueries = async () => {
    await queryClient.invalidateQueries({
      queryKey: [getHangarQueryKey()],
    });
    await queryClient.invalidateQueries({
      queryKey: [getWishlistQueryKey()],
    });
  };

  const getPreviousHangarQueryData = async () => {
    await queryClient.cancelQueries({
      queryKey: [getHangarQueryKey()],
    });
    await queryClient.cancelQueries({
      queryKey: [getWishlistQueryKey()],
    });

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
