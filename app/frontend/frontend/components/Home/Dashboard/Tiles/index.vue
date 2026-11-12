<script lang="ts">
export default {
  name: "HomeDashboardTiles",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import PatchTile from "@/frontend/components/Home/Dashboard/PatchTile/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import { onSaleWishlistParams } from "@/frontend/components/Home/Dashboard/wishlistParams";
import {
  useHangarStats,
  useMyFleetSummaries,
  useWishlist,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { primaryFleet } from "@/frontend/components/Home/Dashboard/primaryFleet";

const { t } = useI18n();

interface Tile {
  key: string;
  icon: string;
  label: string;
  value?: number;
  to: RouteLocationRaw;
}

const { data: stats } = useHangarStats(undefined, { query: liveQuery });

const { data: onSale } = useWishlist(onSaleWishlistParams, {
  query: liveQuery,
});

const { data: fleets } = useMyFleetSummaries({ query: liveQuery });

const onSaleCount = computed(
  () => onSale.value?.meta.pagination?.totalCount || 0,
);

const fleet = computed(() => primaryFleet(fleets.value?.items || []));

// Held back until the stats answer: a tile reading 0 ships while they load is a
// wrong figure, not a placeholder.
const leading = computed<Tile[]>(() => {
  if (!stats.value) return [];

  return [
    {
      key: "hangar",
      icon: "fa-duotone fa-warehouse",
      label: t("home.dashboard.tiles.hangar"),
      value: stats.value.total,
      to: { name: "hangar" },
    },
    {
      key: "wishlist",
      icon: "fa-duotone fa-star",
      label: t("home.dashboard.tiles.wishlist"),
      value: stats.value.wishlistTotal,
      to: { name: "hangar-wishlist" },
    },
  ];
});

// The last tile goes to whatever has something to say: a sale on the
// wishlist first, else the fleet's online count, else no tile rather than a
// zero.
const trailing = computed<Tile | undefined>(() => {
  if (onSaleCount.value) {
    return {
      key: "on-sale",
      icon: "fa-duotone fa-tag",
      label: t("home.dashboard.tiles.onSale"),
      value: onSaleCount.value,
      to: { name: "hangar-wishlist" },
    };
  }

  if (fleet.value?.onlineCount) {
    return {
      key: "fleet",
      icon: "fa-duotone fa-users",
      label: t("home.dashboard.tiles.fleetOnline", {
        fleet: fleet.value.name,
      }),
      value: fleet.value.onlineCount,
      to: { name: "fleet", params: { slug: fleet.value.slug } },
    };
  }

  return undefined;
});
</script>

<template>
  <div class="home-tiles" data-test="home-tiles">
    <router-link
      v-for="tile in leading"
      :key="tile.key"
      :to="tile.to"
      class="home-tiles__tile"
      :data-test="`home-tile-${tile.key}`"
    >
      <StatsPanel
        :label="tile.label"
        :icon="tile.icon"
        :value="tile.value"
        :outer-spacing="false"
      />
    </router-link>
    <PatchTile />
    <router-link
      v-if="trailing"
      :to="trailing.to"
      class="home-tiles__tile"
      :data-test="`home-tile-${trailing.key}`"
    >
      <StatsPanel
        :label="trailing.label"
        :icon="trailing.icon"
        :value="trailing.value"
        :outer-spacing="false"
      />
    </router-link>
  </div>
</template>

<style lang="scss" scoped>
.home-tiles {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 16px;
}

.home-tiles__tile {
  display: block;
  min-width: 0;
  color: inherit;
  text-decoration: none;
}
</style>
