<template>
  <div>
    <Panel
      v-if="model"
      :id="id"
      class="model-panel"
      :class="`model-panel-${model.slug}`"
    >
      <div class="panel-heading">
        <h2 class="panel-title">
          <router-link
            :to="{
              name: 'ship',
              params: {
                slug: model.slug,
              },
            }"
          >
            <span v-if="customName">{{ customName }}</span>
            <span v-else>{{ countLabel }}{{ modelName }}</span>
          </router-link>

          <transition name="fade" appear>
            <small v-if="serial">
              <span class="serial">
                {{ serial }}
              </span>
            </small>
          </transition>

          <br />

          <small>
            <router-link
              v-if="model.manufacturer"
              :to="
                {
                  query: {
                    q: filterManufacturerQuery(model.manufacturer.slug),
                  },
                } as any
              "
            >
              {{ model.manufacturer.name }}
            </router-link>
            <template v-if="customName">
              {{ modelName }}
            </template>
          </small>
        </h2>
      </div>
      <div
        :class="{
          'no-details': !details,
        }"
        class="panel-image text-center"
      >
        <LazyImage
          :to="{ name: 'ship', params: { slug: model.slug } }"
          :aria-label="model.name"
          :src="storeImage"
          :alt="model.name"
          class="image"
        >
          <div
            v-if="loaner"
            v-tooltip="t('labels.vehicle.loaner')"
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
        </LazyImage>
        <VehicleOwner
          v-if="showOwner"
          :owner="username"
          :model-slug="fleetVehicle.slug"
          :fleet-slug="fleetSlug"
        />
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
import VehicleOwner from "@/frontend/components/Vehicles/OwnerLabel/index.vue";
import ModelPanelMetrics from "@/frontend/components/Models/PanelMetrics/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import type {
  VehiclePublic,
  Model,
  FleetModelCountsStats,
} from "@/services/fyApi";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/shared/composables/useI18n";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";

const { t } = useI18n();

type Props = {
  fleetSlug: string;
  fleetVehicle: VehiclePublic | Model;
  details?: boolean;
  showOwner?: boolean;
  modelCounts?: FleetModelCountsStats;
};

const props = withDefaults(defineProps<Props>(), {
  details: true,
  showOwner: true,
  modelCounts: undefined,
});

const uuid = ref(uuidv4());

onMounted(() => {
  uuid.value = uuidv4();
});

const { supported: webpSupported } = useWebpCheck();

const storeImage = computed(() => {
  if (paint.value?.media.storeImage) {
    return paint.value.media.storeImage.medium;
  }

  if (upgrade.value?.media.storeImage) {
    return upgrade.value.media.storeImage.medium;
  }

  if (model.value.media.storeImage) {
    return model.value.media.storeImage.medium;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});

const modelName = computed(() => {
  return model.value.name;
});

const loaner = computed(() => {
  return (props.fleetVehicle as VehiclePublic).loaner;
});
const upgrade = computed(() => {
  return (props.fleetVehicle as VehiclePublic).upgrade;
});

const paint = computed(() => {
  return (props.fleetVehicle as VehiclePublic).paint;
});

const username = computed(() => {
  return (props.fleetVehicle as VehiclePublic).username;
});

const serial = computed(() => {
  return (props.fleetVehicle as VehiclePublic).serial;
});

const model = computed(() => {
  if ((props.fleetVehicle as VehiclePublic).model) {
    return (props.fleetVehicle as VehiclePublic).model;
  }

  return props.fleetVehicle as Model;
});

const id = computed(() => {
  if (props.fleetVehicle) {
    return props.fleetVehicle.id;
  }

  return model.value.slug;
});

const customName = computed(() => {
  if ((props.fleetVehicle as VehiclePublic).model && props.fleetVehicle.name) {
    return props.fleetVehicle.name;
  }

  return null;
});

const countLabel = computed(() => {
  if (!props.fleetVehicle.slug) {
    return "";
  }

  const modelCount = props.modelCounts?.modelCounts[props.fleetVehicle.slug];

  if (!modelCount) {
    return "";
  }

  return `${modelCount}x `;
});

const filterManufacturerQuery = (manufacturer: string) => {
  return { manufacturerIn: [manufacturer] };
};
</script>

<script lang="ts">
export default {
  name: "FleetVehiclePanel",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
