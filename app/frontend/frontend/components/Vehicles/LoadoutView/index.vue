<script lang="ts">
export default {
  name: "VehicleLoadoutView",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import AddonOption from "@/frontend/components/Models/AddonOption/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Specs from "@/frontend/components/Vehicles/Overview/Specs/index.vue";
import { categoryIcon } from "@/frontend/components/Models/Hardpoints/categoryIcon";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { VehicleLoadoutTabsEnum } from "@/frontend/components/Vehicles/LoadoutModal/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useModuleContents } from "@/frontend/composables/useModuleContents";
import { useLoadoutSlotLabel } from "@/frontend/composables/useLoadoutSlotLabel";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  type ModelModule,
  type Vehicle,
  type VehicleLoadoutMinimal,
  type VehiclePublic,
  VehicleLoadoutItemTypeEnum,
  FeatureFlagName,
  useModelModules as useModelModulesQuery,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle | VehiclePublic;
  loadout?: VehicleLoadoutMinimal;
  // The owner, who gets a way into the editor from here.
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  loadout: undefined,
  editable: false,
});

const { t } = useI18n();

const { contents } = useModuleContents();

const { slotLabel } = useLoadoutSlotLabel();

const model = computed(() => props.vehicle.model);

const modelSlug = computed(() => model.value?.slug ?? "");

const { data: modulesData } = useModelModulesQuery(modelSlug);

const modules = computed(() => modulesData.value?.items ?? []);

const items = computed(() => props.loadout?.items ?? []);

const moduleRows = computed(() =>
  items.value
    .filter((item) => item.itemType === VehicleLoadoutItemTypeEnum.MODEL_MODULE)
    .map((item) => ({
      slotPath: item.slotPath,
      module: modules.value.find((mod) => mod.id === item.itemId),
    }))
    .filter((row): row is { slotPath: string; module: ModelModule } =>
      Boolean(row.module),
    )
    .sort((a, b) => a.slotPath.localeCompare(b.slotPath)),
);

// One section per category with something fitted, so the view grows with
// the categories rather than listing the ones still to come.
const sections = computed(() =>
  [
    {
      key: "modules",
      label: t("labels.vehicleLoadout.tabs.modules"),
      icon: categoryIcon("module"),
      rows: moduleRows.value,
    },
  ].filter((section) => section.rows.length),
);

const moduleCargo = computed(() =>
  moduleRows.value.reduce(
    (total, row) => total + (row.module.metrics?.cargo || 0),
    0,
  ),
);

const badges = (mod: ModelModule) =>
  mod.stock
    ? [
        {
          key: "stock",
          label: t("labels.vehicleLoadout.stock"),
          variant: PillVariantsEnum.NEUTRAL,
        },
      ]
    : [];

const previewImage = computed(
  () =>
    props.vehicle.paint?.media.storeImage?.mediumUrl ||
    props.vehicle.paint?.media.storeImage?.url ||
    model.value?.media.storeImage?.mediumUrl ||
    model.value?.media.storeImage?.url,
);

const { isFeatureEnabled } = useFeatures();

// The owner's way into the editor, once the editor is switched on.
const editVisible = computed(
  () => props.editable && isFeatureEnabled(FeatureFlagName.LOADOUT_EDITOR),
);

const comlink = useComlink();

const { openLoadoutModal } = useVehicleModals();

const edit = () => {
  comlink.emit("close-modal");
  openLoadoutModal(props.vehicle, {
    editable: true,
    loadoutId: props.loadout?.id,
    tab: VehicleLoadoutTabsEnum.MODULES,
  });
};
</script>

<template>
  <Modal
    :title="
      loadout?.name ||
      t('headlines.vehicleLoadout', {
        vehicle: vehicle.name || vehicle.model?.name,
      })
    "
  >
    <div class="loadout-view" data-test="vehicle-loadout-view">
      <div class="loadout-view__ship">
        <img
          v-if="previewImage"
          :src="previewImage"
          :alt="vehicle.model.name"
          class="loadout-view__image"
        />
        <div class="loadout-view__ship-info">
          <p class="loadout-view__model">
            <!-- eslint-disable-next-line vue/no-v-html -->
            <span v-html="vehicle.model.manufacturer?.name" />
            <strong>{{ vehicle.name || vehicle.model.name }}</strong>
          </p>
          <Specs :model="vehicle.model" :module-cargo="moduleCargo" />
        </div>
      </div>

      <section
        v-for="section in sections"
        :key="section.key"
        class="loadout-view__section"
        :data-test="`vehicle-loadout-view-${section.key}`"
      >
        <h3>
          <i
            v-if="section.icon?.kind === 'fa'"
            :class="section.icon.className"
          />
          {{ section.label }}
        </h3>
        <dl class="loadout-view__slots">
          <div
            v-for="row in section.rows"
            :key="row.slotPath"
            class="loadout-view__slot"
          >
            <dt>{{ slotLabel(row.slotPath) }}</dt>
            <dd>
              <AddonOption
                :name="row.module.name"
                :image="row.module.media?.storeImage?.smallUrl"
                :contents="row.module.description || contents(row.module)"
                :badges="badges(row.module)"
                :editable="false"
                test-id="vehicle-loadout-view-item"
              />
            </dd>
          </div>
        </dl>
      </section>

      <p
        v-if="!sections.length"
        class="loadout-view__empty"
        data-test="vehicle-loadout-view-empty"
      >
        {{ t("labels.vehicleLoadout.nothingFitted") }}
      </p>
    </div>

    <template v-if="editVisible" #footer>
      <Btn data-test="vehicle-loadout-view-edit" @click="edit">
        <i class="fa-duotone fa-screwdriver-wrench" />
        {{ t("actions.vehicleLoadout.editLoadout") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
