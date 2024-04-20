import { useApiClient } from "@/frontend/composables/useApiClient";
import {
  type ApiError,
  type ModelPaint,
  type Models,
  type ModelQuery,
  type ModelExtended,
} from "@/services/fyApi";
import { FilterGroupParams } from "@/shared/components/base/FilterGroup/index.vue";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  MODELS = "models",
  MODEL = "model",
  MODEL_IMAGES = "modelImages",
  MODEL_VIDEOS = "modelVideos",
  MODEL_MODULE_PACKAGES = "modelModulePackages",
  MODEL_MODULES = "modelModules",
  MODEL_UPGRADES = "modelUpgrades",
  MODEL_PAINTS = "modelPaints",
  MODEL_VARIANTS = "modelVariants",
}

export const useModelQueries = (slug?: string) => {
  const { models: modelsService } = useApiClient();

  const queryClient = useQueryClient();

  const modelsQuery = ({
    page,
    perPage,
    q,
  }: {
    page: ComputedRef<string>;
    perPage: ComputedRef<string | undefined>;
    q: ComputedRef<ModelQuery | undefined>;
  }) => {
    return useQuery<Models, ApiError>(
      {
        queryKey: [QueryKeysEnum.MODELS],
        queryFn: () => {
          return modelsService.models({
            page: page.value,
            perPage: perPage.value,
            q: q.value,
          });
        },
      },
      queryClient,
    );
  };

  const modelQuery = () => {
    if (!slug) throw new Error("slug is required");

    return useQuery<ModelExtended, ApiError>(
      {
        queryKey: [QueryKeysEnum.MODEL, slug],
        queryFn: () => modelsService.model({ slug }),
        retry: false,
      },
      queryClient,
    );
  };

  const imagesQuery = ({ page }: { page?: string }) => {
    if (!slug) throw new Error("slug is required");

    return useQuery(
      {
        queryKey: [QueryKeysEnum.MODEL_IMAGES, slug],
        queryFn: () => modelsService.modelImages({ slug, page }),
      },
      queryClient,
    );
  };

  const videosQuery = ({ page }: { page?: string }) => {
    if (!slug) throw new Error("slug is required");

    return useQuery(
      {
        queryKey: [QueryKeysEnum.MODEL_VIDEOS, slug],
        queryFn: () => modelsService.modelVideos({ slug, page }),
      },
      queryClient,
    );
  };

  const modulePackagesQuery = () => {
    if (!slug) throw new Error("slug is required");

    return useQuery(
      {
        queryKey: [QueryKeysEnum.MODEL_MODULE_PACKAGES, slug],
        queryFn: () => modelsService.modelModulePackages({ slug }),
      },
      queryClient,
    );
  };

  const modulesQuery = () => {
    if (!slug) throw new Error("slug is required");

    return useQuery(
      {
        queryKey: [QueryKeysEnum.MODEL_MODULES, slug],
        queryFn: () => modelsService.modelModules({ slug }),
      },
      queryClient,
    );
  };

  const upgradesQuery = () => {
    if (!slug) throw new Error("slug is required");

    return useQuery(
      {
        queryKey: [QueryKeysEnum.MODEL_UPGRADES, slug],
        queryFn: () => modelsService.modelUpgrades({ slug }),
      },
      queryClient,
    );
  };

  const paintsQuery = (options = {}) => {
    if (!slug) throw new Error("slug is required");

    return useQuery(
      {
        queryKey: [QueryKeysEnum.MODEL_PAINTS, slug],
        queryFn: () => modelsService.modelPaints({ slug }),
        ...options,
      },
      queryClient,
    );
  };

  const paintsFilterQuery = (_params: FilterGroupParams) => {
    if (!slug) throw new Error("slug is required");

    return modelsService.modelPaints({ slug });
  };

  const paintsFilterFormatter = (paints: ModelPaint[]) => {
    return paints.map((paint) => ({
      label: paint.name,
      value: paint.id,
    }));
  };

  const variantsQuery = () => {
    if (!slug) throw new Error("slug is required");

    return useQuery(
      {
        queryKey: [QueryKeysEnum.MODEL_VARIANTS, slug],
        queryFn: () => modelsService.modelVariants({ slug }),
      },
      queryClient,
    );
  };

  return {
    modelsQuery,
    modelQuery,
    imagesQuery,
    videosQuery,
    modulePackagesQuery,
    modulesQuery,
    upgradesQuery,
    paintsQuery,
    paintsFilterQuery,
    paintsFilterFormatter,
    variantsQuery,
  };
};
