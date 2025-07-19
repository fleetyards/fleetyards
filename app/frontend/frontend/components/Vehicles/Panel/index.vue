<script lang="ts">
export default {
  name: "VehiclesPanel",
};
</script>

<script lang="ts" setup>
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import VehicleContextMenu from "@/frontend/components/Vehicles/ContextMenu/index.vue";
import HangarGroups from "@/frontend/components/Vehicles/HangarGroups/index.vue";
import {
  type Vehicle,
  type VehiclePublic,
  type Manufacturer,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";

type Props = {
  vehicle: Vehicle | VehiclePublic;
  details?: boolean;
  editable?: boolean;
  wishlist?: boolean;
  highlight?: boolean;
  loanersHintVisible?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  details: false,
  editable: false,
  wishlist: false,
  highlight: false,
  loanersHintVisible: false,
});

const { t } = useI18n();

const image = computed(() => {
  if (props.vehicle.paint && props.vehicle.paint.media.storeImage) {
    return props.vehicle.paint.media.storeImage.mediumUrl;
  }

  if (props.vehicle.upgrade && props.vehicle.upgrade.media.storeImage) {
    return props.vehicle.upgrade.media.storeImage.mediumUrl;
  }

  if (model.value?.media.storeImage) {
    return model.value?.media.storeImage.mediumUrl;
  }
});

const modelName = computed(() => model.value?.name);

const model = computed(() => props.vehicle.model);

const id = computed(() => props.vehicle.id);

const customName = computed(() => {
  if (props.vehicle.name) {
    return props.vehicle.name;
  }

  return undefined;
});

const name = computed(() => {
  if (customName.value) {
    return customName.value;
  }

  return modelName.value;
});

const route = useRoute();

const flagshipTooltip = computed(() => {
  if (route.name === "hangar") {
    return t("labels.yourFlagship");
  }

  return t("labels.flagship");
});

const hasAddons = computed(
  () =>
    props.vehicle.modelModuleIds.length || props.vehicle.modelUpgradeIds.length,
);

const upgradable = computed(
  () =>
    (props.editable || hasAddons.value) &&
    (model.value?.hasModules || model.value?.hasUpgrades),
);

const loanersTooltip = computed(() =>
  [
    t("labels.vehicle.hasLoaners"),
    (model.value?.loaners || []).map((loaner) => loaner.name).join(", "),
  ].join(": "),
);

const hasLoaners = computed(() => model.value?.loaners?.length);

const filterManufacturerQuery = (manufacturer: Manufacturer) => ({
  manufacturerIn: [manufacturer],
});

const comlink = useComlink();

const openAddonsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/AddonsModal/index.vue"),
    props: {
      vehicle: props.vehicle,
      editable: props.editable,
    },
  });
};

const shouldHighlight = computed(() => {
  return props.highlight || (props.vehicle as Vehicle).flagship;
});
</script>

<template>
  <ModelPanel
    :id="id"
    :model="model"
    class="vehicle-panel"
    :details="details"
    :highlight="shouldHighlight"
    :store-image="image"
  >
    <template #heading-title>
      <span class="flex items-baseline gap-1">
        <router-link
          v-tooltip="name"
          :to="{
            name: 'ship',
            params: {
              slug: model.slug,
            },
          }"
          class="truncate"
        >
          <span>{{ name }}</span>
        </router-link>
        <transition name="fade" appear>
          <HeadingSmall
            v-if="vehicle && vehicle.serial"
            class="whitespace-nowrap"
          >
            {{ vehicle.serial }}
          </HeadingSmall>
        </transition>

        <transition name="fade" appear>
          <small
            v-if="(vehicle as Vehicle).flagship"
            v-tooltip.right="flagshipTooltip"
          >
            <i class="fa fa-certificate vehicle-panel-flagship-icon" />
          </small>
        </transition>
      </span>
    </template>
    <template #heading-subtitle>
      <span class="flex items-start gap-1">
        <router-link
          v-if="model.manufacturer"
          :to="{
            query: {
              q: filterManufacturerQuery(
                model.manufacturer,
              ) as unknown as string,
            },
          }"
          class="truncate"
        >
          {{ model.manufacturer.name }}
        </router-link>
        <span v-if="customName">
          {{ modelName }}
        </span>
      </span>
    </template>
    <template #heading-actions>
      <VehicleContextMenu
        v-if="editable && !vehicle.loaner"
        :vehicle="vehicle as Vehicle"
        :editable="editable"
        :wishlist="wishlist"
        :variant="BtnVariantsEnum.LINK"
        class="vehicle-panel--context-menu-button"
      />

      <AddToHangar
        v-else-if="!editable"
        :model="model"
        class="vehicle-panel--add-to-hangar-button"
        variant="panel"
      />
    </template>
    <template #default>
      <div
        v-if="vehicle.loaner"
        v-tooltip="t('labels.vehicle.loaner')"
        class="vehicle-panel-loaner-label"
      >
        <i class="fal fa-exchange" />
      </div>
      <div
        v-else-if="hasLoaners && loanersHintVisible"
        v-tooltip="loanersTooltip"
        class="vehicle-panel-loaner-label"
      >
        <i class="fal fa-exchange" />
      </div>
      <HangarGroups
        :groups="vehicle.hangarGroups"
        class="vehicle-panel-hangar-groups"
      />
      <div
        v-if="upgradable && vehicle"
        v-tooltip="t('labels.model.addons')"
        class="vehicle-panel-addons"
        :class="{
          'vehicle-panel-addons-selected': hasAddons,
        }"
        @click="openAddonsModal"
      >
        <span v-show="hasAddons">
          <i class="fa fa-plus-octagon" />
        </span>
        <span v-show="!hasAddons">
          <i class="far fa-plus-octagon" />
        </span>
      </div>
    </template>
  </ModelPanel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
