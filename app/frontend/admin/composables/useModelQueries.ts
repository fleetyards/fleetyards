import { useApiClient } from "@/admin/composables/useApiClient";
import {
  type ApiError,
  type Models,
  type ModelQuery,
  type ModelExtended,
  type ModelPaintQuery,
  type ModelPaints,
} from "@/services/fyAdminApi";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

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

  return {
    modelsQuery,
    modelQuery,
    paintsQuery,
  };
};
