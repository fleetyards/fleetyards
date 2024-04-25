import { useApiClient } from "@/admin/composables/useApiClient";
import {
  type ApiError,
  type Models,
  type ModelQuery,
} from "@/services/fyAdminApi";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  MODELS = "models",
}

export const useModelQueries = () => {
  const { models: modelsService } = useApiClient();

  const queryClient = useQueryClient();

  const modelsQuery = ({
    page,
    perPage,
    q,
    s,
  }: {
    page: ComputedRef<string>;
    perPage: ComputedRef<string | undefined>;
    q: ComputedRef<ModelQuery | undefined>;
    s: ComputedRef<string[] | undefined>;
  }) => {
    return useQuery<Models, ApiError>(
      {
        queryKey: [QueryKeysEnum.MODELS],
        queryFn: () =>
          modelsService.models({
            page: page.value,
            perPage: perPage.value,
            q: q.value,
            s: s.value,
          }),
      },
      queryClient,
    );
  };

  return {
    modelsQuery,
  };
};
