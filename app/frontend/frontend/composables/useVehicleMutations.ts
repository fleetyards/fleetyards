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

export const useVehicleMutations = () => {
  const queryClient = useQueryClient();

  const useCreateMutation = () => {
    return useCreateVehicleMutation({
      mutation: {
        onSettled: () => {
          queryClient.invalidateQueries({
            queryKey: [getHangarQueryKey()],
          });
          queryClient.invalidateQueries({
            queryKey: [getWishlistQueryKey()],
          });
        },
      },
    });
  };

  const useCreateBulkMutation = () => {
    return useCreateBulkVehicleMutation({
      mutation: {
        onSettled: () => {
          queryClient.invalidateQueries({
            queryKey: [getHangarQueryKey()],
          });
          queryClient.invalidateQueries({
            queryKey: [getWishlistQueryKey()],
          });
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
          await queryClient.cancelQueries({
            queryKey: [getHangarQueryKey()],
          });
          const queryData = getPreviousQueryData();

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
        onSettled: (_updatedVehicle) => {
          queryClient.invalidateQueries({
            queryKey: [getHangarQueryKey()],
          });
          queryClient.invalidateQueries({
            queryKey: [getWishlistQueryKey()],
          });
        },
      },
    });
  };

  const useUpdateBulkMutation = () => {
    return useUpdateBulkVehicleMutation({
      mutation: {
        onSettled: () => {
          queryClient.invalidateQueries({
            queryKey: [getHangarQueryKey()],
          });
          queryClient.invalidateQueries({
            queryKey: [getWishlistQueryKey()],
          });
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

          await queryClient.cancelQueries({
            queryKey: [getHangarQueryKey()],
          });

          const queryData = getPreviousQueryData();

          if (!queryData?.length) {
            return;
          }

          queryData.forEach((query) => {
            const [queryKey, previousVehicles] = query as [QueryKey, Hangar];

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

            queryClient.setQueryData([queryKey], previousVehicles);
          });
        },
        onSettled: () => {
          queryClient.invalidateQueries({
            queryKey: [getHangarQueryKey()],
          });
          queryClient.invalidateQueries({
            queryKey: [getWishlistQueryKey()],
          });
        },
      },
    });
  };

  const useDestroyBulkMutation = () => {
    return useDestroyBulkVehicleMutation({
      mutation: {
        onSettled: () => {
          queryClient.invalidateQueries({
            queryKey: [getHangarQueryKey()],
          });
          queryClient.invalidateQueries({
            queryKey: [getWishlistQueryKey()],
          });
        },
      },
    });
  };

  const getPreviousQueryData = () => {
    const results = queryClient.getQueriesData({
      queryKey: getHangarQueryKey(),
    });

    if (results.length === 0) {
      return undefined;
    }

    return results;
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
