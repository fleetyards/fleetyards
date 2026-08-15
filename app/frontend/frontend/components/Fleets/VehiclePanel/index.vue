<script lang="ts">
export default {
  name: "FleetVehiclePanel",
};
</script>

<script lang="ts" setup>
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import VehicleOwner from "@/frontend/components/Vehicles/OwnerLabel/index.vue";
import LoadoutMarker from "@/shared/components/LoadoutMarker/index.vue";
import type {
  VehiclePublic,
  Model,
  FleetModelCountsStats,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import type { MemberContact } from "@/frontend/components/base/MemberContactMenu/types";

const { t } = useI18n();

type Props = {
  fleetSlug: string;
  fleetVehicle: VehiclePublic | Model;
  details?: boolean;
  showOwner?: boolean;
  modelCounts?: FleetModelCountsStats;
};

const props = withDefaults(defineProps<Props>(), {
  details: false,
  showOwner: true,
  modelCounts: undefined,
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

const storeImage = computed(() => {
  const vehicle = props.fleetVehicle as VehiclePublic;

  if (vehicle.paint?.media.storeImage) {
    return vehicle.paint.media.storeImage.mediumUrl;
  }

  if (vehicle.upgrade?.media.storeImage) {
    return vehicle.upgrade.media.storeImage.mediumUrl;
  }

  if (model.value?.media.storeImage) {
    return model.value.media.storeImage.mediumUrl;
  }

  return undefined;
});

const loaner = computed(() => {
  return (props.fleetVehicle as VehiclePublic).loaner;
});

const owner = computed<MemberContact | undefined>(() => {
  const vehicle = props.fleetVehicle as VehiclePublic;

  if (!vehicle.username) {
    return undefined;
  }

  return {
    username: vehicle.username,
    rsiHandle: vehicle.userRsiHandle,
    discordProfileUrl: vehicle.userDiscordProfileUrl,
    citizenidProfileUrl: vehicle.userCitizenidProfileUrl,
  };
});

// Only a grouped panel stands for several ships and so needs the owners modal.
// A single vehicle names its own owner - and its `slug` is the vehicle's, which
// the modal, filtering by model slug, would find nothing for.
const ownersModelSlug = computed(() => {
  if ((props.fleetVehicle as VehiclePublic).model) {
    return undefined;
  }

  return props.fleetVehicle.slug;
});

const serial = computed(() => {
  return (props.fleetVehicle as VehiclePublic).serial;
});

const customName = computed(() => {
  if ((props.fleetVehicle as VehiclePublic).model && props.fleetVehicle.name) {
    return props.fleetVehicle.name;
  }

  return null;
});

const modelName = computed(() => model.value.name);

const countLabel = computed(() => {
  if (!props.fleetVehicle.slug) {
    return "";
  }

  const modelCount = props.modelCounts?.modelCounts?.[props.fleetVehicle.slug];

  if (!modelCount) {
    return "";
  }

  return `${modelCount}x `;
});

const filterManufacturerQuery = (manufacturer: string) => {
  return { manufacturerIn: [manufacturer] };
};

const activeLoadout = computed(
  () => (props.fleetVehicle as VehiclePublic).activeLoadout,
);

const route = useRoute();
</script>

<template>
  <ModelPanel
    :id="id"
    :model="model"
    class="fleet-vehicle-panel"
    :details="details"
    :store-image="storeImage"
  >
    <template #heading-title>
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
        <small v-if="serial" class="serial">
          {{ serial }}
        </small>
      </transition>
    </template>

    <template #heading-subtitle>
      <router-link
        v-if="model.manufacturer"
        :to="{
          query: {
            ...route.query,
            ...filterManufacturerQuery(model.manufacturer.slug),
          },
        }"
      >
        {{ model.manufacturer.name }}
      </router-link>
      <template v-if="customName">
        {{ modelName }}
      </template>
    </template>

    <template #heading-actions>
      <span />
    </template>

    <template #default>
      <div
        v-if="loaner"
        v-tooltip="t('labels.vehicle.loaner')"
        class="fleet-vehicle-panel-loaner"
      >
        <i class="fa-light fa-exchange" />
      </div>
      <VehicleOwner
        v-if="showOwner"
        :owner="owner"
        :model-slug="ownersModelSlug"
        :fleet-slug="fleetSlug"
      />
      <LoadoutMarker v-if="activeLoadout" :loadout="activeLoadout" />
    </template>
  </ModelPanel>
</template>

<style lang="scss" scoped>
.fleet-vehicle-panel-loaner {
  position: absolute;
  top: 5px;
  left: 5px;
  padding: 2px 5px;
  background: rgba(0, 0, 0, 0.6);
  border-radius: 3px;
  font-size: 0.85em;
}

.serial {
  font-size: 0.85em;
  opacity: 0.8;
}
</style>
