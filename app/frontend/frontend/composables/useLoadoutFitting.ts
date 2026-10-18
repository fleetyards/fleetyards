import type { MaybeRefOrGetter } from "vue";
import {
  loadoutValues,
  useComponentFitting,
} from "@/frontend/composables/useComponentFitting";
import {
  HardpointSourceEnum,
  type LoadoutSlot,
  type VehicleLoadoutItem,
  useModelHardpoints,
  useModelLoadoutSlots,
  useModelModules,
} from "@/services/fyApi";

type Item = Pick<VehicleLoadoutItem, "slotPath" | "itemType" | "itemId">;

/**
 * A saved loadout fitted to its ship: the hull's slots, the parts the
 * loadout's own slot tree names, and the model's modules, resolved against the
 * loadout's items and grafted onto the ship's game-files hardpoints -- the
 * ship page's hardpoints and figures, for this fitting.
 */
export const useLoadoutFitting = ({
  modelSlug,
  loadoutSlots,
  items,
  enabled = true,
}: {
  modelSlug: MaybeRefOrGetter<string | undefined>;
  // The loadout's slot tree, which names the parts it fits.
  loadoutSlots: MaybeRefOrGetter<LoadoutSlot[] | undefined>;
  items: MaybeRefOrGetter<Item[] | undefined>;
  // Whether the hull's slots and hardpoints are wanted at all.
  enabled?: MaybeRefOrGetter<boolean>;
}) => {
  const fitting = useComponentFitting();

  const slug = () => toValue(modelSlug) ?? "";

  const wanted = () => toValue(enabled) && !!slug();

  const { data: hullSlots } = useModelLoadoutSlots(slug, {
    query: { enabled: wanted },
  });

  const { data: modelHardpoints } = useModelHardpoints(
    slug,
    { source: HardpointSourceEnum.GAME_FILES },
    { query: { enabled: wanted } },
  );

  // Every module the model takes: a module the loadout swapped out still has
  // its slots known.
  const { data: allModules } = useModelModules(slug, undefined, {
    query: { enabled: () => !!slug() },
  });

  const modelModules = computed(() => allModules.value?.items ?? []);

  watch(hullSlots, (slots) => fitting.learn(slots), { immediate: true });
  watch(
    () => toValue(loadoutSlots),
    (slots) => fitting.learn(slots),
    { immediate: true },
  );
  watch(modelModules, (list) => fitting.learnModules(list), {
    immediate: true,
  });

  const tree = computed(() => {
    const { modules, components } = loadoutValues(toValue(items));

    return fitting.resolve(hullSlots.value ?? [], {
      ...modules,
      ...components,
    });
  });

  const hardpoints = computed(() =>
    modelHardpoints.value?.length
      ? fitting.graft(modelHardpoints.value, tree.value)
      : undefined,
  );

  return {
    fitting,
    hullSlots,
    modelHardpoints,
    modelModules,
    tree,
    hardpoints,
  };
};
