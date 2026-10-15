<script lang="ts">
export default {
  name: "VehicleOverviewAcquireCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import { buybackRsiUrl, rsiHangarUrl } from "@/frontend/utils/rsiPledgeUrls";
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

// The lists' own filters, so the footer lands on exactly these.
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
    <!-- An upgrade already in the hangar costs nothing more, so it comes
         before anything that has to be bought back. -->
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
            <a
              :href="rsiHangarUrl(upgrade)"
              target="_blank"
              rel="noopener"
              class="overview-acquire__link"
              data-test="vehicle-overview-acquire-upgrade-link"
            >
              {{ upgrade.name }}
              <i
                class="fa-light fa-arrow-up-right-from-square"
                aria-hidden="true"
              />
            </a>
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
    </section>

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
            <a
              v-if="buyback.available"
              :href="buybackRsiUrl(buyback)"
              target="_blank"
              rel="noopener"
              class="overview-acquire__link"
              data-test="vehicle-overview-acquire-buyback-link"
            >
              {{ buyback.name }}
              <i
                class="fa-light fa-arrow-up-right-from-square"
                aria-hidden="true"
              />
            </a>
            <template v-else>
              {{ buyback.name }}
              <small class="overview-acquire__note">
                {{ t("labels.buybacks.notAvailable") }}
              </small>
            </template>
          </span>
          <span v-if="price(buyback.price)" class="overview-card-row__aside">
            {{ price(buyback.price) }}
          </span>
        </li>
      </ul>
    </section>

    <template #footer>
      <div class="overview-acquire__footer">
        <router-link
          v-if="upgradeCount"
          :to="upgradesRoute"
          class="overview-card-footer-link"
          data-test="vehicle-overview-acquire-all-upgrades"
        >
          {{
            t("actions.vehicleOverview.allUpgrades", { count: upgradeCount })
          }}
        </router-link>
        <router-link
          v-if="buybackCount"
          :to="buybacksRoute"
          class="overview-card-footer-link"
          data-test="vehicle-overview-acquire-all-buybacks"
        >
          {{
            t("actions.vehicleOverview.allBuybacks", { count: buybackCount })
          }}
        </router-link>
      </div>
    </template>
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

  &__link {
    color: inherit;

    i {
      margin-left: 4px;
      color: var(--color-muted);
      font-size: 0.75em;
    }

    &:hover,
    &:focus-visible {
      color: var(--color-primary);

      i {
        color: inherit;
      }
    }
  }

  &__note {
    margin-left: 6px;
    color: var(--color-text-dim);
  }

  &__row--unavailable &__name {
    color: var(--color-text-dim);
  }

  // Both lists side by side as the card's last row, split down the middle
  // rather than stacked into two rows of the footer.
  &__footer {
    display: flex;

    .overview-card-footer-link {
      flex: 1;
      min-width: 0;
      text-align: center;
    }

    .overview-card-footer-link + .overview-card-footer-link {
      border-left: 1px solid var(--color-edge-soft);
    }

    .overview-card-footer-link:first-child:not(:last-child) {
      border-bottom-right-radius: 0;
    }

    .overview-card-footer-link:last-child:not(:first-child) {
      border-bottom-left-radius: 0;
    }
  }
}
</style>
