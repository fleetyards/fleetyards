<script lang="ts">
export default {
  name: "VehicleOverviewLoadoutsCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Vehicle,
  type VehicleLoadout,
  useVehicleLoadouts,
} from "@/services/fyApi";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const OTHERS_COUNT = 3;

const { t } = useI18n();

const { data: loadouts, isLoading } = useVehicleLoadouts(
  () => props.vehicle.id,
);

const all = computed<VehicleLoadout[]>(() => loadouts.value || []);

const active = computed(() => all.value.find((loadout) => loadout.active));

const others = computed(() =>
  all.value.filter((loadout) => !loadout.active).slice(0, OTHERS_COUNT),
);

// A fleetyards loadout is kept here rather than on another site, so it links
// nowhere and names its kind where a link names its site.
const source = (loadout: VehicleLoadout) =>
  loadout.urlSource ||
  (loadout.url ? undefined : t("labels.loadout.fleetyards"));

const toVehicle = useVehicleRoute();

const loadoutsRoute = computed(() =>
  toVehicle("hangar-vehicle-loadouts", props.vehicle),
);
</script>

<template>
  <MetricsCard
    :title="t('nav.hangar.vehicleLoadouts')"
    :loading="isLoading"
    variant="slim"
    data-test="vehicle-overview-loadouts"
  >
    <p v-if="!isLoading && !all.length" class="overview-card-muted">
      {{ t("texts.vehicleOverview.noLoadouts") }}
    </p>

    <component
      :is="active.url ? 'a' : 'div'"
      v-if="active"
      :href="active.url"
      :target="active.url ? '_blank' : undefined"
      :rel="active.url ? 'noopener' : undefined"
      class="overview-loadouts__active"
      data-test="vehicle-overview-active-loadout"
    >
      <span class="overview-loadouts__active-label">
        {{ t("labels.loadout.active") }}
      </span>
      <span class="overview-loadouts__name">{{ active.name }}</span>
      <span class="overview-card-row__aside">{{ source(active) }}</span>
    </component>

    <ul v-if="others.length" class="overview-card-rows">
      <li v-for="loadout in others" :key="loadout.id" class="overview-card-row">
        <a
          v-if="loadout.url"
          :href="loadout.url"
          target="_blank"
          rel="noopener"
        >
          {{ loadout.name }}
        </a>
        <span v-else>{{ loadout.name }}</span>
        <span class="overview-card-row__aside">{{ source(loadout) }}</span>
      </li>
    </ul>

    <template #footer>
      <router-link :to="loadoutsRoute" class="overview-card-footer-link">
        {{ t("actions.hangar.manageLoadouts") }}
      </router-link>
    </template>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "../card.scss";

.overview-loadouts {
  &__active {
    display: flex;
    flex-direction: column;
    margin-bottom: 10px;
    padding: 10px 12px;
    border: 1px solid rgb(92 184 92 / 0.55);
    border-radius: 8px;
    background: rgb(92 184 92 / 0.08);
    color: inherit;
  }

  &__active-label {
    color: #8fd18f;
    font-size: 0.65rem;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }

  &__name {
    color: #fff;
    font-weight: 600;
  }
}
</style>
