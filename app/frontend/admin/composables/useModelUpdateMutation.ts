import {
  useUpdateModel as useUpdateModelMutation,
  getModelsQueryKey,
  type Models,
  type Model,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";

export const useModelUpdateMutation = (model: Model) => {
  const queryClient = useQueryClient();

  const modelsQueryKey = computed(() => {
    return getModelsQueryKey();
  });

  const updateMutation = useUpdateModelMutation({
    mutation: {
      onMutate: async ({ data }) => {
        const updatedModel = {
          ...model,
          ...data,
        };
        await queryClient.cancelQueries({
          queryKey: modelsQueryKey.value,
        });

        const previousModels = queryClient.getQueryData(
          modelsQueryKey.value,
        ) as Models;

        if (!previousModels) {
          return;
        }

        queryClient.setQueryData(modelsQueryKey.value, {
          ...previousModels,
          items: previousModels.items.map((model) => {
            if (model.id === updatedModel.id) {
              return updatedModel;
            }

            return model;
          }),
        });

        return { previousModels };
      },
      onError: (_error, _updatedModel, context) => {
        if (context?.previousModels) {
          queryClient.setQueryData(
            modelsQueryKey.value,
            context?.previousModels,
          );
        }
      },
      onSettled: (updatedModel) => {
        if (updatedModel) {
          queryClient.invalidateQueries({
            queryKey: modelsQueryKey.value,
          });
        }
        queryClient.invalidateQueries({
          queryKey: modelsQueryKey.value,
        });
      },
    },
  });

  return {
    updateMutation,
  };
};
