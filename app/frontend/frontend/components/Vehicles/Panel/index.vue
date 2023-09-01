<template>
  <div>
    <Panel
      v-if="vehicle && model"
      :id="id"
      class="model-panel vehicle-panel"
      :class="`model-panel-${model.slug}`"
      :highlight="vehicle.flagship || highlight"
    >
      <div class="panel-heading">
        <h2 class="panel-title">
          <router-link
            :to="{
              name: 'model',
              params: {
                slug: model.slug,
              },
            }"
          >
            <span v-if="customName">{{ customName }}</span>
            <span v-else>{{ modelName }}</span>
          </router-link>

          <transition name="fade" appear>
            <small v-if="vehicle && vehicle.serial">
              <span v-if="vehicle.serial" class="serial">
                {{ vehicle.serial }}
              </span>
            </small>
          </transition>

          <transition name="fade" appear>
            <small
              v-if="vehicle && vehicle.flagship"
              v-tooltip.right="flagshipTooltip"
            >
              <i class="fa fa-certificate flagship-icon" />
            </small>
          </transition>

          <br />

          <small>
            <router-link :to="manufacturerRoute">
              {{ model.manufacturer?.name }}
            </router-link>
            <template v-if="customName">
              {{ modelName }}
            </template>
          </small>
        </h2>
        <VehicleContextMenu
          v-if="editable && !vehicle.loaner"
          :vehicle="vehicle"
          :editable="editable"
          :wishlist="wishlist"
        />

        <AddToHangar
          v-else-if="!editable"
          :model="model"
          class="panel-add-to-hangar-button"
          variant="panel"
        />
      </div>
      <div
        :class="{
          'no-details': !details,
        }"
        class="panel-image text-center"
      >
        <LazyImage
          v-if="storeImage"
          :to="{ name: 'model', params: { slug: model.slug } }"
          :aria-label="model.name"
          :src="storeImage"
          :alt="model.name"
          class="image"
        >
          <div
            v-if="vehicle.loaner"
            v-tooltip="t('labels.vehicle.loaner')"
            class="loaner-label"
          >
            <i class="fal fa-exchange" />
          </div>
          <div
            v-else-if="!mobile && hasLoaners && loanersHintVisible"
            v-tooltip="loanersTooltip"
            class="loaner-label"
          >
            <i class="fal fa-exchange" />
          </div>
          <div
            v-show="model.onSale"
            v-tooltip="t('labels.model.onSale')"
            class="on-sale"
          >
            <i class="fal fa-dollar-sign" />
          </div>
          <HangarGroups
            :groups="vehicle.hangarGroups"
            class="panel-hangar-groups"
          />
        </LazyImage>
        <div
          v-if="upgradable && vehicle"
          v-tooltip="t('labels.model.addons')"
          class="addons"
          :class="{
            selected: hasAddons,
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
      </div>
      <Collapsed
        :key="`details-${model.slug}-${uuid}-wrapper`"
        :visible="details"
      >
        <div class="production-status">
          <strong class="text-uppercase">
            <template v-if="model.productionStatus">
              {{ t(`labels.model.productionStatus.${model.productionStatus}`) }}
            </template>
            <template v-else>
              {{ t(`labels.not-available`) }}
            </template>
          </strong>
        </div>
        <ModelPanelMetrics :model="model" />
      </Collapsed>
    </Panel>
  </div>
</template>

<script lang="ts" setup>
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import ModelPanelMetrics from "@/frontend/components/Models/PanelMetrics/index.vue";
import VehicleContextMenu from "@/frontend/components/Vehicles/ContextMenu/index.vue";
import HangarGroups from "@/frontend/components/Vehicles/HangarGroups/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import { useMobile } from "@/shared/composables/useMobile";
import type { Vehicle } from "@/services/fyApi";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  vehicle: Vehicle | null;
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

const mobile = useMobile();

const uuid = ref(uuidv4());

onMounted(() => {
  uuid.value = uuidv4();
});

const storeImage = computed(() => {
  if (props.vehicle && props.vehicle.paint) {
    return props.vehicle.paint.storeImageMedium;
  }

  if (props.vehicle && props.vehicle.upgrade) {
    return props.vehicle.upgrade.storeImageMedium;
  }

  return model.value?.storeImageMedium;
});

const modelName = computed(() => {
  return model.value?.name;
});

const model = computed(() => {
  if (!props.vehicle) {
    return undefined;
  }

  return props.vehicle.model;
});

const id = computed(() => {
  if (props.vehicle) {
    return props.vehicle.id;
  }

  return model.value?.slug;
});

const customName = computed(() => {
  if (props.vehicle && props.vehicle.name) {
    return props.vehicle.name;
  }

  return undefined;
});

const route = useRoute();

const flagshipTooltip = computed(() => {
  if (!props.vehicle) {
    return "";
  }

  if (route.name === "hangar") {
    return t("labels.yourFlagship");
  }

  return t("labels.flagship");
});

const hasAddons = computed(() => {
  return (
    props.vehicle &&
    (props.vehicle.modelModuleIds.length ||
      props.vehicle.modelUpgradeIds.length)
  );
});

const upgradable = computed(() => {
  return (
    (props.editable || hasAddons.value) &&
    (model.value?.hasModules || model.value?.hasUpgrades)
  );
});

const loanersTooltip = computed(() => {
  return [
    t("labels.vehicle.hasLoaners"),
    model.value?.loaners.map((loaner) => loaner.name).join(", "),
  ].join(": ");
});

const hasLoaners = computed(() => {
  return model.value?.loaners?.length;
});

const manufacturerRoute = computed(() => {
  return {
    query: {
      q: {
        manufacturerIn: [model.value?.manufacturer?.slug],
      } as unknown as string,
    },
  };
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
</script>

<script lang="ts">
export default {
  name: "VehiclePanel",
};
</script>
