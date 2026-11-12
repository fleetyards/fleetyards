<script lang="ts">
export default {
  name: "HomeDashboardInventoryPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import {
  type HangarInventoryItem,
  InventoryEntryTypeEnum,
  useHangarAllInventoryItems,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const SHOWN = 5;

const { t, timeDistance } = useI18n();

// The latest entries across every inventory the pilot keeps, ships' holds
// included.
const { data, isLoading, isFetching, isLoadingError } =
  useHangarAllInventoryItems(
    { perPage: String(SHOWN), q: { s: "createdAt desc" } },
    { query: liveQuery },
  );

const entries = computed(() => data.value?.items || []);

const quantityFor = (entry: HangarInventoryItem) =>
  `${entry.entryType === InventoryEntryTypeEnum.WITHDRAWAL ? "−" : "+"}${
    entry.quantity
  } ${t(`labels.logistics.units.${entry.unit}`)}`;

const placeFor = (entry: HangarInventoryItem) =>
  entry.inventory?.vehicleName || entry.inventory?.name;

// A ship's hold shares its slug with every ship of that model, so its entries
// lead to the overview rather than to an inventory of their own.
const linkFor = (entry: HangarInventoryItem) =>
  entry.inventory?.slug && entry.stockSlug && !entry.inventory.vehicleName
    ? {
        name: "hangar-inventory-item",
        params: { inventory: entry.inventory.slug, item: entry.stockSlug },
      }
    : { name: "hangar-inventories" };
</script>

<template>
  <!-- Most pilots keep no inventory, and an empty one has nothing to say. -->
  <DashboardPanel
    v-if="isLoading || isLoadingError || entries.length"
    :title="t('home.dashboard.inventory.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!entries.length"
    :more="{ name: 'hangar-inventories' }"
    :more-label="t('home.dashboard.inventory.all')"
    data-test="home-inventory"
  >
    <div class="home-inventory">
      <RowListItem
        v-for="entry in entries"
        :key="entry.id"
        :to="linkFor(entry)"
        :badges="[{ key: 'quantity', value: quantityFor(entry) }]"
        data-test="home-inventory-entry"
      >
        <template #name>{{ entry.name }}</template>
        <template #sub>
          <template v-if="placeFor(entry)">{{ placeFor(entry) }} · </template>
          <time :datetime="entry.createdAt">
            {{ timeDistance(entry.createdAt) }}
          </time>
        </template>
      </RowListItem>
    </div>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-inventory {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
</style>
