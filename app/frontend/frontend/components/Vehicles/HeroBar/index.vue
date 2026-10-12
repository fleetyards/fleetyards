<script lang="ts">
export default {
  name: "VehicleHeroBar",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import VehicleContextMenu from "@/frontend/components/Vehicles/ContextMenu/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { type Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();

const picture = computed(
  () =>
    props.vehicle.image ||
    props.vehicle.paint?.media.storeImage ||
    props.vehicle.upgrade?.media.storeImage ||
    props.vehicle.model.media.storeImage,
);

const title = computed(() => props.vehicle.name || props.vehicle.model.name);

const overviewRoute = computed(() => ({
  name: "hangar-vehicle-overview",
  params: { id: props.vehicle.serial || props.vehicle.id },
}));

const openEditModal = () => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/Vehicles/Modal/index.vue"),
    props: {
      vehicle: props.vehicle,
      wishlist: props.vehicle.wanted,
    },
  });
};
</script>

<template>
  <div class="vehicle-hero-bar" data-test="vehicle-hero-bar">
    <router-link :to="overviewRoute" class="vehicle-hero-bar__identity">
      <img
        v-if="picture?.smallUrl || picture?.url"
        :src="picture.smallUrl || picture.url"
        alt=""
        class="vehicle-hero-bar__thumb"
      />
      <span class="vehicle-hero-bar__text">
        <span class="vehicle-hero-bar__title">
          <i
            v-if="vehicle.flagship"
            class="fa-solid fa-star vehicle-hero-bar__flagship"
            :aria-label="t('labels.vehicle.flagship')"
          />
          {{ title }}
        </span>
        <span class="vehicle-hero-bar__subline">
          <template v-if="vehicle.name">{{ vehicle.model.name }}</template>
          <template v-if="vehicle.serial"> · {{ vehicle.serial }}</template>
          <template v-if="vehicle.location"> · {{ vehicle.location }}</template>
        </span>
      </span>
    </router-link>
    <div v-if="!vehicle.loaner" class="vehicle-hero-bar__actions">
      <Btn
        :aria-label="t('actions.vehicleOverview.edit')"
        @click="openEditModal"
      >
        <i class="fa fa-pencil" />
      </Btn>
      <VehicleContextMenu
        :vehicle="vehicle"
        :wishlist="vehicle.wanted"
        editable
        hide-edit
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.vehicle-hero-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  height: var(--vehicle-hero-bar-h, 64px);
  padding: 0 4px;

  &__identity {
    display: flex;
    align-items: center;
    gap: 12px;
    min-width: 0;
    color: inherit;
  }

  &__thumb {
    flex: none;
    width: 72px;
    height: 44px;
    border-radius: 6px;
    object-fit: cover;
  }

  &__text {
    display: flex;
    flex-direction: column;
    min-width: 0;
  }

  &__title {
    overflow: hidden;
    color: #fff;
    font-family: Orbitron, sans-serif;
    font-size: 1.1rem;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__flagship {
    color: var(--color-gold);
    font-size: 0.8em;
  }

  &__subline {
    overflow: hidden;
    color: var(--color-text-dim);
    font-size: 0.85rem;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__actions {
    display: flex;
    flex: none;
    gap: 8px;
  }
}
</style>
