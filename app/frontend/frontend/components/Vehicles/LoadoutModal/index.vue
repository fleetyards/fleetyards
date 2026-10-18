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
import {
  BtnSizesEnum,
  BtnTypesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import { useLoadoutProblems } from "@/frontend/composables/useLoadoutProblems";
import { useLoadoutPlanners } from "@/frontend/composables/useLoadoutPlanners";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import SavedIndicator from "@/shared/components/base/SavedIndicator/index.vue";
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import SocketBoard from "@/frontend/components/Loadout/SocketBoard/index.vue";
import Picker from "@/frontend/components/Loadout/Picker/index.vue";
import Comparison from "./Comparison/index.vue";
import ComponentComparison from "./ComponentComparison/index.vue";
import LoadoutMetrics from "./Metrics/index.vue";
import LoadoutChanges from "@/frontend/components/Loadout/Changes/index.vue";
import { VehicleLoadoutTabsEnum } from "./types";
import { moduleSlots } from "./moduleSlots";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";
import { useLoadoutDiff } from "@/frontend/composables/useLoadoutDiff";
import { useModuleSockets } from "@/frontend/composables/useModuleSockets";
import {
  COMPONENT_TABS,
  type ComponentTab,
  EMPTIED,
  loadoutValues,
  slotName,
  stockModuleValues,
  stockModules,
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
  // On a saved loadout both are saved the moment they are switched, apart from
  // the fitting; on a new one they go with its first save. Fields either way,
  // which the change detection leaves out.
  loadoutPublic: boolean;
  loadoutActive: boolean;
  // A build planned on another site, which a new loadout can be instead of a
  // fitting of its own.
  linkUrl: string;
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

const savedValues = (): LoadoutValues => {
  const { modules, components } = loadoutValues(editedLoadout.value?.items);

  return {
    loadoutName: editedLoadout.value?.name ?? "",
    // A new loadout starts as the server would make it: the ship's default
    // when it has none yet, and then public on a public ship.
    loadoutPublic:
      editedLoadout.value?.public ??
      (!!props.vehicle.public && !props.vehicle.activeLoadout),
    loadoutActive: editedLoadout.value?.active ?? !props.vehicle.activeLoadout,
    linkUrl: "",
    fittedModules: modules,
    fittedComponents: components,
  };
};

const { defineField, handleSubmit, resetForm, resetField, isFieldDirty } =
  useForm<LoadoutValues>({
    initialValues: savedValues(),
  });

// Against the loadout as saved: the fitting, or its name. Undoing a pick
// undoes the change. Visibility is saved as it is switched, so it is never a
// change waiting on the save.
const INSTANT_FIELDS: (keyof LoadoutValues)[] = [
  "loadoutPublic",
  "loadoutActive",
];

const changed = computed(() =>
  (Object.keys(savedValues()) as (keyof LoadoutValues)[])
    .filter((field) => !INSTANT_FIELDS.includes(field) && field !== "linkUrl")
    .some((field) => isFieldDirty(field)),
);

/**
 * Re-seeds the fields rather than the initial values, which vee-validate has
 * already copied by this point: reassigning those did nothing at all, so the
 * modal kept answering for whichever ship it was first opened for.
 *
 * A pending choice wins over the refresh, or a background refetch of the hangar
 * would discard what you had just picked and not yet saved.
 */
watch([() => props.vehicle, () => editedLoadout.value?.updatedAt], () => {
  if (changed.value) {
    return;
  }

  resetForm({ values: savedValues() });
});

const [fittedModules] = defineField("fittedModules");

const [fittedComponents] = defineField("fittedComponents");

const [loadoutPublic] = defineField("loadoutPublic");

const [loadoutActive] = defineField("loadoutActive");

const [linkUrl] = defineField("linkUrl");

// A new loadout can be a link to a build planned elsewhere instead of a
// fitting: the footer switches the modal to the link alone and back.
const linkMode = ref(false);

const linking = computed(() => !editedLoadout.value && linkMode.value);

const linkMissing = computed(() => linking.value && !linkUrl.value?.trim());

const { erkulUrl, spviewerUrl } = useLoadoutPlanners(() => props.vehicle.model);

const loadoutProblems = useLoadoutProblems(
  () => props.vehicle.id,
  () => editedLoadout.value?.id,
  () => props.editable,
);

// The refused items the fitting still holds: picking something else for the
// slot settles one, and a save takes out the rest.
const refusedItems = computed(() =>
  loadoutProblems.problems.value.filter((problem) => {
    if (problem.itemType === VehicleLoadoutItemTypeEnum.MODEL_MODULE) {
      return fittedModules.value?.[problem.slotPath] === problem.itemId;
    }

    const held = fittedComponents.value?.[problem.slotPath];
    return problem.itemType === VehicleLoadoutItemTypeEnum.EMPTY
      ? held === EMPTIED
      : held === problem.itemId;
  }),
);

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

// Below this the picker opens under the socket it fills rather than beside the
// board, where a phone has no room for it.
const mobile = useMobile();

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
  groups: loadoutProblems.markRefused(
    fitting.groups(componentTree.value, tab, {
      fittedOnly: !props.editable,
      saved: props.editable ? savedTree.value : undefined,
    }),
    refusedItems.value,
  ),
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

const loadoutDiff = useLoadoutDiff(fitting);

// Each fitting measured once, and the saved one only when it changes, rather
// than both again for every card on every pick.
const measuredNow = computed(() =>
  loadoutDiff.measure({
    hullCargo: hullCargo.value,
    modules: modulesFor(fittedModuleIds.value),
    hardpoints: modelHardpoints.value ?? [],
    tree: componentTree.value,
    weaponPoolSize: model.value?.metrics.weaponPoolSize,
  }),
);

const measuredSaved = computed(() =>
  loadoutDiff.measure({
    hullCargo: hullCargo.value,
    modules: modulesFor(Object.values(savedValues().fittedModules)),
    hardpoints: modelHardpoints.value ?? [],
    tree: savedTree.value,
    weaponPoolSize: model.value?.metrics.weaponPoolSize,
  }),
);

const figures = computed(() =>
  loadoutDiff.diff(measuredSaved.value, measuredNow.value, COMPONENT_TABS),
);

// The ship as the game files deliver it: the modules it comes with, and the
// stock part in every other slot.
const measuredStock = computed(() =>
  loadoutDiff.measure({
    hullCargo: hullCargo.value,
    modules: stockModules(modules.value),
    hardpoints: modelHardpoints.value ?? [],
    tree: fitting.resolve(
      hullSlots.value ?? [],
      stockModuleValues(modules.value),
    ),
    weaponPoolSize: model.value?.metrics.weaponPoolSize,
  }),
);

// What the fitting on screen changes against the stock ship, as the loadout's
// page and read view list it.
const changesFromStock = computed(
  () =>
    loadoutDiff.diff(measuredStock.value, measuredNow.value, COMPONENT_TABS)
      .changed,
);

// The open tab's figures, each with how far it moved from the saved loadout.
const tabMetrics = computed(() => {
  if (currentTab.value === VehicleLoadoutTabsEnum.MODULES) {
    return {
      title: t("labels.vehicleLoadout.tabs.modules"),
      metrics: figures.value.modules,
    };
  }

  // Until the ship's hardpoints are in, a card would show a tab's own figures
  // and then grow its tiles under them.
  const metrics = currentTab.value && figures.value.tabs[currentTab.value];
  if (!metrics || !modelHardpoints.value?.length) return undefined;

  return {
    title: t(`labels.vehicleLoadout.tabs.${currentTab.value}`),
    metrics,
  };
});

/**
 * Everything the changes moved against the saved loadout, on every tab: a
 * summary of all that was done, in the words the tiles use, so a swap is never
 * out of sight on the tab it was not made on.
 */
const changedFigures = computed(() => figures.value.changed);

const slots = computed(() => moduleSlots(modules.value));

const moduleSockets = useModuleSockets();

const socketGroups = computed(() =>
  loadoutProblems.markRefused(
    moduleSockets.groups(modules.value, fittedModules.value || {}, {
      fittedOnly: !props.editable,
      saved: props.editable ? savedValues().fittedModules : undefined,
      contents: fitting.moduleContents,
    }),
    refusedItems.value,
  ),
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

// The ports above the active slot, whose tags a part in it may demand.
const ancestorIds = computed(() => {
  const path = activeComponentSlot.value?.path;
  if (!path) return [];

  const names = path.split("/");
  return names
    .slice(1)
    .map((_, depth) =>
      fitting.find(componentTree.value, names.slice(0, depth + 1).join("/")),
    )
    .map((above) => above?.slot.hardpointId)
    .filter((id): id is string => !!id);
});

const {
  data: componentOptions,
  isPending: componentOptionsPending,
  isPlaceholderData: componentOptionsStale,
} = useHardpointLoadoutOptions(
  () => activeComponentSlot.value?.slot.hardpointId ?? "",
  // What the slot came with, the ship it is on and the ports above it, which a
  // port inside a part cannot tell the server.
  () => ({
    stockId: activeComponentSlot.value?.slot.stock?.id,
    modelSlug: model.value.slug,
    ancestorIds: ancestorIds.value,
  }),
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

  // The module the slot already holds: nothing changes, and what sits in it
  // stays.
  if ((itemId ?? undefined) === fitted.value[slot]) {
    void closePicker();
    return;
  }

  const swap = () => {
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

  // Parts fitted inside the module go with it and are not brought back by
  // picking it again, so taking them out is asked first.
  const inside = Object.entries(fittedComponents.value || {}).filter(
    ([path, id]) => path.startsWith(`${slot}/`) && id !== EMPTIED,
  ).length;
  if (!inside) {
    swap();
    return;
  }

  displayConfirm({
    text: t("messages.confirm.vehicleLoadout.moduleContents", {
      count: inside,
    }),
    confirmText: itemId
      ? t("actions.vehicleLoadout.swapModule")
      : t("actions.vehicleLoadout.removeModule"),
    tone: AppConfirmTonesEnum.WARNING,
    onConfirm: swap,
  });
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

const { displayAlert, displayConfirm } = useAppNotifications();

const { invalidateHangarQueries, invalidateVehiclePage } =
  useVehicleMutations();

// Whether the saved loadout shows in the public hangar, saved as it is
// switched. Settled as the field's starting value either way, so it never
// counts as a change the fitting's save is waiting on.
// The list the loadouts tab shows, set from the answer at once rather than
// left to the refetch the invalidation starts.
const updateCachedLoadouts = (
  change: (loadout: VehicleLoadout) => VehicleLoadout,
) =>
  queryClient.setQueryData<VehicleLoadout[]>(
    getVehicleLoadoutsQueryKey(props.vehicle.id),
    (list) => list?.map(change),
  );

// One write at a time, the switch held while it runs, so an earlier answer can
// never land over a later choice; "saved" shows only once the server agrees.
const savingPublic = ref(false);

const publicSaved = ref<InstanceType<typeof SavedIndicator>>();

const onTogglePublic = async (value: boolean) => {
  const loadout = editedLoadout.value;
  if (!loadout || savingPublic.value) return;

  savingPublic.value = true;

  try {
    await updateVehicleLoadout(props.vehicle.id, loadout.id, { public: value });
    resetField("loadoutPublic", { value });
    updateCachedLoadouts((entry) =>
      entry.id === loadout.id ? { ...entry, public: value } : entry,
    );
    publicSaved.value?.show();
    await Promise.all([
      invalidateVehiclePage(props.vehicle),
      queryClient.invalidateQueries({
        queryKey: getVehicleLoadoutsQueryKey(props.vehicle.id),
      }),
    ]);
  } catch (error) {
    resetField("loadoutPublic", { value: !value });
    displayAlert({
      text: [t("messages.vehicleLoadout.failure"), firstErrorMessageFrom(error)]
        .filter(Boolean)
        .join(": "),
    });
  } finally {
    savingPublic.value = false;
  }
};

// Switched on as asked, apart from the fitting, like the visibility: the
// active loadout is the one the ship's figures and plaque show. There is no
// switching it off; another loadout is switched on instead.
const activating = ref(false);

const activeSaved = ref<InstanceType<typeof SavedIndicator>>();

const onToggleActive = async (value: boolean) => {
  const loadout = editedLoadout.value;
  if (!loadout || !value || activating.value) return;

  activating.value = true;

  try {
    await activateVehicleLoadout(props.vehicle.id, loadout.id);
    resetField("loadoutActive", { value: true });
    updateCachedLoadouts((entry) => ({
      ...entry,
      active: entry.id === loadout.id,
    }));
    activeSaved.value?.show();
    await Promise.all([
      invalidateHangarQueries(),
      invalidateVehiclePage(props.vehicle),
      queryClient.invalidateQueries({
        queryKey: getVehicleLoadoutsQueryKey(props.vehicle.id),
      }),
    ]);
  } catch (error) {
    resetField("loadoutActive", { value: false });
    displayAlert({
      text: [t("messages.vehicleLoadout.failure"), firstErrorMessageFrom(error)]
        .filter(Boolean)
        .join(": "),
    });
  } finally {
    activating.value = false;
  }
};

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

// A saved loadout needs a change to save, or an item the build refuses to take
// out; a new one saves the ship as it is.
const savable = computed(
  () => !editedLoadout.value || changed.value || !!refusedItems.value.length,
);

// Created by a save whose activation then failed: the retry finishes that one
// rather than creating another beside it.
const createdLoadout = ref<VehicleLoadout>();

/**
 * Writes the loadout being edited, or a new one -- also on request beside the
 * one opened, which then stays as it was saved. A new loadout is switched on
 * only when nothing else is: replacing an active build stays a choice made on
 * the loadouts page.
 */
// A new loadout that links a build: no fitting, the switches as picked.
const saveLink = async (values: LoadoutValues) => {
  saving.value = true;

  try {
    createdLoadout.value ??= await createVehicleLoadout(props.vehicle.id, {
      kind: VehicleLoadoutKindEnum.LINK,
      name: values.loadoutName.trim(),
      url: values.linkUrl.trim(),
      public: values.loadoutPublic,
    });

    if (values.loadoutActive) {
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
    displayAlert({
      text: [t("messages.vehicleLoadout.failure"), firstErrorMessageFrom(error)]
        .filter(Boolean)
        .join(": "),
    });
  } finally {
    saving.value = false;
  }
};

const save = async (values: LoadoutValues, asNew: boolean) => {
  if (
    !props.editable ||
    !flightReady.value ||
    loadoutPending.value ||
    !(asNew ? changed.value : savable.value)
  ) {
    return;
  }

  if (!asNew && linking.value) {
    if (!linkMissing.value) await saveLink(values);
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

  const refusedPaths = new Set(
    refusedItems.value.map((problem) => problem.slotPath),
  );

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
  ].filter((item) => !refusedPaths.has(item.slotPath));
  // A cleared name goes back to the default the server gives, and so does the
  // opened loadout's own name on a copy of it, which would clash.
  const typed = values.loadoutName.trim();
  const name = asNew && typed === editedLoadout.value?.name ? "" : typed;
  const target = asNew
    ? createdLoadout.value
    : (createdLoadout.value ?? editedLoadout.value);

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
        // A copy takes the server's default, not the switches of the loadout
        // it was copied from.
        ...(asNew ? {} : { public: values.loadoutPublic }),
        items,
      });
    }

    const activate = asNew
      ? !props.vehicle.activeLoadout
      : !editedLoadout.value && values.loadoutActive;

    if (createdLoadout.value && activate) {
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
};

const onSubmit = handleSubmit((values) => save(values, false));

const onSaveAsNew = handleSubmit((values) => save(values, true));
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

      <aside
        v-show="!linking"
        class="vehicle-loadout__ship"
        data-test="vehicle-loadout-ship"
      >
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

        <LoadoutChanges
          v-if="changedFigures.length"
          :title="t('labels.loadoutPicker.changed')"
          :figures="changedFigures"
          test-id="vehicle-loadout-changes"
        />

        <LoadoutChanges
          v-if="changesFromStock.length"
          :title="t('labels.vehicleLoadout.againstStock')"
          :figures="changesFromStock"
          test-id="vehicle-loadout-changes-from-stock"
        />
      </aside>

      <div class="vehicle-loadout__panel">
        <!-- Enter in the name names the loadout; saving it is the button's. -->
        <div
          v-if="editable && flightReady"
          class="vehicle-loadout__identity"
          data-test="vehicle-loadout-identity"
          @keydown.enter.prevent
        >
          <FormInput
            name="loadoutName"
            :label="t('labels.vehicleLoadout.loadoutName')"
            :placeholder="t('labels.vehicleLoadout.loadoutName')"
            no-label
            inline
            class="vehicle-loadout__name"
            data-test="vehicle-loadout-name"
          />
          <FormToggle
            :model-value="loadoutPublic"
            name="loadoutPublic"
            :label="t('labels.loadout.public')"
            :disabled="savingPublic"
            no-placeholder
            class="vehicle-loadout__switch"
            data-test="vehicle-loadout-public"
            @update:model-value="onTogglePublic"
          />
          <SavedIndicator v-if="editedLoadout" ref="publicSaved" />
          <FormToggle
            :model-value="loadoutActive"
            name="loadoutActive"
            :label="t('labels.loadout.active')"
            :disabled="activating || (!!editedLoadout && editedLoadout.active)"
            no-placeholder
            class="vehicle-loadout__switch"
            data-test="vehicle-loadout-active"
            @update:model-value="onToggleActive"
          />
          <SavedIndicator v-if="editedLoadout" ref="activeSaved" />
        </div>

        <div
          v-if="editable && flightReady && linking"
          class="vehicle-loadout__link"
          data-test="vehicle-loadout-link"
          @keydown.enter.prevent
        >
          <FormInput
            name="linkUrl"
            :label="t('labels.vehicleLoadout.linkBuild')"
            :placeholder="t('labels.loadout.urlPlaceholder')"
            class="vehicle-loadout__link-url"
            data-test="vehicle-loadout-link-url"
          />
          <div v-if="erkulUrl || spviewerUrl" class="vehicle-loadout__planners">
            <Btn
              v-if="erkulUrl"
              :href="erkulUrl"
              :size="BtnSizesEnum.SM"
              class="erkul-link"
            >
              <i />
              {{ t("labels.hardpoints.erkul") }}
            </Btn>
            <Btn
              v-if="spviewerUrl"
              :href="spviewerUrl"
              :size="BtnSizesEnum.SM"
              class="spviewer-link"
            >
              <i />
              {{ t("labels.hardpoints.spviewer") }}
            </Btn>
          </div>
        </div>

        <p
          v-if="!flightReady"
          class="vehicle-loadout__hint"
          data-test="vehicle-loadout-not-flight-ready"
        >
          {{ t("labels.vehicleLoadout.notFlightReady") }}
        </p>

        <Alert
          v-if="refusedItems.length"
          :variant="AlertVariantsEnum.WARNING"
          :size="AlertSizesEnum.COMPACT"
          :title="t('labels.vehicleLoadout.refused.title')"
          data-test="vehicle-loadout-refused"
        >
          <p>{{ t("labels.vehicleLoadout.refused.removedOnSave") }}</p>
          <ul class="vehicle-loadout__refused">
            <li v-for="problem in refusedItems" :key="problem.slotPath">
              {{ loadoutProblems.describe(problem) }}
            </li>
          </ul>
        </Alert>

        <FormTabs
          v-show="!linking"
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
      <Btn
        v-if="flightReady && !editedLoadout"
        :variant="BtnVariantsEnum.GHOST"
        class="vehicle-loadout__mode"
        data-test="vehicle-loadout-mode"
        @click="linkMode = !linkMode"
      >
        <i
          :class="
            linkMode ? 'fa-duotone fa-screwdriver-wrench' : 'fa-duotone fa-link'
          "
        />
        {{
          linkMode
            ? t("actions.vehicleLoadout.createOnFleetyards")
            : t("actions.vehicleLoadout.linkInstead")
        }}
      </Btn>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        :form="`vehicle-loadout-${vehicle.id}`"
        :loading="saving"
        :disabled="!flightReady || loadoutPending || !savable || linkMissing"
        data-test="vehicle-loadout-save"
      >
        {{ t("actions.vehicleLoadout.saveLoadout") }}
      </Btn>
      <Btn
        v-if="editedLoadout && changed"
        :loading="saving"
        :disabled="!flightReady || loadoutPending"
        data-test="vehicle-loadout-save-as-new"
        @click="onSaveAsNew"
      >
        {{ t("actions.vehicleLoadout.saveAsNewLoadout") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
