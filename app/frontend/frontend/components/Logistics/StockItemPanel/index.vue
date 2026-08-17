<script lang="ts">
export default {
  name: "LogisticsStockItemPanel",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { InventoryStockPosition } from "@/services/fyApi";

type Props = {
  stockItem: InventoryStockPosition;
};

const props = defineProps<Props>();

const { t, l, toNumber } = useI18n();

const quality = computed(() => {
  const { qualityMin, qualityMax } = props.stockItem;

  if (qualityMin == null && qualityMax == null) return undefined;
  if (qualityMin === qualityMax) return String(qualityMin);

  return `${qualityMin} - ${qualityMax}`;
});
</script>

<template>
  <MetricsCard :title="t('labels.logistics.stockItem')">
    <div class="stock-item">
      <div v-if="stockItem.image?.mediumUrl" class="stock-item__image">
        <img :src="stockItem.image.mediumUrl" :alt="stockItem.name" />
      </div>

      <div class="stock-item__metrics">
        <div class="metrics-card__hero">
          <div class="metrics-card__tile metrics-card__tile--primary">
            <div class="metrics-card__tile__label">
              {{ t("labels.logistics.inStock") }}
            </div>
            <div class="metrics-card__tile__value">
              {{ toNumber(stockItem.netQuantity, "integer") }}
              <span class="metrics-card__tile__unit">
                {{ t(`labels.logistics.units.${stockItem.unit}`) }}
              </span>
            </div>
            <div class="metrics-card__tile__sub">
              {{ t(`labels.logistics.categories.${stockItem.category}`) }}
            </div>
          </div>

          <div class="metrics-card__tile">
            <div class="metrics-card__tile__label">
              {{ t("labels.logistics.entries") }}
            </div>
            <div class="metrics-card__tile__value">
              {{ stockItem.entriesCount }}
            </div>
            <div v-if="stockItem.lastEntryAt" class="metrics-card__tile__sub">
              {{ l(stockItem.lastEntryAt, "datetime.formats.short") }}
            </div>
          </div>

          <div v-if="quality" class="metrics-card__tile">
            <div class="metrics-card__tile__label">
              {{ t("labels.logistics.qualityRange") }}
            </div>
            <div class="metrics-card__tile__value">
              {{ quality }}
            </div>
          </div>
        </div>

        <div class="metrics-card__rows">
          <div v-if="stockItem.item" class="metrics-card__row">
            <div class="metrics-card__row__label">
              {{ t("labels.logistics.linkedItem") }}
            </div>
            <div class="metrics-card__row__value">
              {{ stockItem.item.name }}
              <BasePill
                v-if="stockItem.item.available === false"
                variant="warning"
                :title="t('labels.logistics.itemUnavailableHint')"
              >
                {{ t("labels.logistics.itemUnavailable") }}
              </BasePill>
            </div>
          </div>
          <div v-if="stockItem.lastEntryAt" class="metrics-card__row">
            <div class="metrics-card__row__label">
              {{ t("labels.logistics.lastEntry") }}
            </div>
            <div class="metrics-card__row__value">
              {{ l(stockItem.lastEntryAt) }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.stock-item {
  display: flex;
  gap: 20px;
  align-items: flex-start;
  flex-wrap: wrap;

  &__image {
    flex: 0 0 180px;
    max-width: 100%;
    background: $gray-black;
    border: 1px solid rgba($gray-light, 0.28);
    border-radius: 8px;
    overflow: hidden;

    img {
      display: block;
      width: 100%;
      height: auto;
    }
  }

  // Wide enough that the hero tiles keep their own scale next to the image, and
  // narrow enough to wrap under it on a phone.
  &__metrics {
    flex: 1 1 320px;
    min-width: 0;
  }
}
</style>
