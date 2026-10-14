<script lang="ts">
export default {
  name: "VehicleOverviewAcquireCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import {
  type BuybackPledge,
  type HangarPledgeItem,
  type Vehicle,
  useHangarBuybacks,
  useHangarUpgrades,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const PREVIEW_COUNT = 3;

const { t } = useI18n();
const { formatCents } = useCurrencyFormat();

const slug = computed(() => props.vehicle.model.slug);

const { data: buybacks, isLoading: buybacksLoading } = useHangarBuybacks(
  () => ({
    q: { modelSlugEq: slug.value },
    perPage: String(PREVIEW_COUNT),
  }),
);

const { data: upgrades, isLoading: upgradesLoading } = useHangarUpgrades(
  () => ({
    q: { upgradeToModelSlugEq: slug.value },
    perPage: String(PREVIEW_COUNT),
  }),
);

const buybackItems = computed<BuybackPledge[]>(
  () => buybacks.value?.items ?? [],
);
const upgradeItems = computed<HangarPledgeItem[]>(
  () => upgrades.value?.items ?? [],
);

const buybackCount = computed(
  () =>
    buybacks.value?.meta.pagination?.totalCount ?? buybackItems.value.length,
);
const upgradeCount = computed(
  () =>
    upgrades.value?.meta.pagination?.totalCount ?? upgradeItems.value.length,
);

const loading = computed(() => buybacksLoading.value || upgradesLoading.value);

const price = (value?: number) =>
  value === undefined || value === null
    ? undefined
    : formatCents(Math.round(value * 100), "USD");

// The lists' own filters, so "show all" lands on exactly these.
const buybacksRoute = computed(() => ({
  name: "hangar-buybacks",
  query: { modelSlugEq: slug.value },
}));

const upgradesRoute = computed(() => ({
  name: "hangar-upgrades",
  query: { upgradeToModelSlugEq: slug.value },
}));
</script>

<template>
  <MetricsCard
    v-if="loading || buybackCount || upgradeCount"
    :title="t('labels.vehicleOverview.waysToGetIt')"
    :loading="loading"
    variant="slim"
    data-test="vehicle-overview-acquire"
  >
    <section
      v-if="buybackCount"
      class="overview-acquire__section"
      data-test="vehicle-overview-acquire-buybacks"
    >
      <h3 class="overview-acquire__heading">
        {{ t("labels.buybacks.name") }}
      </h3>
      <ul class="overview-card-rows">
        <li
          v-for="buyback in buybackItems"
          :key="buyback.id"
          class="overview-card-row"
          :class="{ 'overview-acquire__row--unavailable': !buyback.available }"
          data-test="vehicle-overview-acquire-buyback"
        >
          <span class="overview-acquire__name">
            {{ buyback.name }}
            <small v-if="!buyback.available" class="overview-acquire__note">
              {{ t("labels.buybacks.notAvailable") }}
            </small>
          </span>
          <span v-if="price(buyback.price)" class="overview-card-row__aside">
            {{ price(buyback.price) }}
          </span>
        </li>
      </ul>
      <router-link :to="buybacksRoute" class="overview-acquire__more">
        {{
          t("actions.vehicleOverview.showAllMatches", { count: buybackCount })
        }}
      </router-link>
    </section>

    <section
      v-if="upgradeCount"
      class="overview-acquire__section"
      data-test="vehicle-overview-acquire-upgrades"
    >
      <h3 class="overview-acquire__heading">
        {{ t("nav.hangar.upgrades") }}
      </h3>
      <ul class="overview-card-rows">
        <li
          v-for="upgrade in upgradeItems"
          :key="upgrade.id"
          class="overview-card-row"
          data-test="vehicle-overview-acquire-upgrade"
        >
          <span class="overview-acquire__name">
            {{ upgrade.name }}
            <small v-if="upgrade.quantity > 1" class="overview-acquire__note">
              ×{{ upgrade.quantity }}
            </small>
          </span>
          <span
            v-if="price(upgrade.pledgeValue)"
            class="overview-card-row__aside"
          >
            {{ price(upgrade.pledgeValue) }}
          </span>
        </li>
      </ul>
      <router-link :to="upgradesRoute" class="overview-acquire__more">
        {{
          t("actions.vehicleOverview.showAllMatches", { count: upgradeCount })
        }}
      </router-link>
    </section>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "../card.scss";

.overview-acquire {
  &__section + &__section {
    margin-top: 14px;
    padding-top: 14px;
    border-top: 1px solid var(--color-edge-faint);
  }

  &__heading {
    margin: 0 0 8px;
    color: var(--color-text-dim);
    font-size: 0.7rem;
    font-weight: normal;
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }

  &__name {
    min-width: 0;
    overflow-wrap: anywhere;
  }

  &__note {
    margin-left: 6px;
    color: var(--color-text-dim);
  }

  &__row--unavailable &__name {
    color: var(--color-text-dim);
  }

  &__more {
    font-size: 0.85rem;
  }
}
</style>
