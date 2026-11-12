<script lang="ts">
export default {
  name: "HomeDashboardShipsPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import ShipTile from "@/frontend/components/Home/Dashboard/ShipTile/index.vue";
import {
  type Vehicle,
  VehicleSortEnum,
  useHangar,
  useMyPatchChanges,
  useSyncRsiHangarLastRead,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import fallbackImage from "@/images/fallback/store_image.webp";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";

const { t, l } = useI18n();

const toVehicle = useVehicleRoute();

// The flagship large, and four more in a square beside it.
const GRID = 4;

// The flagship leads, or the newest ship when none is flagged; the rest
// follow newest first.
const { data, isLoading, isFetching, isLoadingError } = useHangar(
  {
    perPage: String(GRID + 1),
    q: {
      sorts: [VehicleSortEnum.FLAGSHIP_DESC, VehicleSortEnum.CREATED_AT_DESC],
    },
  },
  { query: liveQuery },
);

const vehicles = computed(() => data.value?.items || []);

const hero = computed(() => vehicles.value[0]);

const rest = computed(() => vehicles.value.slice(1));

const remaining = computed(() =>
  Math.max(
    (data.value?.meta.pagination?.totalCount || 0) - vehicles.value.length,
    0,
  ),
);

const { supported: webpSupported } = useWebpCheck();

// The coloured angled render shows the ship itself rather than a scene around
// it, standing on the panel without a card.
const heroImage = computed(() => {
  const media = hero.value?.model.media;

  return (
    media?.angledViewColored?.largeUrl ||
    media?.angledView?.largeUrl ||
    media?.storeImage?.largeUrl ||
    (webpSupported.value ? fallbackImage : fallbackImageJpg)
  );
});

const heroIsRender = computed(() => {
  const media = hero.value?.model.media;

  return !!(media?.angledViewColored?.largeUrl || media?.angledView?.largeUrl);
});

const { data: lastRead } = useSyncRsiHangarLastRead({
  query: { retry: false },
});

// Most builds leave a pilot's ships alone, so the patch has no panel of its
// own: a ship it did change carries a tag, and otherwise nothing says so.
const { data: patchChanges } = useMyPatchChanges({ query: liveQuery });

const changedModelIds = computed(
  () => new Set(patchChanges.value?.ownedModelIds || []),
);

const tagFor = (vehicle: Vehicle) =>
  patchChanges.value && changedModelIds.value.has(vehicle.model.id)
    ? t("home.dashboard.ships.changedIn", {
        version: patchChanges.value.version.split("-")[0],
      })
    : undefined;

const tagsFor = (vehicle: Vehicle) => {
  const tag = tagFor(vehicle);

  return tag ? [{ label: tag }] : [];
};

// A ship the pilot named shows its model; otherwise its maker.
const subFor = (vehicle: Vehicle) =>
  vehicle.name ? vehicle.model.name : vehicle.model.manufacturer?.name;
</script>

<template>
  <DashboardPanel
    :title="t('home.dashboard.ships.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!vehicles.length"
    :more="{ name: 'hangar' }"
    :more-label="t('home.dashboard.ships.open')"
    data-test="home-ships"
  >
    <p v-if="lastRead?.finishedAt" class="home-ships__synced">
      <i class="fa-light fa-arrows-rotate" aria-hidden="true" />
      {{
        t("home.dashboard.ships.synced", {
          time: l(lastRead.finishedAt, "datetime.formats.short"),
        })
      }}
    </p>
    <div v-if="hero" class="home-ships">
      <router-link
        :to="toVehicle('hangar-vehicle', hero)"
        class="home-ships__hero"
        data-test="home-ships-hero"
      >
        <span
          class="home-ships__hero-image"
          :class="{ 'home-ships__hero-image--render': heroIsRender }"
        >
          <img :src="heroImage" alt="" />
        </span>
        <span
          v-if="tagFor(hero)"
          class="home-ships__hero-tag"
          data-test="home-ship-tile-tag"
        >
          {{ tagFor(hero) }}
        </span>
        <span class="home-ships__hero-body">
          <span class="home-ships__hero-name">
            {{ hero.name || hero.model.name }}
          </span>
          <span class="home-ships__hero-sub">{{ subFor(hero) }}</span>
        </span>
      </router-link>
      <div class="home-ships__side">
        <div class="home-ships__grid">
          <ShipTile
            v-for="vehicle in rest"
            :key="vehicle.id"
            :name="vehicle.name || vehicle.model.name"
            :sub="subFor(vehicle)"
            :image="vehicle.model.media.storeImage"
            :tags="tagsFor(vehicle)"
            :to="toVehicle('hangar-vehicle', vehicle)"
          />
        </div>
        <p v-if="remaining" class="home-ships__more">
          {{ t("home.dashboard.ships.more", { count: remaining }) }}
        </p>
      </div>
    </div>
    <template #empty>
      <DashboardEmpty
        icon="fa-warehouse"
        :title="t('home.dashboard.ships.empty.title')"
        :hint="t('home.dashboard.ships.empty.hint')"
      >
        <Btn :size="BtnSizesEnum.SM" :to="{ name: 'hangar' }">
          {{ t("home.dashboard.ships.empty.action") }}
        </Btn>
      </DashboardEmpty>
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
// The flagship comes first in the markup, so it leads on a phone where the two
// stack, and stands to the right of the cards where they sit side by side.
.home-ships {
  display: flex;
  flex-direction: row-reverse;
  flex-wrap: wrap;
  gap: 12px;
}

.home-ships__hero {
  position: relative;
  display: flex;
  flex: 1 1 360px;
  flex-direction: column;
  min-width: 0;
  color: inherit;
  text-decoration: none;

  &:hover .home-ships__hero-name {
    color: var(--color-primary, #428bca);
  }
}

.home-ships__hero-image {
  display: flex;
  flex: 1 1 auto;
  align-items: center;
  justify-content: center;
  min-height: 240px;

  // A store picture, when the ship has no render, is rounded like the cards.
  img {
    display: block;
    width: 100%;
    height: 100%;
    border-radius: 10px;
    object-fit: cover;
  }

  // A render on a transparent ground: shown whole, straight on the panel.
  &--render img {
    max-height: 320px;
    border-radius: 0;
    object-fit: contain;
  }
}

.home-ships__hero-tag {
  position: absolute;
  top: 10px;
  right: 10px;
  padding: 2px 8px;
  border: 1px solid rgb(66 139 202 / 0.6);
  border-radius: 11px;
  background: rgb(26 29 33 / 0.9);
  color: #8dbbe3;
  font-size: 0.625rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  white-space: nowrap;
}

// Right-aligned, to the panel's edge the flagship stands against.
.home-ships__hero-body {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  text-align: right;
  gap: 2px;
  padding: 8px 0 0;
}

.home-ships__hero-name {
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-family: Orbitron, sans-serif;
  font-size: 1.5rem;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.home-ships__hero-sub {
  color: var(--color-text-dim, #959595);
  font-size: 0.75rem;
}

.home-ships__side {
  display: flex;
  flex: 1 1 360px;
  flex-direction: column;
  min-width: 0;
}

.home-ships__grid {
  display: grid;
  flex: 1 1 auto;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  grid-auto-rows: 1fr;
  gap: 12px;
}

.home-ships__synced,
.home-ships__more {
  margin: 0 0 12px;
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;
}

.home-ships__more {
  margin: 12px 0 0;
  text-align: right;
}
</style>
