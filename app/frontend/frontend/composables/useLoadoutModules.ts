import type { MaybeRefOrGetter } from "vue";
import { CARGO, useModuleDiff } from "@/frontend/composables/useLoadoutDiff";
import {
  type ModelModule,
  type VehicleLoadout,
  type VehicleLoadoutMinimal,
  VehicleLoadoutItemTypeEnum,
  useModelModules,
} from "@/services/fyApi";

export type LoadoutModuleRow = { slotPath: string; module: ModelModule };

export const useLoadoutModules = (
  modelSlug: MaybeRefOrGetter<string | undefined>,
  loadout: MaybeRefOrGetter<VehicleLoadout | VehicleLoadoutMinimal | undefined>,
) => {
  const slug = computed(() => toValue(modelSlug) ?? "");

  const fitted = computed(() =>
    (toValue(loadout)?.items ?? []).filter(
      (item) => item.itemType === VehicleLoadoutItemTypeEnum.MODEL_MODULE,
    ),
  );

  // Only a loadout with modules fitted needs the model's list to name them.
  const { data } = useModelModules(slug, undefined, {
    query: { enabled: computed(() => !!slug.value && !!fitted.value.length) },
  });

  const moduleRows = computed<LoadoutModuleRow[]>(() => {
    const modules = data.value?.items ?? [];

    return fitted.value
      .map((item) => ({
        slotPath: item.slotPath,
        module: modules.find((mod) => mod.id === item.itemId),
      }))
      .filter((row): row is LoadoutModuleRow => Boolean(row.module))
      .sort((a, b) => a.slotPath.localeCompare(b.slotPath));
  });

  const { metrics } = useModuleDiff();

  // What the modules carry, counted as the editor counts it.
  const moduleCargo = computed(
    () =>
      metrics(
        0,
        moduleRows.value.map((row) => row.module),
      ).get(CARGO) || 0,
  );

  return { moduleRows, moduleCargo };
};
