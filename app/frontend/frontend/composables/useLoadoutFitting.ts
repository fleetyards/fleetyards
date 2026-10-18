import type { MaybeRefOrGetter } from "vue";
import {
  COMPONENT_TABS,
  type FittedSlot,
  loadoutValues,
  stockModuleValues,
  stockModules as stockModulesOf,
  useComponentFitting,
} from "@/frontend/composables/useComponentFitting";
import { useLoadoutDiff } from "@/frontend/composables/useLoadoutDiff";
import {
  type Hardpoint,
  HardpointSourceEnum,
  type LoadoutSlot,
  type ModelModule,
  type VehicleLoadoutItem,
  useModelHardpoints,
  useModelLoadoutSlots,
  useModelModules,
} from "@/services/fyApi";

type Item = Pick<VehicleLoadoutItem, "slotPath" | "itemType" | "itemId">;

type FittedModel = {
  slug: string;
  metrics: { cargo?: number; weaponPoolSize?: number };
};

/**
 * A saved loadout fitted to its ship: the hull's slots, the parts the
 * loadout's own slot tree names, and the model's modules, resolved against the
 * loadout's items and grafted onto the ship's game-files hardpoints -- the
 * ship page's hardpoints and figures, for this fitting, and how it differs
 * from the stock ship.
 */
export const useLoadoutFitting = ({
  model,
  loadoutSlots,
  items,
  enabled = true,
}: {
  model: MaybeRefOrGetter<FittedModel | undefined>;
  // The loadout's slot tree, which names the parts it fits.
  loadoutSlots: MaybeRefOrGetter<LoadoutSlot[] | undefined>;
  items: MaybeRefOrGetter<Item[] | undefined>;
  // Whether the hull's slots and hardpoints are wanted at all.
  enabled?: MaybeRefOrGetter<boolean>;
}) => {
  const fitting = useComponentFitting();

  const slug = () => toValue(model)?.slug ?? "";

  const wanted = () => toValue(enabled) && !!slug();

  const { data: hullSlots, isLoading: hullSlotsLoading } = useModelLoadoutSlots(
    slug,
    {
      query: { enabled: wanted },
    },
  );

  const { data: modelHardpoints, isLoading: hardpointsLoading } =
    useModelHardpoints(
      slug,
      { source: HardpointSourceEnum.GAME_FILES },
      { query: { enabled: wanted } },
    );

  // Every module the model takes: a module the loadout swapped out still has
  // its slots known.
  const { data: allModules, isLoading: modulesLoading } = useModelModules(
    slug,
    undefined,
    {
      query: { enabled: () => !!slug() },
    },
  );

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

  const values = computed(() => loadoutValues(toValue(items)));

  const tree = computed(() =>
    fitting.resolve(hullSlots.value ?? [], {
      ...values.value.modules,
      ...values.value.components,
    }),
  );

  const hardpoints = computed(() =>
    modelHardpoints.value?.length
      ? fitting.graft(modelHardpoints.value, tree.value)
      : undefined,
  );

  // The ship as the game files deliver it: the modules it comes with in their
  // slots, and the stock part in every other one.
  const stockModules = computed(() => stockModulesOf(modelModules.value));

  const stockTree = computed(() =>
    fitting.resolve(
      hullSlots.value ?? [],
      stockModuleValues(modelModules.value),
    ),
  );

  const fittedModules = computed(() => {
    const ids = new Set(Object.values(values.value.modules));

    return modelModules.value.filter((mod) => ids.has(mod.id));
  });

  // The ids of every hardpoint the loadout fits differently from the stock
  // ship: a part swapped in or taken out, another module.
  const changed = computed(() => {
    const marked = new Set<string>();

    const walk = (
      list: Hardpoint[],
      entries: FittedSlot[],
      stock: FittedSlot[],
    ) =>
      list.forEach((hardpoint) => {
        const entry = entries.find((slot) => slot.slot.name === hardpoint.name);
        if (!entry) return;

        const was = stock.find((slot) => slot.slot.name === hardpoint.name);
        if (entry.content?.id !== was?.content?.id) marked.add(hardpoint.id);

        walk(hardpoint.hardpoints ?? [], entry.children, was?.children ?? []);
      });

    walk(hardpoints.value ?? [], tree.value, stockTree.value);

    return marked;
  });

  const loadoutDiff = useLoadoutDiff(fitting);

  // What the loadout changes against the stock ship, in the editor's words.
  const changesFromStock = computed(() => {
    const metrics = toValue(model)?.metrics;
    const measure = (modules: ModelModule[], fitted: FittedSlot[]) =>
      loadoutDiff.measure({
        hullCargo: metrics?.cargo || 0,
        modules,
        hardpoints: modelHardpoints.value ?? [],
        tree: fitted,
        weaponPoolSize: metrics?.weaponPoolSize,
      });

    return loadoutDiff.diff(
      measure(stockModules.value, stockTree.value),
      measure(fittedModules.value, tree.value),
      COMPONENT_TABS,
    ).changed;
  });

  // Whether what the fitting is measured from is still on its way.
  const loading = computed(
    () =>
      hullSlotsLoading.value || hardpointsLoading.value || modulesLoading.value,
  );

  return {
    fitting,
    loading,
    hullSlots,
    modelHardpoints,
    modelModules,
    tree,
    hardpoints,
    changed,
    changesFromStock,
  };
};
