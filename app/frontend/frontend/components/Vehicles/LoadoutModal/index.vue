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
import Specs from "@/frontend/components/Vehicles/Overview/Specs/index.vue";
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import VehiclePaintPicker from "@/frontend/components/Vehicles/PaintPicker/index.vue";
import Addons from "./Addons/index.vue";
import Packages from "./Packages/index.vue";
import { VehicleLoadoutTabsEnum } from "./types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import {
  type Vehicle,
  type VehicleUpdateInput,
  getVehiclePaintsQueryKey,
  useModelModules as useModelModulesQuery,
  useModelModulePackages as useModelModulePackagesQuery,
  useModelPaints as useModelPaintsQuery,
  useModelUpgrades as useModelUpgradesQuery,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
  editable?: boolean;
  tab?: VehicleLoadoutTabsEnum;
  paintId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
  tab: undefined,
  paintId: undefined,
});

const { t } = useI18n();

type LoadoutValues = Pick<
  VehicleUpdateInput,
  "modelPaintId" | "modelModuleIds" | "modelUpgradeIds"
>;

const savedValues = (): LoadoutValues => ({
  modelPaintId: props.vehicle.paint?.id ?? null,
  modelModuleIds: [...props.vehicle.modelModuleIds],
  modelUpgradeIds: [...props.vehicle.modelUpgradeIds],
});

const LOADOUT_FIELDS = Object.keys(savedValues()) as (keyof LoadoutValues)[];

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
watch(
  () => props.vehicle,
  () => {
    if (meta.value.dirty) {
      return;
    }

    resetForm({ values: savedValues() });
  },
);

const [modelPaintId] = defineField("modelPaintId");
const [modelModuleIds] = defineField("modelModuleIds");
const [modelUpgradeIds] = defineField("modelUpgradeIds");

// Set as a pending choice rather than an initial value, so it saves like a pick
// and survives the background refetch the watcher above lets through.
if (props.paintId) {
  modelPaintId.value = props.paintId;
}

const model = computed(() => props.vehicle.model);

const modelSlug = computed(() => model.value?.slug ?? "");

const { data: modulePackages, ...modulePackagesAsyncStatus } =
  useModelModulePackagesQuery(modelSlug);

const { data: modulesData, ...modulesAsyncStatus } =
  useModelModulesQuery(modelSlug);

const { data: upgradesData, ...upgradesAsyncStatus } =
  useModelUpgradesQuery(modelSlug);

const { data: paintsData } = useModelPaintsQuery(modelSlug);

// Three endpoints, three shapes: modules and packages come back paginated under
// `items`, upgrades as a bare array.
const packages = computed(() => modulePackages.value?.items ?? []);
const modules = computed(() => modulesData.value?.items ?? []);
const upgrades = computed(() => upgradesData.value ?? []);

// Picking a paint is a change of the vehicle's look, not something to show to a
// visitor who cannot make it.
const paintsVisible = computed(
  () => props.editable && !!model.value?.hasPaints,
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

const selectedPaint = computed(() =>
  (paintsData.value || []).find((paint) => paint.id === modelPaintId.value),
);

const previewImage = computed(
  () =>
    selectedPaint.value?.media.storeImage?.mediumUrl ||
    selectedPaint.value?.media.storeImage?.url ||
    model.value?.media.storeImage?.mediumUrl ||
    model.value?.media.storeImage?.url,
);

const selectedNames = (
  addons: { id: string; name: string }[],
  ids?: string[] | null,
) =>
  addons
    .filter((addon) => (ids || []).includes(addon.id))
    .map((addon) => addon.name);

const summary = computed(() =>
  [
    {
      key: "paint",
      label: t("labels.vehicleLoadout.tabs.paints"),
      values: selectedPaint.value ? [selectedPaint.value.name] : [],
      visible: paintsVisible.value,
    },
    {
      key: "modules",
      label: t("labels.vehicleLoadout.tabs.modules"),
      values: selectedNames(modules.value, modelModuleIds.value),
      visible: !!model.value?.hasModules,
    },
    {
      key: "upgrades",
      label: t("labels.vehicleLoadout.tabs.upgrades"),
      values: selectedNames(upgrades.value, modelUpgradeIds.value),
      visible: !!model.value?.hasUpgrades,
    },
  ].filter((entry) => entry.visible),
);

const comlink = useComlink();

const queryClient = useQueryClient();

const { displayAlert } = useAppNotifications();

const { useUpdateMutation } = useVehicleMutations();

const vehicle = computed(() => props.vehicle);

const mutation = useUpdateMutation(vehicle);

const changedFields = (values: LoadoutValues) => {
  const saved = savedValues();

  const changes = LOADOUT_FIELDS.reduce<VehicleUpdateInput>((data, field) => {
    if (JSON.stringify(values[field]) !== JSON.stringify(saved[field])) {
      return { ...data, [field]: values[field] };
    }

    return data;
  }, {});

  return Object.keys(changes).length ? changes : undefined;
};

const onSubmit = handleSubmit(async (values) => {
  if (!props.editable) {
    return;
  }

  const changes = changedFields(values);

  if (!changes) {
    comlink.emit("close-modal");
    return;
  }

  await mutation
    .mutateAsync({
      id: props.vehicle.id,
      data: changes,
    })
    .then(async () => {
      if ("modelPaintId" in changes) {
        await queryClient.invalidateQueries({
          queryKey: getVehiclePaintsQueryKey(props.vehicle.id),
        });
      }

      comlink.emit("close-modal");
    })
    .catch(() => {
      displayAlert({ text: t("messages.vehicleLoadout.failure") });
    });
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
              :fields="['modelModuleIds']"
              :disabled="!vehicle.model.hasModules"
            >
              <div class="vehicle-loadout__sections">
                <AsyncData
                  :fullscreen="false"
                  :async-status="modulePackagesAsyncStatus"
                >
                  <template #resolved>
                    <fieldset v-if="packages.length">
                      <legend>
                        <h3>{{ t("labels.model.modulePackages") }}</h3>
                        <span v-if="editable" class="vehicle-loadout__hint">
                          {{ t("addon.packages.hint") }}
                        </span>
                      </legend>
                      <Packages
                        v-model="modelModuleIds"
                        :packages="packages"
                        :editable="editable"
                      />
                    </fieldset>
                  </template>
                </AsyncData>

                <AsyncData
                  :fullscreen="false"
                  :async-status="modulesAsyncStatus"
                >
                  <template #resolved>
                    <fieldset>
                      <legend>
                        <h3>{{ t("labels.model.modules") }}</h3>
                      </legend>
                      <Addons
                        v-model="modelModuleIds"
                        :addons="modules"
                        :editable="editable"
                        :empty-label="t('addon.empty.modules')"
                      />
                    </fieldset>
                  </template>
                </AsyncData>
              </div>
            </FormTab>

            <FormTab
              :id="VehicleLoadoutTabsEnum.UPGRADES"
              :label="t('labels.vehicleLoadout.tabs.upgrades')"
              icon="fa-duotone fa-wrench"
              :fields="['modelUpgradeIds']"
              :disabled="!vehicle.model.hasUpgrades"
            >
              <AsyncData
                :fullscreen="false"
                :async-status="upgradesAsyncStatus"
              >
                <template #resolved>
                  <Addons
                    v-model="modelUpgradeIds"
                    :addons="upgrades"
                    :editable="editable"
                    :empty-label="t('addon.empty.upgrades')"
                  />
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

            <FormTab
              :id="VehicleLoadoutTabsEnum.PAINTS"
              :label="t('labels.vehicleLoadout.tabs.paints')"
              :icon="categoryTabIcon('paints').icon"
              :fields="['modelPaintId']"
              :hidden="!paintsVisible"
            >
              <VehiclePaintPicker
                v-if="paintsVisible"
                v-model="modelPaintId"
                :model-slug="vehicle.model.slug"
                :default-image="vehicle.model.media.storeImage?.smallUrl"
                hide-legend
              />
            </FormTab>
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
            <Specs :model="vehicle.model" />
            <dl class="vehicle-loadout__summary">
              <div
                v-for="entry in summary"
                :key="entry.key"
                class="vehicle-loadout__summary-entry"
                :data-test="`vehicle-loadout-summary-${entry.key}`"
              >
                <dt>{{ entry.label }}</dt>
                <dd>
                  {{
                    entry.values.length
                      ? entry.values.join(", ")
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
      <span v-tooltip="t('labels.vehicleLoadout.comingSoon')">
        <Btn disabled data-test="vehicle-loadout-save-preset">
          {{ t("actions.vehicleLoadout.saveLoadout") }}
        </Btn>
      </span>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        :form="`vehicle-loadout-${vehicle.id}`"
        :loading="mutation.isPending.value"
        data-test="vehicle-loadout-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
