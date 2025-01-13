import { useApiClient } from "@/admin/composables/useApiClient";
import {
  type ApiError,
  type Models,
  type ModelQuery,
  type ModelExtended,
  type ModelPaintQuery,
  type ModelPaints,
  type Model,
  type ModelUpdateInput,
} from "@/services/fyAdminApi";
import { useQuery, useQueryClient, useMutation } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  MODELS = "models",
  MODEL = "model",
  PAINTS = "paints",
}

export const useModelQueries = () => {
  const { models: modelsService } = useApiClient();

  const queryClient = useQueryClient();

  const modelsQuery = ({
    page,
    perPage,
    filters,
    sorts,
  }: {
    page: ComputedRef<string>;
    perPage: ComputedRef<string | undefined>;
    filters: ComputedRef<ModelQuery | undefined>;
    sorts: ComputedRef<string[] | undefined>;
  }) => {
    return useQuery<Models, ApiError>(
      {
        queryKey: [QueryKeysEnum.MODELS],
        queryFn: () =>
          modelsService.models({
            page: page.value,
            perPage: perPage.value,
            q: filters.value,
            s: sorts.value,
          }),
      },
      queryClient,
    );
  };

  const modelQuery = ({ id }: { id: string }) => {
    return useQuery<ModelExtended, ApiError>(
      {
        queryKey: [QueryKeysEnum.MODEL, id],
        queryFn: () =>
          modelsService.model({
            id,
          }),
      },
      queryClient,
    );
  };

  const paintsQuery = ({
    page,
    perPage,
    filters,
    sorts,
  }: {
    page: ComputedRef<string>;
    perPage: ComputedRef<string | undefined>;
    filters: ComputedRef<ModelPaintQuery | undefined>;
    sorts: ComputedRef<string[] | undefined>;
  }) => {
    return useQuery<ModelPaints, ApiError>(
      {
        queryKey: [QueryKeysEnum.PAINTS],
        queryFn: () =>
          modelsService.paints({
            page: page.value,
            perPage: perPage.value,
            q: filters.value,
            s: sorts.value,
          }),
      },
      queryClient,
    );
  };

  const updateMutation = (model: Model) => {
    return useMutation(
      {
        mutationFn: (requestBody: ModelUpdateInput) => {
          return modelsService.modelUpdate({
            id: model.id,
            requestBody,
          });
        },
        onMutate: async (input: ModelUpdateInput) => {
          const updatedModel = {
            ...model,
            ...input,
          };
          await queryClient.cancelQueries({
            queryKey: [QueryKeysEnum.MODELS],
          });

          const previousModels = queryClient.getQueryData([
            QueryKeysEnum.MODELS,
          ]) as Models;

          if (!previousModels) {
            return;
          }

          queryClient.setQueryData([QueryKeysEnum.MODELS], {
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
              [QueryKeysEnum.MODELS],
              context?.previousModels,
            );
          }
        },
        onSettled: (updatedModel) => {
          queryClient.invalidateQueries({
            queryKey: [QueryKeysEnum.MODEL, updatedModel?.id],
          });
          queryClient.invalidateQueries({
            queryKey: [QueryKeysEnum.MODELS],
          });
        },
      },
      queryClient,
    );
  };

  return {
    modelsQuery,
    modelQuery,
    updateMutation,
    paintsQuery,
  };
};
