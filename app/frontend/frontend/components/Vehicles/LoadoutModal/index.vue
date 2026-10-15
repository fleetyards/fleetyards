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
import Specs from "@/frontend/components/Vehicles/Overview/Specs/index.vue";
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import Fitting from "./Fitting/index.vue";
import { VehicleLoadoutTabsEnum } from "./types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import {
  type Vehicle,
  type VehicleLoadoutItemInput,
  ModelProductionStatusEnum,
  VehicleLoadoutItemTypeEnum,
  VehicleLoadoutKindEnum,
  activateVehicleLoadout,
  createVehicleLoadout,
  getShowVehicleQueryKey,
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

const { data: loadoutsData } = useVehicleLoadouts(() => props.vehicle.id, {
  query: { enabled: () => props.editable && !!props.loadoutId },
});

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

  return active?.kind === VehicleLoadoutKindEnum.FLEETYARDS
    ? active
    : undefined;
});

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

const moduleCargo = computed(() =>
  modules.value
    .filter((mod) => fittedModuleIds.value.includes(mod.id))
    .reduce((total, mod) => total + (mod.metrics?.cargo || 0), 0),
);

// Components a later version of this editor will cover, shown so the tab strip
// already says where it is headed.
const categoryTabIcon = (category: string) => {
  const icon = categoryIcon(category);
  return {
    icon: icon?.kind === "fa" ? icon.className : undefined,
    iconSrc: icon?.kind === "svg" ? icon.src : undefined,
  };
};

const systemTabs = computed(() => [
  {
    id: "radar",
    label: t("labels.vehicleLoadout.tabs.radar"),
    ...categoryTabIcon("radar"),
  },
  {
    id: "coolers",
    label: t("labels.vehicleLoadout.tabs.coolers"),
    ...categoryTabIcon("cooler"),
  },
  {
    id: "lifeSupport",
    label: t("labels.vehicleLoadout.tabs.lifeSupport"),
    ...categoryTabIcon("lifesupport"),
  },
  {
    id: "powerPlants",
    label: t("labels.vehicleLoadout.tabs.powerPlants"),
    ...categoryTabIcon("powerplant"),
  },
  {
    id: "shields",
    label: t("labels.vehicleLoadout.tabs.shields"),
    ...categoryTabIcon("shieldgenerator"),
  },
]);

const propulsionWeaponTabs = computed(() => [
  {
    id: "quantumDrives",
    label: t("labels.vehicleLoadout.tabs.quantumDrives"),
    ...categoryTabIcon("quantumdrive"),
  },
  {
    id: "flightBlades",
    label: t("labels.vehicleLoadout.tabs.flightBlades"),
    ...categoryTabIcon("controller"),
  },
  {
    id: "missiles",
    label: t("labels.vehicleLoadout.tabs.missiles"),
    ...categoryTabIcon("missiles"),
  },
  {
    id: "weapons",
    label: t("labels.vehicleLoadout.tabs.weapons"),
    ...categoryTabIcon("weapons"),
  },
]);

const previewImage = computed(
  () =>
    props.vehicle.paint?.media.storeImage?.mediumUrl ||
    model.value?.media.storeImage?.mediumUrl ||
    model.value?.media.storeImage?.url,
);

const fittedNames = computed(() =>
  modules.value
    .filter((mod) => fittedModuleIds.value.includes(mod.id))
    .map((mod) => mod.name),
);

const comlink = useComlink();

const queryClient = useQueryClient();

const { displayAlert } = useAppNotifications();

const { invalidateHangarQueries } = useVehicleMutations();

const saving = ref(false);

/**
 * Writes the loadout being edited, or a new one. A new loadout is switched on
 * only when nothing else is: replacing an active build stays a choice made on
 * the loadouts page.
 */
const onSubmit = handleSubmit(async (values) => {
  if (!props.editable || !flightReady.value) {
    return;
  }

  const items: VehicleLoadoutItemInput[] = Object.entries(
    values.fittedModules,
  ).map(([slotPath, itemId]) => ({
    slotPath,
    itemType: VehicleLoadoutItemTypeEnum.MODEL_MODULE,
    itemId,
  }));
  const name = values.loadoutName.trim() || undefined;
  const target = editedLoadout.value;

  saving.value = true;

  try {
    if (target) {
      await updateVehicleLoadout(props.vehicle.id, target.id, {
        name,
        items,
      });
    } else {
      const loadout = await createVehicleLoadout(props.vehicle.id, {
        kind: VehicleLoadoutKindEnum.FLEETYARDS,
        name,
        items,
      });

      if (!props.vehicle.activeLoadout) {
        await activateVehicleLoadout(props.vehicle.id, loadout.id);
      }
    }

    await Promise.all([
      invalidateHangarQueries(),
      queryClient.invalidateQueries({
        queryKey: getShowVehicleQueryKey(props.vehicle.id),
      }),
      queryClient.invalidateQueries({
        queryKey: getVehicleLoadoutsQueryKey(props.vehicle.id),
      }),
    ]);

    comlink.emit("close-modal");
  } catch {
    displayAlert({ text: t("messages.vehicleLoadout.failure") });
  } finally {
    saving.value = false;
  }
});
</script>

<template>
  <Modal
    v-if="vehicle"
    :title="
      t('headlines.vehicleLoadout', {
        vehicle: vehicle.name || vehicle.model?.name,
      })
    "
  >
    <form
      :id="`vehicle-loadout-${vehicle.id}`"
      class="vehicle-loadout"
      data-test="vehicle-loadout-form"
      @submit.prevent="onSubmit"
    >
      <p
        v-if="!flightReady"
        class="vehicle-loadout__hint"
        data-test="vehicle-loadout-not-flight-ready"
      >
        {{ t("labels.vehicleLoadout.notFlightReady") }}
      </p>

      <FormInput
        v-else-if="editable"
        name="loadoutName"
        :label="t('labels.vehicleLoadout.loadoutName')"
        :placeholder="t('labels.vehicleLoadout.loadoutNamePlaceholder')"
        class="vehicle-loadout__name"
        data-test="vehicle-loadout-name"
      />

      <FormTabs
        :default-tab="tab"
        :sync-url="false"
        horizontal
        active-label-only
      >
        <div class="vehicle-loadout__layout">
          <div class="vehicle-loadout__main">
            <FormTab
              v-for="upcoming in systemTabs"
              :id="upcoming.id"
              :key="upcoming.id"
              :label="upcoming.label"
              :icon="upcoming.icon"
              :icon-src="upcoming.iconSrc"
              :hint="t('labels.vehicleLoadout.comingSoon')"
              disabled
            />

            <FormTab
              :id="VehicleLoadoutTabsEnum.MODULES"
              :label="t('labels.vehicleLoadout.tabs.modules')"
              :icon="categoryTabIcon('module').icon"
              :fields="['fittedModules']"
              :disabled="!vehicle.model.hasModules"
              :hint="
                vehicle.model.hasModules
                  ? undefined
                  : t('labels.vehicleLoadout.unavailable.modules')
              "
            >
              <AsyncData :async-status="modulesAsyncStatus">
                <template #resolved>
                  <fieldset data-test="vehicle-loadout-fitted">
                    <legend>
                      <h3>{{ t("labels.vehicleLoadout.fitted") }}</h3>
                      <span
                        v-if="editable && flightReady"
                        class="vehicle-loadout__hint"
                      >
                        {{ t("labels.vehicleLoadout.fittedHint") }}
                      </span>
                    </legend>
                    <Fitting
                      v-if="flightReady"
                      v-model="fittedModules"
                      :modules="modules"
                      :owned-ids="vehicle.modelModuleIds"
                      :editable="editable"
                    />
                  </fieldset>
                </template>
              </AsyncData>
            </FormTab>

            <FormTab
              v-for="upcoming in propulsionWeaponTabs"
              :id="upcoming.id"
              :key="upcoming.id"
              :label="upcoming.label"
              :icon="upcoming.icon"
              :icon-src="upcoming.iconSrc"
              :hint="t('labels.vehicleLoadout.comingSoon')"
              disabled
            />
          </div>

          <aside
            class="vehicle-loadout__preview"
            data-test="vehicle-loadout-preview"
          >
            <img
              v-if="previewImage"
              :src="previewImage"
              :alt="vehicle.model.name"
              class="vehicle-loadout__image"
            />
            <p class="vehicle-loadout__model">
              <!-- eslint-disable-next-line vue/no-v-html -->
              <span v-html="vehicle.model.manufacturer?.name" />
              <strong>{{ vehicle.model.name }}</strong>
            </p>
            <Specs :model="vehicle.model" :module-cargo="moduleCargo" />
            <dl class="vehicle-loadout__summary">
              <div
                v-if="vehicle.model.hasModules"
                class="vehicle-loadout__summary-entry"
                data-test="vehicle-loadout-summary-modules"
              >
                <dt>{{ t("labels.vehicleLoadout.tabs.modules") }}</dt>
                <dd>
                  {{
                    fittedNames.length
                      ? fittedNames.join(", ")
                      : t("labels.vehicleLoadout.none")
                  }}
                </dd>
              </div>
            </dl>
          </aside>
        </div>
      </FormTabs>
    </form>

    <template v-if="editable" #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        :form="`vehicle-loadout-${vehicle.id}`"
        :loading="saving"
        :disabled="!flightReady"
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
