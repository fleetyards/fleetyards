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
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { VehicleLoadoutTabsEnum } from "@/frontend/components/Vehicles/LoadoutModal/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useModuleContents } from "@/frontend/composables/useModuleContents";
import { useLoadoutSlotLabel } from "@/frontend/composables/useLoadoutSlotLabel";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { useLoadoutEditor } from "@/frontend/composables/useLoadoutEditor";
import { useLoadoutModules } from "@/frontend/composables/useLoadoutModules";
import {
  HardpointCategoryEnum,
  type ModelModule,
  type Vehicle,
  type VehicleLoadout,
  type VehicleLoadoutMinimal,
  type VehiclePublic,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle | VehiclePublic;
  loadout?: VehicleLoadout | VehicleLoadoutMinimal;
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

const { moduleRows, moduleCargo } = useLoadoutModules(
  () => model.value?.slug,
  () => props.loadout,
);

// One section per category with something fitted, so the view grows with
// the categories rather than listing the ones still to come.
const sections = computed(() =>
  [
    {
      key: "modules",
      label: t("labels.vehicleLoadout.tabs.modules"),
      category: HardpointCategoryEnum.MODULE,
      rows: moduleRows.value,
    },
  ].filter((section) => section.rows.length),
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
    props.vehicle.image?.mediumUrl ||
    props.vehicle.image?.url ||
    model.value?.media.storeImage?.mediumUrl ||
    model.value?.media.storeImage?.url,
);

const { loadoutEditorAvailable } = useLoadoutEditor();

// The owner's way into the editor, where the editor is available.
const editVisible = computed(
  () => props.editable && loadoutEditorAvailable(props.vehicle),
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
          <HardpointCategoryIcon
            :category="section.category"
            class="loadout-view__icon"
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
