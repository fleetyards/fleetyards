<script lang="ts">
export default {
  name: "HomeDashboardStats",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import { onSaleWishlistParams } from "@/frontend/components/Home/Dashboard/wishlistParams";
import {
  useHangarStats,
  useMyFleetSummaries,
  useWishlist,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { primaryFleet } from "@/frontend/components/Home/Dashboard/primaryFleet";

const { t, toNumber } = useI18n();

interface Stat {
  key: string;
  label: string;
  value: number;
  to: RouteLocationRaw;
  title?: string;
}

const { data: hangar } = useHangarStats(undefined, { query: liveQuery });

const { data: onSale } = useWishlist(onSaleWishlistParams, {
  query: liveQuery,
});

const { data: fleets } = useMyFleetSummaries({ query: liveQuery });

const fleet = computed(() => primaryFleet(fleets.value?.items || []));

// Held back until the hangar answers: 0 ships while it loads is a wrong figure,
// not a placeholder. A sale or somebody online only counts when there is one.
const stats = computed<Stat[]>(() => {
  if (!hangar.value) return [];

  const list: Stat[] = [
    {
      key: "hangar",
      label: t("home.dashboard.stats.ships"),
      value: hangar.value.total,
      to: { name: "hangar" },
    },
    {
      key: "wishlist",
      label: t("home.dashboard.stats.wishlist"),
      value: hangar.value.wishlistTotal,
      to: { name: "hangar-wishlist" },
    },
  ];

  const onSaleCount = onSale.value?.meta.pagination?.totalCount || 0;

  if (onSaleCount) {
    list.push({
      key: "on-sale",
      label: t("home.dashboard.stats.onSale"),
      value: onSaleCount,
      to: { name: "hangar-wishlist" },
    });
  }

  if (fleet.value?.onlineCount) {
    list.push({
      key: "fleet",
      label: t("home.dashboard.stats.online"),
      value: fleet.value.onlineCount,
      to: { name: "fleet", params: { slug: fleet.value.slug } },
      title: t("home.dashboard.tiles.fleetOnline", { fleet: fleet.value.name }),
    });
  }

  return list;
});
</script>

<template>
  <div v-if="stats.length" class="home-stats" data-test="home-stats">
    <router-link
      v-for="stat in stats"
      :key="stat.key"
      :to="stat.to"
      :title="stat.title"
      class="home-stats__stat"
      :data-test="`home-stat-${stat.key}`"
    >
      <span class="home-stats__value">{{ toNumber(stat.value) }}</span>
      <span class="home-stats__label">{{ stat.label }}</span>
    </router-link>
  </div>
</template>

<style lang="scss" scoped>
.home-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 28px;
}

.home-stats__stat {
  display: flex;
  flex-direction: column;
  gap: 2px;
  color: inherit;
  text-decoration: none;

  &:hover .home-stats__value {
    color: var(--color-primary, #428bca);
  }
}

.home-stats__value {
  color: var(--color-lifted, #eee);
  font-family: Orbitron, sans-serif;
  font-size: 1.75rem;
  line-height: 1.1;
}

.home-stats__label {
  color: var(--color-text, #c8c8c8);
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
</style>
