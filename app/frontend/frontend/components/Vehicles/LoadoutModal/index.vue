<script lang="ts">
export default {
  name: "VehicleLoadoutModal",
};
</script>

<script lang="ts" setup>
import { categoryIcon } from "@/frontend/components/Models/Hardpoints/categoryIcon";
import { useForm } from "vee-validate";
import { useQueryClient } from "@tanstack/vue-query";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import SocketBoard from "@/frontend/components/Loadout/SocketBoard/index.vue";
import Picker from "@/frontend/components/Loadout/Picker/index.vue";
import Comparison from "./Comparison/index.vue";
import { VehicleLoadoutTabsEnum } from "./types";
import { moduleSlots } from "./moduleSlots";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";
import { useFittingDiff } from "@/frontend/composables/useFittingDiff";
import { useModuleSockets } from "@/frontend/composables/useModuleSockets";
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
  useModelModules as useModelModulesQuery,
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

const savedValues = (): LoadoutValues => ({
  loadoutName: editedLoadout.value?.name ?? "",
  fittedModules: Object.fromEntries(
    (editedLoadout.value?.items || [])
      .filter(
        (item) => item.itemType === VehicleLoadoutItemTypeEnum.MODEL_MODULE,
      )
      .map((item) => [item.slotPath, item.itemId]),
  ),
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

// Components a later version of this editor will cover, shown so the tab strip
// already says where it is headed.

const systemTabs = computed(() => [
  {
    id: "radar",
    label: t("labels.vehicleLoadout.tabs.radar"),
    icon: categoryIcon("radar"),
  },
  {
    id: "coolers",
    label: t("labels.vehicleLoadout.tabs.coolers"),
    icon: categoryIcon("cooler"),
  },
  {
    id: "lifeSupport",
    label: t("labels.vehicleLoadout.tabs.lifeSupport"),
    icon: categoryIcon("lifesupport"),
  },
  {
    id: "powerPlants",
    label: t("labels.vehicleLoadout.tabs.powerPlants"),
    icon: categoryIcon("powerplant"),
  },
  {
    id: "shields",
    label: t("labels.vehicleLoadout.tabs.shields"),
    icon: categoryIcon("shieldgenerator"),
  },
]);

const propulsionWeaponTabs = computed(() => [
  {
    id: "quantumDrives",
    label: t("labels.vehicleLoadout.tabs.quantumDrives"),
    icon: categoryIcon("quantumdrive"),
  },
  {
    id: "flightBlades",
    label: t("labels.vehicleLoadout.tabs.flightBlades"),
    icon: categoryIcon("controller"),
  },
  {
    id: "missiles",
    label: t("labels.vehicleLoadout.tabs.missiles"),
    icon: categoryIcon("missile_racks"),
  },
  {
    id: "weapons",
    label: t("labels.vehicleLoadout.tabs.weapons"),
    icon: categoryIcon("weapons"),
  },
]);

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

// The ship's figures under the fitting as it stands, each with its change
// against the loadout as saved.
const shipFigures = computed(() =>
  rows(
    metrics(
      hullCargo.value,
      modulesFor(Object.values(savedValues().fittedModules)),
    ),
    metrics(hullCargo.value, modulesFor(fittedModuleIds.value)),
  ),
);

const slots = computed(() => moduleSlots(modules.value));

const moduleSockets = useModuleSockets();

const socketGroups = computed(() =>
  moduleSockets.groups(modules.value, fittedModules.value || {}, {
    fittedOnly: !props.editable,
  }),
);

/**
 * The socket the picker fills. None until one is picked, so the editor opens on
 * the ship as fitted; picking the active socket again, or pressing outside the
 * picker, closes it.
 */
const activeSlot = ref<string>();

const pickerOpen = computed(() => props.editable && !!activeSlot.value);

const fitted = computed(() => fittedModules.value || {});

const pickerHost = ref<HTMLElement>();

const picker = ref<InstanceType<typeof Picker>>();

const socketButton = (slot: string) =>
  pickerHost.value?.querySelector<HTMLElement>(
    `[data-test="loadout-socket-${slot}"]`,
  );

const onSocketSelect = async (slot: string) => {
  const opening = activeSlot.value !== slot;

  activeSlot.value = opening ? slot : undefined;
  hovered.value = undefined;

  // On desktop the picker comes after every socket in the page's order, so
  // the keyboard is handed to it rather than left to tab its way there.
  if (opening) {
    await nextTick();
    picker.value?.focus();
  }
};

const pickerOptions = computed(() =>
  activeSlot.value
    ? moduleSockets.options(
        modules.value,
        activeSlot.value,
        fitted.value[activeSlot.value],
        props.vehicle.modelModuleIds,
      )
    : [],
);

const pickerSorts = computed(() => moduleSockets.sorts(pickerOptions.value));

// The phone and the desktop place the picker apart; both take these.
const pickerBindings = computed(() => ({
  title: moduleSockets.slotLabel(activeSlot.value || ""),
  options: pickerOptions.value,
  selectedId: activeSlot.value ? fitted.value[activeSlot.value] : undefined,
  sorts: pickerSorts.value,
}));

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

const onPick = (moduleId: string | null) => {
  const slot = activeSlot.value;
  if (!slot) return;

  const next = { ...fitted.value };
  if (moduleId) {
    next[slot] = moduleId;
  } else {
    delete next[slot];
  }
  fittedModules.value = next;

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
    !!pickerHost.value
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

const comparison = computed(() => {
  const slot = activeSlot.value;
  if (!slot) {
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

  const items: VehicleLoadoutItemInput[] = Object.entries(
    values.fittedModules,
  ).map(([slotPath, itemId]) => ({
    slotPath,
    itemType: VehicleLoadoutItemTypeEnum.MODEL_MODULE,
    itemId,
  }));
  // A cleared name goes back to the default the server gives.
  const name = values.loadoutName.trim();
  const target = createdLoadout.value ?? editedLoadout.value;

  // What this editor does not show yet stays, as long as the slot it sits in
  // is still fitted.
  const fittedPaths = items.map((item) => item.slotPath);
  const kept = (target?.items || []).filter(
    (item) =>
      item.itemType !== VehicleLoadoutItemTypeEnum.MODEL_MODULE &&
      (!item.slotPath.includes("/") ||
        fittedPaths.includes(
          item.slotPath.slice(0, item.slotPath.lastIndexOf("/")),
        )),
  );
  items.push(
    ...kept.map(({ slotPath, itemType, itemId }) => ({
      slotPath,
      itemType,
      itemId,
    })),
  );

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
      class="vehicle-loadout"
      :style="backdrop ? { '--loadout-backdrop': `url(${backdrop})` } : {}"
      data-test="vehicle-loadout-form"
      @submit.prevent="onSubmit"
    >
      <aside class="vehicle-loadout__ship" data-test="vehicle-loadout-ship">
        <p class="vehicle-loadout__model">
          <!-- eslint-disable-next-line vue/no-v-html -->
          <span v-html="vehicle.model.manufacturer?.name" />
          <strong>{{ vehicle.model.name }}</strong>
        </p>
        <dl class="vehicle-loadout__figures">
          <div
            v-for="figure in shipFigures"
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
          :sync-url="false"
          horizontal
          active-label-only
        >
          <FormTab
            v-for="upcoming in systemTabs"
            :id="upcoming.id"
            :key="upcoming.id"
            :label="upcoming.label"
            :icon="upcoming.icon"
            :hint="t('labels.vehicleLoadout.comingSoon')"
            disabled
          />

          <FormTab
            :id="VehicleLoadoutTabsEnum.MODULES"
            :label="t('labels.vehicleLoadout.tabs.modules')"
            :icon="categoryIcon('module')"
            :fields="['fittedModules']"
            :disabled="!flightReady || !vehicle.model.hasModules"
            :hint="modulesHint"
          >
            <AsyncData :async-status="modulesAsyncStatus">
              <template #resolved>
                <div
                  ref="pickerHost"
                  class="vehicle-loadout__category"
                  :class="{
                    'vehicle-loadout__category--picking': pickerOpen && !mobile,
                  }"
                >
                  <div
                    v-if="flightReady && slots.length"
                    class="vehicle-loadout__sockets"
                    data-test="vehicle-loadout-fitted"
                  >
                    <SocketBoard
                      :active="activeSlot"
                      :groups="socketGroups"
                      :editable="editable"
                      @update:active="onSocketSelect"
                    >
                      <template v-if="pickerOpen && mobile" #active>
                        <Picker
                          :key="activeSlot"
                          ref="picker"
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
                    v-if="pickerOpen && !mobile"
                    :key="activeSlot"
                    ref="picker"
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
            v-for="upcoming in propulsionWeaponTabs"
            :id="upcoming.id"
            :key="upcoming.id"
            :label="upcoming.label"
            :icon="upcoming.icon"
            :hint="t('labels.vehicleLoadout.comingSoon')"
            disabled
          />
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
