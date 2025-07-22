import {
  useCreateVehicle as useCreateVehicleMutation,
  useCreateBulkVehicle as useCreateBulkVehicleMutation,
  useUpdateVehicle as useUpdateVehicleMutation,
  useDestroyVehicle as useDestroyVehicleMutation,
  useUpdateBulkVehicle as useUpdateBulkVehicleMutation,
  useDestroyBulkVehicle as useDestroyBulkVehicleMutation,
  useHangarQueryOptions,
  useWishlistQueryOptions,
} from "@/services/fyApi";
import { type CustomQueryOptions } from "@/services/customQueryOptions";
import { type Hangar, type Vehicle } from "@/services/fyApi";
import { QueryKey, useQueryClient } from "@tanstack/vue-query";
import { type ComputedRef } from "vue";
import { getPreviousQueryData } from "@/shared/utils/QueryData";

export const useVehicleMutations = () => {
  const queryClient = useQueryClient();

  const hangarQueryOptions = useHangarQueryOptions() as CustomQueryOptions;
  const wishlistQueryOptions = useWishlistQueryOptions() as CustomQueryOptions;

  const useCreateMutation = () => {
    return useCreateVehicleMutation({
      mutation: {
        onSettled: () => {
          invalidateHangarQueries();
        },
      },
    });
  };

  const useCreateBulkMutation = () => {
    return useCreateBulkVehicleMutation({
      mutation: {
        onSettled: () => {
          invalidateHangarQueries();
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
        onSettled: (_updatedVehicle) => {
          invalidateHangarQueries();
        },
      },
    });
  };

  const useUpdateBulkMutation = () => {
    return useUpdateBulkVehicleMutation({
      mutation: {
        onSettled: () => {
          invalidateHangarQueries();
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
          invalidateHangarQueries();
        },
      },
    });
  };

  const useDestroyBulkMutation = () => {
    return useDestroyBulkVehicleMutation({
      mutation: {
        onSettled: () => {
          invalidateHangarQueries();
        },
      },
    });
  };

  const invalidateHangarQueries = () => {
    queryClient.invalidateQueries({
      queryKey: [hangarQueryOptions.queryKey],
    });
    queryClient.invalidateQueries({
      queryKey: [wishlistQueryOptions.queryKey],
    });
  };

  const getPreviousHangarQueryData = async () => {
    await queryClient.cancelQueries({
      queryKey: [hangarQueryOptions.queryKey],
    });
    await queryClient.cancelQueries({
      queryKey: [wishlistQueryOptions.queryKey],
    });

    return getPreviousQueryData(queryClient, [
      hangarQueryOptions.queryKey,
      wishlistQueryOptions.queryKey,
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
