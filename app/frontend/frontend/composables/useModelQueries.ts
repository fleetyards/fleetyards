import { useApiClient } from "@/frontend/composables/useApiClient";
import { ModelPaint, type Model } from "@/services/fyApi";
import { FilterGroupParams } from "@/shared/components/base/FilterGroup/index.vue";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export const useModelQueries = (model: Model) => {
  const { models: modelsService } = useApiClient();

  const queryClient = useQueryClient();

  const modulePackagesQuery = () => {
    return useQuery(
      {
        queryKey: ["modulePackages", model.slug],
        queryFn: () => modelsService.modelModulePackages({ slug: model.slug }),
      },
      queryClient,
    );
  };

  const modulesQuery = () => {
    return useQuery(
      {
        queryKey: ["modules", model.slug],
        queryFn: () => modelsService.modelModules({ slug: model.slug }),
      },
      queryClient,
    );
  };

  const upgradesQuery = () => {
    return useQuery(
      {
        queryKey: ["upgrades", model.slug],
        queryFn: () => modelsService.modelUpgrades({ slug: model.slug }),
      },
      queryClient,
    );
  };

  const paintsQuery = (options = {}) => {
    return useQuery(
      {
        queryKey: ["paints", model.slug],
        queryFn: () => modelsService.modelPaints({ slug: model.slug }),
        ...options,
      },
      queryClient,
    );
  };

  const paintsFilterQuery = (_params: FilterGroupParams) => {
    return modelsService.modelPaints({ slug: model.slug });
  };

  const paintsFilterFormatter = (paints: ModelPaint[]) => {
    return paints.map((paint) => ({
      label: paint.name,
      value: paint.id,
    }));
  };

  return {
    modulePackagesQuery,
    modulesQuery,
    upgradesQuery,
    paintsQuery,
    paintsFilterQuery,
    paintsFilterFormatter,
  };
};
