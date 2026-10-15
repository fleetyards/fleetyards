<script lang="ts">
export default {
  name: "VehicleOverviewPaintsCard",
};
</script>

<script lang="ts" setup>
import { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Vehicle,
  type VehiclePaint,
  useVehiclePaints,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const SHOWN_COUNT = 6;

const { t } = useI18n();

const { data: vehiclePaints, isLoading } = useVehiclePaints(
  () => props.vehicle.id,
);

const all = computed<VehiclePaint[]>(() => vehiclePaints.value || []);

const owned = computed(() => all.value.filter((entry) => entry.owned));

// Without a synced paint pledge there is nothing to call "yours", so the card
// offers the model's paints instead of standing empty.
const shown = computed(() =>
  (owned.value.length ? owned.value : all.value).slice(0, SHOWN_COUNT),
);

const { openEditModal } = useVehicleModals();

// Loaners carry the paint they were lent with, as on the configuration card.
const editable = computed(() => !props.vehicle.loaner);

const openPicker = (paintId?: string) =>
  openEditModal(props.vehicle, { tab: VehicleEditTabsEnum.PAINT, paintId });

const thumb = (entry: VehiclePaint) =>
  entry.paint.media.storeImage?.smallUrl || entry.paint.media.storeImage?.url;
</script>

<template>
  <MetricsCard
    v-if="isLoading || all.length"
    :title="
      owned.length
        ? t('labels.vehicleOverview.ownedPaints')
        : t('labels.vehicleOverview.availablePaints')
    "
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
        {{ t("actions.vehicleOverview.choosePaint") }}
      </Btn>
    </template>
    <div class="overview-paints">
      <button
        v-for="entry in shown"
        :key="entry.paint.id"
        type="button"
        class="overview-paints__paint"
        :class="{ 'overview-paints__paint--applied': entry.applied }"
        :aria-pressed="entry.applied"
        :disabled="!editable"
        :aria-label="
          entry.applied
            ? t('labels.vehicleOverview.paintApplied', {
                paint: entry.paint.name,
              })
            : t('actions.vehicleOverview.choosePaint')
        "
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

    &--applied {
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
