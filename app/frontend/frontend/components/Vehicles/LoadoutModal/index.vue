<script lang="ts">
export default {
  name: "VehicleLoadoutModal",
};
</script>

<script lang="ts" setup>
import { categoryIcon } from "@/frontend/components/Models/Hardpoints/categoryIcon";
import type { LoadoutSocketSlot } from "@/frontend/components/Loadout/Socket/types";
import { useForm } from "vee-validate";
import { useQueryClient } from "@tanstack/vue-query";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import Loader from "@/shared/components/Loader/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import SocketBoard from "@/frontend/components/Loadout/SocketBoard/index.vue";
import Picker from "@/frontend/components/Loadout/Picker/index.vue";
import Comparison from "./Comparison/index.vue";
import ComponentComparison from "./ComponentComparison/index.vue";
import LoadoutMetrics from "./Metrics/index.vue";
import {
  type LoadoutMetric,
  type LoadoutMetricsCard,
  TAB_METRICS,
  useLoadoutMetrics,
} from "@/frontend/composables/useLoadoutMetrics";
import { VehicleLoadoutTabsEnum } from "./types";
import { moduleSlots } from "./moduleSlots";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";
import { useFittingDiff } from "@/frontend/composables/useFittingDiff";
import { useModuleSockets } from "@/frontend/composables/useModuleSockets";
import {
  COMPONENT_TABS,
  type ComponentTab,
  EMPTIED,
  slotName,
  useComponentFitting,
} from "@/frontend/composables/useComponentFitting";
import { useMobile } from "@/shared/composables/useMobile";
import {
  type Vehicle,
  type VehicleLoadout,
  type VehicleLoadoutItemInput,
  ModelProductionStatusEnum,
  VehicleLoadoutItemTypeEnum,
  VehicleLoadoutKindEnum,
  activateVehicleLoadout,
  createVehicleLoadout,
  getVehicleLoadoutsQueryKey,
  updateVehicleLoadout,
  useHardpointLoadoutOptions,
  type ComponentController,
  HardpointCategoryEnum,
  HardpointSourceEnum,
  useModelHardpoints,
  useModelLoadoutSlots,
  useModelModules as useModelModulesQuery,
  useVehicleLoadoutSlots,
  useVehicleLoadouts,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
  editable?: boolean;
  tab?: VehicleLoadoutTabsEnum;
  // The saved fleetyards loadout to edit. Without one the editor opens the
  // active fleetyards loadout, or a new one.
  loadoutId?: string;
  newLoadout?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
  tab: undefined,
  loadoutId: undefined,
  newLoadout: false,
});

const { t } = useI18n();

/**
 * One fleetyards loadout: its name and what is fitted, slot path by slot path.
 * What the ship owns is edited on the vehicle, not here; this only reads it to
 * know what can be fitted.
 */
type LoadoutValues = {
  loadoutName: string;
  fittedModules: Record<string, string>;
  // Only parts that differ from the slot's stock one: a slot left alone keeps
  // the part it came with.
  fittedComponents: Record<string, string>;
};

const { data: loadoutsData, isPending: loadoutsPending } = useVehicleLoadouts(
  () => props.vehicle.id,
  { query: { enabled: () => props.editable } },
);

const editedLoadout = computed(() => {
  if (props.newLoadout) {
    return undefined;
  }

  if (props.loadoutId) {
    return (loadoutsData.value || []).find(
      (loadout) => loadout.id === props.loadoutId,
    );
  }

  const active = props.vehicle.activeLoadout;
  if (active?.kind === VehicleLoadoutKindEnum.FLEETYARDS) {
    return active;
  }

  // A linked build is active: the ship's own loadout is still the one to
  // edit, or every save would start another beside it.
  return (loadoutsData.value || [])
    .filter((loadout) => loadout.kind === VehicleLoadoutKindEnum.FLEETYARDS)
    .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))[0];
});

// Until the list is in, a save could not tell an edit from a new loadout.
const loadoutPending = computed(
  () => props.editable && !props.newLoadout && loadoutsPending.value,
);

const savedItems = (type: VehicleLoadoutItemTypeEnum) =>
  Object.fromEntries(
    (editedLoadout.value?.items || [])
      .filter((item) => item.itemType === type)
      .map((item) => [item.slotPath, item.itemId ?? EMPTIED]),
  );

const savedValues = (): LoadoutValues => ({
  loadoutName: editedLoadout.value?.name ?? "",
  fittedModules: savedItems(VehicleLoadoutItemTypeEnum.MODEL_MODULE),
  fittedComponents: {
    ...savedItems(VehicleLoadoutItemTypeEnum.COMPONENT),
    ...Object.fromEntries(
      Object.keys(savedItems(VehicleLoadoutItemTypeEnum.EMPTY)).map((path) => [
        path,
        EMPTIED,
      ]),
    ),
  },
});

const { defineField, handleSubmit, resetForm, meta } = useForm<LoadoutValues>({
  initialValues: savedValues(),
});

/**
 * Re-seeds the fields rather than the initial values, which vee-validate has
 * already copied by this point: reassigning those did nothing at all, so the
 * modal kept answering for whichever ship it was first opened for.
 *
 * A pending choice wins over the refresh, or a background refetch of the hangar
 * would discard what you had just picked and not yet saved.
 */
watch([() => props.vehicle, () => editedLoadout.value?.updatedAt], () => {
  if (meta.value.dirty) {
    return;
  }

  resetForm({ values: savedValues() });
});

const [fittedModules] = defineField("fittedModules");

const [fittedComponents] = defineField("fittedComponents");

const model = computed(() => props.vehicle.model);

const modelSlug = computed(() => model.value?.slug ?? "");

const { data: modulesData, ...modulesAsyncStatus } =
  useModelModulesQuery(modelSlug);

const modules = computed(() => modulesData.value?.items ?? []);

const flightReady = computed(
  () =>
    model.value?.productionStatus === ModelProductionStatusEnum.FLIGHT_READY,
);

const fittedModuleIds = computed(() =>
  Object.values(fittedModules.value || {}),
);

const fitting = useComponentFitting();

const { data: hullSlots, ...hullSlotsAsyncStatus } = useModelLoadoutSlots(
  modelSlug,
  { query: { enabled: flightReady } },
);

// The saved loadout's own tree names the parts fitted in it, and the slots a
// swapped-in part brings.
const { data: savedSlots } = useVehicleLoadoutSlots(
  () => props.vehicle.id,
  () => editedLoadout.value?.id ?? "",
  { query: { enabled: () => !!editedLoadout.value?.id } },
);

watch(hullSlots, (slots) => fitting.learn(slots), { immediate: true });
watch(savedSlots, (slots) => fitting.learn(slots), { immediate: true });
watch(modules, (list) => fitting.learnModules(list), { immediate: true });

// Opening on a ship, until its slots and modules are in: one loader in the
// middle of the editor rather than one at the start of a tab.
const initialising = computed(
  () =>
    loadoutPending.value ||
    (flightReady.value &&
      (hullSlotsAsyncStatus.isPending.value ||
        modulesAsyncStatus.isPending.value)),
);

const componentTree = computed(() =>
  fitting.resolve(hullSlots.value ?? [], {
    ...(fittedModules.value || {}),
    ...(fittedComponents.value || {}),
  }),
);

const SYSTEM_TAB_IDS = [
  "radar",
  "coolers",
  "lifeSupport",
  "powerPlants",
  "shields",
];

const TAB_ICONS: Record<string, string> = {
  radar: "radar",
  coolers: "cooler",
  lifeSupport: "lifesupport",
  powerPlants: "powerplant",
  shields: "shieldgenerator",
  quantumDrives: "quantumdrive",
  flightBlades: "controller",
  missiles: "missile_racks",
  weapons: "weapons",
};

const componentTab = (tab: ComponentTab) => ({
  ...tab,
  label: t(`labels.vehicleLoadout.tabs.${tab.id}`),
  icon: categoryIcon(TAB_ICONS[tab.id]),
  groups: fitting.groups(componentTree.value, tab, {
    fittedOnly: !props.editable,
    saved: props.editable ? savedTree.value : undefined,
  }),
  available: fitting.hasSlots(componentTree.value, tab),
});

const systemTabs = computed(() =>
  COMPONENT_TABS.filter((tab) => SYSTEM_TAB_IDS.includes(tab.id)).map(
    componentTab,
  ),
);

const propulsionWeaponTabs = computed(() =>
  COMPONENT_TABS.filter((tab) => !SYSTEM_TAB_IDS.includes(tab.id)).map(
    componentTab,
  ),
);

// The ship's systems, then its modules, then what moves and arms it.
const tabs = computed(() => [
  ...systemTabs.value,
  { id: VehicleLoadoutTabsEnum.MODULES },
  ...propulsionWeaponTabs.value,
]);

const componentTabs = computed(() =>
  Object.fromEntries(
    [...systemTabs.value, ...propulsionWeaponTabs.value].map((tab) => [
      tab.id,
      tab,
    ]),
  ),
);

const componentHint = (tab: { available: boolean }) => {
  if (!flightReady.value) {
    return t("labels.vehicleLoadout.notFlightReady");
  }

  return tab.available ? undefined : t("labels.vehicleLoadout.noSlots");
};

// The ship as a backdrop rather than a picture beside the controls: the
// angled view, coloured where there is one.
const backdrop = computed(() => {
  const media = model.value?.media;
  const file =
    media?.angledViewColored || media?.angledView || media?.storeImage;

  return file ? file.largeUrl || file.url : undefined;
});

const modulesFor = (ids: string[]) =>
  modules.value.filter((mod) => ids.includes(mod.id));

const hullCargo = computed(() => model.value?.metrics.cargo || 0);

// A ship that is not flight ready has modules but no slots to fit them in, so
// the category would open on an empty panel.
const modulesHint = computed(() => {
  if (!flightReady.value) {
    return t("labels.vehicleLoadout.notFlightReady");
  }

  return props.vehicle.model.hasModules
    ? undefined
    : t("labels.vehicleLoadout.unavailable.modules");
});

const { metrics, rows } = useFittingDiff();

// The tab on show, as FormTabs settles it: the one asked for while it can be
// opened, else the first that can.
const pickedTab = ref<string | undefined>(props.tab);

const tabEnabled = (id: string) =>
  flightReady.value &&
  (id === VehicleLoadoutTabsEnum.MODULES
    ? !!props.vehicle.model.hasModules
    : !!componentTabs.value[id]?.available);

const currentTab = computed(() =>
  pickedTab.value && tabEnabled(pickedTab.value)
    ? pickedTab.value
    : tabs.value.find((entry) => tabEnabled(entry.id))?.id,
);

const { data: modelHardpoints } = useModelHardpoints(
  modelSlug,
  { source: HardpointSourceEnum.GAME_FILES },
  { query: { enabled: flightReady } },
);

const savedTree = computed(() =>
  fitting.resolve(hullSlots.value ?? [], {
    ...savedValues().fittedModules,
    ...savedValues().fittedComponents,
  }),
);

// The ship's hardpoints with the fitting in them, and with the saved one, for
// the figures the ship page's metrics cards lead with.
const fittedHardpoints = computed(() =>
  fitting.graft(modelHardpoints.value ?? [], componentTree.value),
);

const savedHardpoints = computed(() =>
  fitting.graft(modelHardpoints.value ?? [], savedTree.value),
);

// The flight blade a tree holds, whose speeds the flight figures read.
const bladeIn = (tree: typeof componentTree.value) =>
  tree.find((entry) => entry.slot.category === HardpointCategoryEnum.CONTROLLER)
    ?.content?.typeData as ComponentController | undefined;

const { metrics: loadoutMetrics } = useLoadoutMetrics();

const now = computed(() => ({
  hardpoints: fittedHardpoints.value,
  blade: bladeIn(componentTree.value),
}));

const saved = computed(() => ({
  hardpoints: savedHardpoints.value,
  blade: bladeIn(savedTree.value),
}));

const cardMetrics = (card: LoadoutMetricsCard) =>
  modelHardpoints.value?.length
    ? loadoutMetrics(
        card,
        now.value,
        saved.value,
        model.value?.metrics.weaponPoolSize,
      )
    : [];

// The tabs whose parts' own figure no card leads with -- a radar's assist
// range, a drive's speed -- which their tab shows ahead of the card's.
const OWN_FIGURE_TABS = ["radar", "coolers", "lifeSupport", "quantumDrives"];

// Draw and signatures are the power card's to show, summed for the whole ship.
const CARD_FIGURES = new Set([
  "powerConsumption",
  "signatureEm",
  "signatureIr",
]);

const ownFigures = (tabId: string): LoadoutMetric[] => {
  const tab = componentTabs.value[tabId];
  if (!tab || !OWN_FIGURE_TABS.includes(tabId)) return [];

  return fitting
    .tabFigures(componentTree.value, savedTree.value, tab)
    .filter((figure) => !CARD_FIGURES.has(figure.key))
    .map(({ key, label, value, deltaLabel, tone }) => ({
      key,
      label,
      value,
      deltaLabel,
      tone,
    }));
};

const openCard = computed(() =>
  currentTab.value ? TAB_METRICS[currentTab.value] : undefined,
);

// The open tab's card, cut down to its leading figures, each with how far it
// moved from the saved loadout.
const tabMetrics = computed(() => {
  if (!currentTab.value || !openCard.value || !modelHardpoints.value?.length) {
    return undefined;
  }

  return {
    title: t(`labels.vehicleLoadout.tabs.${currentTab.value}`),
    metrics: [...ownFigures(currentTab.value), ...cardMetrics(openCard.value)],
  };
});

const moduleFigures = computed(() =>
  rows(
    metrics(
      hullCargo.value,
      modulesFor(Object.values(savedValues().fittedModules)),
    ),
    metrics(hullCargo.value, modulesFor(fittedModuleIds.value)),
  ),
);

const moduleMetrics = computed<LoadoutMetric[]>(() =>
  moduleFigures.value.map((row) => ({
    key: row.key,
    label: row.label,
    value: row.value,
    deltaLabel: row.deltaLabel,
    tone: row.delta?.tone,
  })),
);

/**
 * Everything the changes moved against the saved loadout, on every tab: a
 * summary of all that was done, in the words the tiles use, so a swap is never
 * out of sight on the tab it was not made on.
 */
const changedFigures = computed<LoadoutMetric[]>(() => {
  const all = [
    ...moduleMetrics.value,
    ...[...new Set(Object.values(TAB_METRICS))].flatMap(cardMetrics),
    ...OWN_FIGURE_TABS.flatMap(ownFigures),
  ].filter((figure) => figure.deltaLabel);

  return all.filter(
    (figure, index) =>
      all.findIndex((other) => other.key === figure.key) === index,
  );
});

const slots = computed(() => moduleSlots(modules.value));

const moduleSockets = useModuleSockets();

const socketGroups = computed(() =>
  moduleSockets.groups(modules.value, fittedModules.value || {}, {
    fittedOnly: !props.editable,
    saved: props.editable ? savedValues().fittedModules : undefined,
    contents: fitting.moduleContents,
  }),
);

/**
 * The socket the picker fills. None until one is picked, so the editor opens on
 * the ship as fitted; picking the active socket again, or pressing outside the
 * picker, closes it.
 */
const activeSlot = ref<string>();

// Whether the active socket is a module slot or a component one, and for a
// component, the tab it was opened from.
const activeKind = ref<"module" | "component">("module");

const activeTab = ref<string>();

const pickerOpen = computed(() => props.editable && !!activeSlot.value);

const pickerOpenFor = (tabId: string) =>
  pickerOpen.value &&
  activeKind.value === "component" &&
  activeTab.value === tabId;

const fitted = computed(() => fittedModules.value || {});

const formRoot = ref<HTMLElement>();

const picker = ref<InstanceType<typeof Picker>>();

// One picker shows at a time, in whichever tab is open.
const setPicker = (instance: unknown) => {
  if (instance) picker.value = instance as InstanceType<typeof Picker>;
};

const socketButton = (slot: string) =>
  formRoot.value?.querySelector<HTMLElement>(
    `[data-test="loadout-socket-${slot}"]`,
  );

const socketIn = (
  slots: LoadoutSocketSlot[],
  id: string,
): LoadoutSocketSlot | undefined => {
  for (const slot of slots) {
    if (slot.id === id) return slot;
    const inside = socketIn(
      [...(slot.children ?? []), ...(slot.stack ?? [])],
      id,
    );
    if (inside) return inside;
  }

  return undefined;
};

// The slots the open socket stands for: one, or every slot of a stacked row.
const activeMembers = computed(() => {
  const tab = activeTab.value && componentTabs.value[activeTab.value];
  const slot =
    tab && activeSlot.value
      ? socketIn(
          tab.groups.flatMap((group) => group.slots),
          activeSlot.value,
        )
      : undefined;

  return slot?.members ?? (activeSlot.value ? [activeSlot.value] : []);
});

const onSocketSelect = async (
  slot: string,
  kind: "module" | "component" = "module",
  tabId?: string,
) => {
  const opening = activeSlot.value !== slot || activeKind.value !== kind;

  activeSlot.value = opening ? slot : undefined;
  activeKind.value = kind;
  activeTab.value = tabId;
  hovered.value = undefined;

  // On desktop the picker comes after every socket in the page's order, so
  // the keyboard is handed to it rather than left to tab its way there.
  if (opening) {
    await nextTick();
    picker.value?.focus();
  }
};

// A stacked row is open on its first slot, which stands for the rest.
const activeComponentSlot = computed(() =>
  activeKind.value === "component" && activeSlot.value
    ? fitting.find(
        componentTree.value,
        activeMembers.value[0] ?? activeSlot.value,
      )
    : undefined,
);

const {
  data: componentOptions,
  isPending: componentOptionsPending,
  isPlaceholderData: componentOptionsStale,
} = useHardpointLoadoutOptions(
  () => activeComponentSlot.value?.slot.hardpointId ?? "",
  { query: { enabled: () => !!activeComponentSlot.value } },
);

const pickerOptions = computed(() => {
  if (activeComponentSlot.value) {
    return fitting.options(
      componentOptions.value ?? [],
      activeComponentSlot.value.slot,
      activeComponentSlot.value.content,
    );
  }

  return activeSlot.value
    ? moduleSockets.options(
        modules.value,
        activeSlot.value,
        fitted.value[activeSlot.value],
        props.vehicle.modelModuleIds,
      )
    : [];
});

const pickerSorts = computed(() =>
  activeComponentSlot.value
    ? fitting.sorts(
        componentOptions.value ?? [],
        activeComponentSlot.value.slot,
      )
    : moduleSockets.sorts(pickerOptions.value),
);

// The phone and the desktop place the picker apart; both take these.
const pickerBindings = computed(() => {
  const component = activeComponentSlot.value;

  if (component) {
    return {
      title: slotName(component.slot.name),
      options: pickerOptions.value,
      selectedId: component.content?.id,
      sorts: pickerSorts.value,
      clearable: true,
      // The previous slot's list stays in the query until this one's lands.
      loading: componentOptionsPending.value || componentOptionsStale.value,
      facets: fitting.facets(),
    };
  }

  return {
    title: moduleSockets.slotLabel(activeSlot.value || ""),
    options: pickerOptions.value,
    selectedId: activeSlot.value ? fitted.value[activeSlot.value] : undefined,
    sorts: pickerSorts.value,
    clearable: true,
    loading: false,
    facets: [],
  };
});

/**
 * Pointing at an option previews it in the comparison for as long as the
 * pointer or focus stays on the list, then it returns to what is fitted, so
 * passing over options on the way to one never leaves it on another.
 */
const hovered = ref<{ slot: string; moduleId: string | null }>();

const onPreview = (moduleId: string | null) => {
  if (!activeSlot.value) return;

  hovered.value = { slot: activeSlot.value, moduleId };
};

const onPreviewEnd = () => {
  hovered.value = undefined;
};

const onPick = (itemId: string | null) => {
  const slot = activeSlot.value;
  if (!slot) return;

  const component = activeComponentSlot.value;
  if (component) {
    const option = componentOptions.value?.find(
      (entry) => entry.component.id === itemId,
    );

    // A stacked row stands for every identical slot: the pick fills them all.
    fittedComponents.value = activeMembers.value.reduce((next, path) => {
      const entry = fitting.find(componentTree.value, path);
      if (!entry) return next;
      if (option) fitting.learnOption(path, option);

      return fitting.pick(next, entry, itemId);
    }, fittedComponents.value || {});

    void closePicker();
    return;
  }

  const next = { ...fitted.value };
  if (itemId) {
    next[slot] = itemId;
  } else {
    delete next[slot];
  }
  fittedModules.value = next;

  // What sat inside the module went with it.
  fittedComponents.value = Object.fromEntries(
    Object.entries(fittedComponents.value || {}).filter(
      ([path]) => !path.startsWith(`${slot}/`),
    ),
  );

  // The pick is the answer the picker was opened for.
  void closePicker();
};

// Focus inside the picker goes back to the socket it was filling, or it would
// fall to the page's start with the picker gone. A press outside has already
// put it where it went.
const closePicker = async () => {
  const slot = activeSlot.value;
  const hadFocus =
    !!slot &&
    !!formRoot.value
      ?.querySelector(".loadout-picker")
      ?.contains(document.activeElement);

  activeSlot.value = undefined;
  hovered.value = undefined;

  if (hadFocus) {
    await nextTick();
    socketButton(slot)?.focus();
  }
};

const pickerListeners = {
  pick: onPick,
  preview: onPreview,
  previewEnd: onPreviewEnd,
  close: closePicker,
};

// Below this the picker opens under the socket it fills rather than beside the
// board, where a phone has no room for it.
const mobile = useMobile();

// Against what the slot holds now, picked but not yet saved included, as the
// module comparison reads it.
const componentComparison = computed(() => {
  const entry = activeComponentSlot.value;
  if (!entry) return undefined;

  const hoveredId =
    hovered.value?.slot === entry.path ? hovered.value.moduleId : undefined;
  const to =
    hoveredId === undefined
      ? entry.content
      : hoveredId
        ? (componentOptions.value?.find(
            (option) => option.component.id === hoveredId,
          )?.component ?? entry.content)
        : undefined;

  return {
    from: entry.content,
    to,
    rows: fitting.compare(entry.content, to, entry.slot.category),
  };
});

const comparison = computed(() => {
  const slot = activeSlot.value;
  if (!slot || activeKind.value !== "module") {
    return undefined;
  }

  // Against what the socket holds now, picked but not yet saved included:
  // the swap the pointer is weighing is from that, not from the last save.
  const fittedId = fitted.value[slot];
  const moduleId =
    hovered.value?.slot === slot ? hovered.value.moduleId : fittedId;
  const others = Object.entries(fitted.value)
    .filter(([path]) => path !== slot)
    .map(([, id]) => id);

  return {
    from: modules.value.find((mod) => mod.id === fittedId),
    to: modules.value.find((mod) => mod.id === moduleId),
    others: modulesFor(others),
  };
});

const comlink = useComlink();

const queryClient = useQueryClient();

const { displayAlert } = useAppNotifications();

const { invalidateHangarQueries, invalidateVehiclePage } =
  useVehicleMutations();

/**
 * The parts the tree still reaches, and those inside a fitted module, which
 * this editor does not list yet and keeps as they are while the module stays.
 */
const fittedComponentsToSave = (values: LoadoutValues) => {
  const components = values.fittedComponents || {};
  const moduleSlots = Object.keys(values.fittedModules);
  const insideModule = Object.fromEntries(
    Object.entries(components).filter(([path]) =>
      moduleSlots.some((slot) => path.startsWith(`${slot}/`)),
    ),
  );

  return {
    ...fitting.reachable(componentTree.value, components),
    ...insideModule,
  };
};

const saving = ref(false);

// Created by a save whose activation then failed: the retry finishes that one
// rather than creating another beside it.
const createdLoadout = ref<VehicleLoadout>();

/**
 * Writes the loadout being edited, or a new one. A new loadout is switched on
 * only when nothing else is: replacing an active build stays a choice made on
 * the loadouts page.
 */
const onSubmit = handleSubmit(async (values) => {
  if (!props.editable || !flightReady.value || loadoutPending.value) {
    return;
  }

  const asItems = (
    fitted: Record<string, string>,
    itemType: VehicleLoadoutItemTypeEnum,
  ): VehicleLoadoutItemInput[] =>
    Object.entries(fitted).map(([slotPath, itemId]) => ({
      slotPath,
      itemType,
      itemId,
    }));

  const components = fittedComponentsToSave(values);

  const items = [
    ...asItems(values.fittedModules, VehicleLoadoutItemTypeEnum.MODEL_MODULE),
    ...asItems(
      Object.fromEntries(
        Object.entries(components).filter(([, id]) => id !== EMPTIED),
      ),
      VehicleLoadoutItemTypeEnum.COMPONENT,
    ),
    ...Object.entries(components)
      .filter(([, id]) => id === EMPTIED)
      .map(([slotPath]) => ({
        slotPath,
        itemType: VehicleLoadoutItemTypeEnum.EMPTY,
      })),
  ];
  // A cleared name goes back to the default the server gives.
  const name = values.loadoutName.trim();
  const target = createdLoadout.value ?? editedLoadout.value;

  saving.value = true;

  try {
    if (target) {
      await updateVehicleLoadout(props.vehicle.id, target.id, {
        name,
        items,
      });
    } else {
      createdLoadout.value = await createVehicleLoadout(props.vehicle.id, {
        kind: VehicleLoadoutKindEnum.FLEETYARDS,
        name,
        items,
      });
    }

    if (createdLoadout.value && !props.vehicle.activeLoadout) {
      await activateVehicleLoadout(props.vehicle.id, createdLoadout.value.id);
    }

    await Promise.all([
      invalidateHangarQueries(),
      invalidateVehiclePage(props.vehicle),
      queryClient.invalidateQueries({
        queryKey: getVehicleLoadoutsQueryKey(props.vehicle.id),
      }),
    ]);

    comlink.emit("close-modal");
  } catch (error) {
    // The reason -- a name another loadout already has, say -- is what tells
    // the owner what to change.
    displayAlert({
      text: [t("messages.vehicleLoadout.failure"), firstErrorMessageFrom(error)]
        .filter(Boolean)
        .join(": "),
    });
  } finally {
    saving.value = false;
  }
});
</script>

<template>
  <Modal
    v-if="vehicle"
    tabbed
    :title="
      t('headlines.vehicleLoadout', {
        vehicle: vehicle.name || vehicle.model?.name,
      })
    "
  >
    <form
      :id="`vehicle-loadout-${vehicle.id}`"
      ref="formRoot"
      class="vehicle-loadout"
      :style="backdrop ? { '--loadout-backdrop': `url(${backdrop})` } : {}"
      data-test="vehicle-loadout-form"
      @submit.prevent="onSubmit"
    >
      <Loader
        :loading="initialising"
        relative
        immediate
        data-test="vehicle-loadout-loading"
      />

      <aside class="vehicle-loadout__ship" data-test="vehicle-loadout-ship">
        <p class="vehicle-loadout__model">
          <!-- eslint-disable-next-line vue/no-v-html -->
          <span v-html="vehicle.model.manufacturer?.name" />
          <strong>{{ vehicle.model.name }}</strong>
        </p>
        <LoadoutMetrics
          v-if="tabMetrics"
          v-bind="tabMetrics"
          class="vehicle-loadout__card"
        />

        <dl v-if="!tabMetrics" class="vehicle-loadout__figures">
          <div
            v-for="figure in moduleFigures"
            :key="figure.key"
            class="vehicle-loadout__figure"
            :data-test="`vehicle-loadout-figure-${figure.key}`"
          >
            <dt>{{ figure.label }}</dt>
            <dd>
              {{ figure.value }}
              <span
                v-if="figure.deltaLabel"
                class="vehicle-loadout__figure-delta"
                :class="`vehicle-loadout__figure-delta--${figure.delta?.tone}`"
              >
                {{ figure.deltaLabel }}
              </span>
            </dd>
          </div>
        </dl>

        <section
          v-if="changedFigures.length"
          class="vehicle-loadout__changes"
          data-test="vehicle-loadout-changes"
        >
          <h4 class="vehicle-loadout__changes-title">
            {{ t("labels.loadoutPicker.changed") }}
          </h4>
          <dl class="vehicle-loadout__changes-list">
            <div
              v-for="figure in changedFigures"
              :key="figure.key"
              class="vehicle-loadout__change"
              :data-test="`vehicle-loadout-change-${figure.key}`"
            >
              <dt>{{ figure.label }}</dt>
              <dd>
                {{ figure.value }}
                <span
                  class="vehicle-loadout__figure-delta"
                  :class="`vehicle-loadout__figure-delta--${figure.tone}`"
                >
                  {{ figure.deltaLabel }}
                </span>
              </dd>
            </div>
          </dl>
        </section>
      </aside>

      <div class="vehicle-loadout__panel">
        <p
          v-if="!flightReady"
          class="vehicle-loadout__hint"
          data-test="vehicle-loadout-not-flight-ready"
        >
          {{ t("labels.vehicleLoadout.notFlightReady") }}
        </p>

        <FormTabs
          :default-tab="tab"
          @update:active-tab="(id) => (pickedTab = id)"
          :sync-url="false"
          horizontal
          active-label-only
        >
          <template v-for="tab in tabs" :key="tab.id">
            <FormTab
              v-if="tab.id === VehicleLoadoutTabsEnum.MODULES"
              :id="VehicleLoadoutTabsEnum.MODULES"
              :label="t('labels.vehicleLoadout.tabs.modules')"
              :icon="categoryIcon('module')"
              :fields="['fittedModules']"
              :disabled="!flightReady || !vehicle.model.hasModules"
              :hint="modulesHint"
            >
              <AsyncData
                :async-status="modulesAsyncStatus"
                :show-spinner="false"
              >
                <template #resolved>
                  <div
                    class="vehicle-loadout__category"
                    :class="{
                      'vehicle-loadout__category--picking':
                        pickerOpen && activeKind === 'module' && !mobile,
                    }"
                  >
                    <div
                      v-if="flightReady && slots.length"
                      class="vehicle-loadout__sockets"
                      data-test="vehicle-loadout-fitted"
                    >
                      <SocketBoard
                        :active="
                          activeKind === 'module' ? activeSlot : undefined
                        "
                        :groups="socketGroups"
                        :editable="editable"
                        @update:active="
                          (slot) => onSocketSelect(slot, 'module')
                        "
                      >
                        <template
                          v-if="pickerOpen && activeKind === 'module' && mobile"
                          #active
                        >
                          <Picker
                            :key="activeSlot"
                            :ref="setPicker"
                            v-bind="pickerBindings"
                            v-on="pickerListeners"
                          >
                            <template v-if="comparison" #comparison>
                              <Comparison
                                :hull-cargo="hullCargo"
                                :others="comparison.others"
                                :from="comparison.from"
                                :to="comparison.to"
                              />
                            </template>
                          </Picker>
                        </template>
                      </SocketBoard>
                    </div>

                    <Picker
                      v-if="pickerOpen && activeKind === 'module' && !mobile"
                      :key="activeSlot"
                      :ref="setPicker"
                      class="vehicle-loadout__picker"
                      v-bind="pickerBindings"
                      v-on="pickerListeners"
                    >
                      <template v-if="comparison" #comparison>
                        <Comparison
                          :hull-cargo="hullCargo"
                          :others="comparison.others"
                          :from="comparison.from"
                          :to="comparison.to"
                        />
                      </template>
                    </Picker>

                    <p
                      v-if="
                        !editable &&
                        flightReady &&
                        slots.length &&
                        !socketGroups.length
                      "
                      class="vehicle-loadout__hint"
                      data-test="vehicle-loadout-nothing-fitted"
                    >
                      {{ t("labels.vehicleLoadout.nothingFitted") }}
                    </p>

                    <div
                      v-if="flightReady && !slots.length"
                      class="vehicle-loadout__empty"
                      data-test="vehicle-loadout-no-slots"
                    >
                      <i class="fa-duotone fa-layer-minus" aria-hidden="true" />
                      <p>{{ t("labels.vehicleLoadout.noSlots") }}</p>
                    </div>
                  </div>
                </template>
              </AsyncData>
            </FormTab>
            <FormTab
              v-else
              :id="tab.id"
              :label="componentTabs[tab.id].label"
              :icon="componentTabs[tab.id].icon"
              :fields="['fittedComponents']"
              :disabled="!flightReady || !componentTabs[tab.id].available"
              :hint="componentHint(componentTabs[tab.id])"
            >
              <AsyncData
                :async-status="hullSlotsAsyncStatus"
                :show-spinner="false"
              >
                <template #resolved>
                  <div
                    class="vehicle-loadout__category"
                    :class="{
                      'vehicle-loadout__category--picking':
                        pickerOpenFor(tab.id) && !mobile,
                    }"
                  >
                    <div
                      v-if="componentTabs[tab.id].groups.length"
                      class="vehicle-loadout__sockets"
                      :data-test="`vehicle-loadout-${tab.id}`"
                    >
                      <SocketBoard
                        :active="
                          activeKind === 'component' ? activeSlot : undefined
                        "
                        :groups="componentTabs[tab.id].groups"
                        :editable="editable"
                        @update:active="
                          (slot) => onSocketSelect(slot, 'component', tab.id)
                        "
                      >
                        <template
                          v-if="pickerOpenFor(tab.id) && mobile"
                          #active
                        >
                          <Picker
                            :key="activeSlot"
                            :ref="setPicker"
                            v-bind="pickerBindings"
                            v-on="pickerListeners"
                          >
                            <template v-if="componentComparison" #comparison>
                              <ComponentComparison
                                v-bind="componentComparison"
                              />
                            </template>
                          </Picker>
                        </template>
                      </SocketBoard>
                    </div>

                    <Picker
                      v-if="pickerOpenFor(tab.id) && !mobile"
                      :key="activeSlot"
                      :ref="setPicker"
                      class="vehicle-loadout__picker"
                      v-bind="pickerBindings"
                      v-on="pickerListeners"
                    >
                      <template v-if="componentComparison" #comparison>
                        <ComponentComparison v-bind="componentComparison" />
                      </template>
                    </Picker>

                    <p
                      v-if="!componentTabs[tab.id].groups.length"
                      class="vehicle-loadout__hint"
                      :data-test="`vehicle-loadout-${tab.id}-nothing-fitted`"
                    >
                      {{ t("labels.vehicleLoadout.nothingFitted") }}
                    </p>
                  </div>
                </template>
              </AsyncData>
            </FormTab>
          </template>
        </FormTabs>
      </div>
    </form>

    <template v-if="editable" #footer>
      <!-- Named where it is saved; the label stays as the field's accessible name. -->
      <FormInput
        v-if="flightReady"
        name="loadoutName"
        :label="t('labels.vehicleLoadout.loadoutName')"
        :placeholder="t('labels.vehicleLoadout.loadoutName')"
        no-label
        inline
        class="vehicle-loadout__name"
        data-test="vehicle-loadout-name"
      />
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        :form="`vehicle-loadout-${vehicle.id}`"
        :loading="saving"
        :disabled="!flightReady || loadoutPending"
        data-test="vehicle-loadout-save"
      >
        {{ t("actions.vehicleLoadout.saveLoadout") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
