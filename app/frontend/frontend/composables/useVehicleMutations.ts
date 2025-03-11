import {
  useCreateVehicle as useCreateVehicleMutation,
  useCreateBulkVehicle as useCreateBulkVehicleMutation,
  useUpdateVehicle as useUpdateVehicleMutation,
  useUpdateBulkVehicle as useUpdateBulkVehicleMutation,
  useDestroyBulkVehicle as useDestroyBulkVehicleMutation,
  getHangarQueryKey,
  getWishlistQueryKey,
} from "@/services/fyApi";
import { type Hangar, type Vehicle } from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";
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

          const previousVehicles = queryClient.getQueryData([
            getHangarQueryKey(),
          ]) as Hangar;

          queryClient.setQueryData([getHangarQueryKey()], {
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
            [getHangarQueryKey()],
            context?.previousVehicles,
          );
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

  return {
    useCreateMutation,
    useCreateBulkMutation,
    useUpdateMutation,
    useUpdateBulkMutation,
    useDestroyBulkMutation,
  };
};
