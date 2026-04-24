import {
  useModel as useModelQuery,
  useModelModules as useModelModulesQuery,
  type Model,
  type ModelModule,
} from "@/services/fyApi";
import { computeGreedyFill } from "@/frontend/components/CargoGridViewer/constants";
import type { CargoHold } from "@/services/fyApi";

export function useCargoGridShip(slug: Ref<string | undefined>) {
  const model = ref<Model>();

  const { data: modelData } = useModelQuery(
    computed(() => slug.value || ""),
    {
      query: {
        enabled: computed(() => !!slug.value),
      },
    },
  );

  const { data: modulesData } = useModelModulesQuery(
    computed(() => slug.value || ""),
    undefined,
    {
      query: {
        enabled: computed(() => !!slug.value),
      },
    },
  );

  watch(
    modelData,
    (data) => {
      if (data) {
        model.value = data;
      }
    },
    { immediate: true },
  );

  watch(slug, (newSlug, oldSlug) => {
    if (newSlug !== oldSlug) {
      model.value = undefined;
      selectedModuleSlugs.value = new Set();
    }
  });

  const availableModules = computed<ModelModule[]>(
    () => modulesData.value?.items || [],
  );

  const modulesWithCargo = computed(() =>
    availableModules.value.filter((m) => m.cargoHolds?.length),
  );

  const selectedModuleSlugs = ref<Set<string>>(new Set());

  const toggleModule = (moduleSlug: string) => {
    const next = new Set(selectedModuleSlugs.value);
    if (next.has(moduleSlug)) {
      next.delete(moduleSlug);
    } else {
      next.add(moduleSlug);
    }
    selectedModuleSlugs.value = next;
  };

  const setModuleSlugs = (slugs: string[]) => {
    selectedModuleSlugs.value = new Set(slugs);
  };

  const combinedCargoHolds = computed<CargoHold[]>(() => {
    const base = model.value?.cargoHolds || [];
    const moduleCargo = availableModules.value
      .filter((m) => selectedModuleSlugs.value.has(m.slug))
      .flatMap((m) => m.cargoHolds || []);
    return [...base, ...moduleCargo];
  });

  const angledImage = computed(() => {
    if (!model.value) return undefined;
    return model.value.media.angledViewColored || model.value.media.angledView;
  });

  const shipRoute = computed(() => {
    if (!model.value) return undefined;
    return { name: "ship", params: { slug: model.value.slug } };
  });

  const getGreedyFillCounts = () => {
    if (!combinedCargoHolds.value.length) return {};
    return computeGreedyFill(combinedCargoHolds.value);
  };

  return {
    model: computed(() => model.value),
    availableModules,
    modulesWithCargo,
    selectedModuleSlugs: computed(() => selectedModuleSlugs.value),
    combinedCargoHolds,
    angledImage,
    shipRoute,
    toggleModule,
    setModuleSlugs,
    getGreedyFillCounts,
  };
}
