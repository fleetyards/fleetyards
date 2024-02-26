import { useApiClient } from "@/frontend/composables/useApiClient";
import {
  type Hangar,
  type Vehicle,
  type VehicleUpdateInput,
} from "@/services/fyApi";
import { useMutation, useQuery, useQueryClient } from "@tanstack/vue-query";

export const useVehicleQueries = (vehicle: Vehicle) => {
  const { vehicles: vehiclesService } = useApiClient();

  const queryClient = useQueryClient();

  const updateMutation = useMutation(
    {
      mutationFn: (requestBody: VehicleUpdateInput) => {
        return vehiclesService.updateVehicle({
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
          queryKey: ["vehicles"],
        });
        await queryClient.cancelQueries({
          queryKey: ["vehicles", updatedVehicle.id],
        });

        const previousVehicles = queryClient.getQueryData([
          "vehicles",
        ]) as Hangar;

        queryClient.setQueryData(["vehicles"], {
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
        queryClient.setQueryData(["vehicles"], context?.previousVehicles);
      },
      onSettled: (updatedVehicle) => {
        queryClient.invalidateQueries({
          queryKey: ["vehicles", updatedVehicle?.id],
        });
        queryClient.invalidateQueries({
          queryKey: ["vehicles"],
        });
      },
    },
    queryClient,
  );

  const boughtViaFiltersQuery = () => {
    return useQuery(
      {
        queryKey: ["boughtViaFilters"],
        queryFn: async () => {
          return vehiclesService.boughtViaFilters();
        },
      },
      queryClient,
    );
  };

  return {
    updateMutation,
    boughtViaFiltersQuery,
  };
};
