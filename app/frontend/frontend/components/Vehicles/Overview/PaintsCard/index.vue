<script lang="ts">
export default {
  name: "VehicleOverviewPaintsCard",
};
</script>

<script lang="ts" setup>
import { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { useVehicleOwnedPaints } from "@/frontend/composables/useVehicleOwnedPaints";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle, type VehiclePaint } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const SHOWN_COUNT = 6;

const { t } = useI18n();

const { all, owned, isLoading } = useVehicleOwnedPaints(() => props.vehicle);

const shown = computed(() => owned.value.slice(0, SHOWN_COUNT));

const { openEditModal } = useVehicleModals();

// The modal offers its paint tab under the same conditions.
const editable = computed(() => !props.vehicle.loaner && !props.vehicle.wanted);

const visible = computed(
  () =>
    isLoading.value ||
    owned.value.length > 0 ||
    (editable.value && all.value.length > 0),
);

const openPicker = (paintId?: string) =>
  openEditModal(props.vehicle, { tab: VehicleEditTabsEnum.PAINT, paintId });

const thumb = (entry: VehiclePaint) =>
  entry.paint.media.storeImage?.smallUrl || entry.paint.media.storeImage?.url;
</script>

<template>
  <MetricsCard
    v-if="visible"
    :title="t('labels.vehicleOverview.ownedPaints')"
    :loading="isLoading"
    variant="slim"
    data-test="vehicle-overview-paints"
  >
    <template #head>
      <Btn
        v-if="editable"
        :size="BtnSizesEnum.SM"
        data-test="vehicle-overview-paints-all"
        @click="openPicker()"
      >
        {{ t("actions.vehicleOverview.editPaints") }}
      </Btn>
    </template>
    <p
      v-if="!isLoading && !owned.length"
      class="overview-card-muted"
      data-test="vehicle-overview-paints-empty"
    >
      {{ t("labels.vehicleOverview.noPaint") }}
    </p>
    <div v-else class="overview-paints">
      <button
        v-for="entry in shown"
        :key="entry.paint.id"
        type="button"
        class="overview-paints__paint"
        :class="{ 'overview-paints__paint--picture': entry.picture }"
        :disabled="!editable"
        data-test="vehicle-overview-paint"
        @click="openPicker(entry.paint.id)"
      >
        <img
          v-if="thumb(entry)"
          :src="thumb(entry)"
          alt=""
          class="overview-paints__image"
        />
        <span v-else class="overview-paints__image" />
        <span class="overview-paints__name">{{ entry.paint.name }}</span>
      </button>
    </div>

    <template #footer>
      <router-link
        :to="{
          name: 'ship',
          params: { slug: vehicle.model.slug },
          hash: '#paints',
        }"
        class="overview-card-footer-link"
        data-test="vehicle-overview-paints-ship"
      >
        {{ t("actions.vehicleOverview.allPaints", { count: all.length }) }}
      </router-link>
    </template>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "../card.scss";

.overview-paints {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
  margin-bottom: 10px;

  &__paint {
    padding: 0;
    overflow: hidden;
    border: 2px solid var(--color-edge-soft);
    border-radius: 6px;
    background: var(--color-gray-black);
    color: inherit;
    text-align: left;
    cursor: pointer;

    &:hover:not(:disabled),
    &:focus-visible {
      border-color: var(--color-edge-strong);
    }

    &--picture {
      border-color: var(--color-gold);
      cursor: default;
    }
  }

  &__image {
    display: block;
    width: 100%;
    height: 64px;
    object-fit: cover;
  }

  &__name {
    display: block;
    padding: 6px 8px;
    overflow: hidden;
    font-size: 0.75rem;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
}
</style>
