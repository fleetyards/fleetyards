import {
  useCreateVehicle as useCreateVehicleMutation,
  useCreateBulkVehicle as useCreateBulkVehicleMutation,
  useUpdateVehicle as useUpdateVehicleMutation,
  useDestroyVehicle as useDestroyVehicleMutation,
  useUpdateBulkVehicle as useUpdateBulkVehicleMutation,
  useDestroyBulkVehicle as useDestroyBulkVehicleMutation,
  getHangarQueryKey,
  getShowVehicleQueryKey,
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

          const needsInvalidation =
            ("wanted" in data && data.wanted !== vehicleForMutation.wanted) ||
            ("hiddenByUser" in data &&
              data.hiddenByUser !== vehicleForMutation.hiddenByUser) ||
            ("flagship" in data &&
              data.flagship !== vehicleForMutation.flagship) ||
            "hangarGroupIds" in data;

          const updatedVehicle = {
            ...vehicleForMutation,
            ...data,
          };

          const queryData = await getPreviousHangarQueryData();

          if (!queryData?.length) {
            return { needsInvalidation };
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

          return { queryData, needsInvalidation };
        },
        onSuccess: (updatedVehicle, _variables, context) => {
          void invalidateVehiclePage(updatedVehicle);

          if (context?.needsInvalidation) {
            void invalidateHangarQueries();
            return;
          }

          updateVehicleInCache(updatedVehicle);
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

  const updateVehicleInCache = (updatedVehicle: Vehicle) => {
    const queryKeys = [getHangarQueryKey(), getWishlistQueryKey()];

    queryKeys.forEach((queryKey) => {
      queryClient
        .getQueriesData<Hangar>({ queryKey })
        .forEach(([key, data]) => {
          if (!data?.items) return;

          queryClient.setQueryData(key, {
            ...data,
            items: data.items.map((v) => {
              if (v.id === updatedVehicle.id) {
                return updatedVehicle;
              }

              if (v.bundled && v.bundledParent?.id === updatedVehicle.id) {
                return {
                  ...v,
                  bundledParent: {
                    ...v.bundledParent,
                    customName: updatedVehicle.name,
                  },
                };
              }

              return v;
            }),
          });
        });
    });
  };

  // The vehicle page is addressed by id or by serial, so its query is cached
  // under whichever of the two the link carried.
  const invalidateVehiclePage = async (vehicle: Vehicle) => {
    // A page still open under a serial the edit just replaced would refetch
    // into a 404. It takes the answer instead, and the page then moves its
    // address to the vehicle's new one.
    queryClient.setQueriesData<Vehicle>(
      {
        queryKey: getShowVehicleQueryKey(vehicle.id).slice(0, 1),
        predicate: (query) =>
          query.queryKey.length === 2 &&
          (query.state.data as Vehicle | undefined)?.id === vehicle.id,
      },
      (current) => (current ? { ...current, ...vehicle } : current),
    );

    const identifiers = [vehicle.id, vehicle.serial].filter(
      (identifier): identifier is string => !!identifier,
    );

    // Seeded too, so the address the page moves to opens on the answer already
    // in hand instead of a cold fetch that blanks the page.
    identifiers.forEach((identifier) => {
      queryClient.setQueryData<Vehicle>(
        getShowVehicleQueryKey(identifier),
        (current) => ({ ...current, ...vehicle }),
      );
    });

    await Promise.all(
      identifiers.map((identifier) =>
        queryClient.invalidateQueries({
          queryKey: getShowVehicleQueryKey(identifier),
        }),
      ),
    );
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
    invalidateVehiclePage,
    invalidateHangarQueries,
  };
};
