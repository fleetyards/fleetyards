<script lang="ts">
export default {
  name: "ModelAvailabilityModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import type { ItemPrice } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  soldAt?: ItemPrice[];
  rentalAt?: ItemPrice[];
};

const props = withDefaults(defineProps<Props>(), {
  soldAt: () => [],
  rentalAt: () => [],
});

const { t, toUEC } = useI18n();

const byPrice = (prices: ItemPrice[]) =>
  [...prices].sort((a, b) => a.price - b.price);

const buyPrices = computed(() => byPrice(props.soldAt));
const rentalPrices = computed(() => byPrice(props.rentalAt));

const hasData = computed(
  () => !!buyPrices.value.length || !!rentalPrices.value.length,
);

// Rentals are quoted per period, so the same location appears once per range.
const timeRangeLabel = (price: ItemPrice) =>
  price.timeRange ? t(`labels.availability.timeRange.${price.timeRange}`) : "";
</script>

<template>
  <Modal :title="t('labels.availability.title')">
    <div class="availability">
      <p v-if="!hasData" class="availability__empty">
        {{ t("labels.availability.empty") }}
      </p>

      <template v-if="buyPrices.length">
        <div class="availability__label">
          {{ t("labels.availability.buy") }}
        </div>
        <ul class="availability__list">
          <li
            v-for="price in buyPrices"
            :key="price.id"
            class="availability__item"
          >
            <a
              v-if="price.locationUrl"
              :href="price.locationUrl"
              class="availability__location"
              target="_blank"
              rel="noopener noreferrer"
            >
              {{ price.location }}
            </a>
            <span v-else class="availability__location">
              {{ price.location }}
            </span>
            <!-- eslint-disable vue/no-v-html -->
            <span class="availability__price" v-html="toUEC(price.price)" />
            <!-- eslint-enable vue/no-v-html -->
          </li>
        </ul>
      </template>

      <template v-if="rentalPrices.length">
        <div class="availability__label">
          {{ t("labels.availability.rent") }}
        </div>
        <ul class="availability__list">
          <li
            v-for="price in rentalPrices"
            :key="price.id"
            class="availability__item"
          >
            <a
              v-if="price.locationUrl"
              :href="price.locationUrl"
              class="availability__location"
              target="_blank"
              rel="noopener noreferrer"
            >
              {{ price.location }}
            </a>
            <span v-else class="availability__location">
              {{ price.location }}
            </span>
            <span v-if="price.timeRange" class="availability__range">
              {{ timeRangeLabel(price) }}
            </span>
            <!-- eslint-disable vue/no-v-html -->
            <span class="availability__price" v-html="toUEC(price.price)" />
            <!-- eslint-enable vue/no-v-html -->
          </li>
        </ul>
      </template>

      <div v-if="hasData" class="metrics-attribution">
        <a href="https://uexcorp.space" target="_blank" rel="noopener">
          {{ t("model.poweredByUex") }}
        </a>
      </div>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
.availability {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.availability__empty {
  margin: 0;
  color: $gray-light;
}

.availability__label {
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 10px;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: $gray-light;
  margin: 14px 0 6px;

  &:first-child {
    margin-top: 0;
  }
}

.availability__list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
}

.availability__item {
  display: flex;
  align-items: baseline;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px solid rgba($gray-light, 0.16);

  &:last-child {
    border-bottom: 0;
  }
}

.availability__location {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.availability__range {
  flex: none;
  font-size: 11px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: $gray-light;
}

.availability__price {
  flex: none;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  color: lighten($text-color, 15%);
}
</style>
