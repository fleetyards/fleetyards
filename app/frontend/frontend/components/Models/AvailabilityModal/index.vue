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

const { t, toNumber } = useI18n();

const byPrice = (prices: ItemPrice[]) =>
  [...prices].sort((a, b) => a.price - b.price);

const buyPrices = computed(() => byPrice(props.soldAt));
const rentalPrices = computed(() => byPrice(props.rentalAt));

const sections = computed(() =>
  [
    {
      key: "buy",
      label: t("labels.availability.buy"),
      prices: buyPrices.value,
    },
    {
      key: "rent",
      label: t("labels.availability.rent"),
      prices: rentalPrices.value,
    },
  ]
    .filter((section) => section.prices.length)
    .map((section) => ({
      ...section,
      // Today every rental is quoted for the same period, and repeating "1 day"
      // down thirty rows says nothing the tile has not — it earns its column
      // only once the periods actually differ.
      mixedPeriods:
        new Set(section.prices.map((price) => price.timeRange)).size > 1,
    })),
);

const hasData = computed(() => !!sections.value.length);

const uec = computed(() => t("number.units.uec"));

// Rentals are quoted per period, so the same location appears once per range.
const timeRangeLabel = (price: ItemPrice) =>
  price.timeRange ? t(`labels.availability.timeRange.${price.timeRange}`) : "";

// UEX names a terminal "shop - spaceport - city": the shop is what people look
// for and the rest is where to fly, so they get separate weights instead of one
// long run of text that ellipsises mid-place.
const shopName = (price: ItemPrice) => price.location.split(" - ")[0];

const placeName = (price: ItemPrice) =>
  price.location.split(" - ").slice(1).join(" · ");

// Vehicle prices barely move between shops — a few percent — so bars scaled to
// the dearest would all read full. The premium over the cheapest is the part
// worth showing.
const premium = (price: ItemPrice, cheapest: ItemPrice) =>
  cheapest.price ? Math.round((price.price / cheapest.price - 1) * 100) : 0;
</script>

<template>
  <Modal :title="t('labels.availability.title')">
    <div class="availability">
      <p v-if="!hasData" class="availability__empty">
        {{ t("labels.availability.empty") }}
      </p>

      <template v-else>
        <div class="availability__tiles">
          <div
            v-for="(section, index) in sections"
            :key="section.key"
            class="availability__tile"
            :class="{ 'availability__tile--primary': index === 0 }"
          >
            <div class="availability__tile__label">
              {{ t(`labels.availability.cheapest.${section.key}`) }}
            </div>
            <div class="availability__tile__value">
              {{ toNumber(section.prices[0].price, "integer") }}
              <span class="availability__tile__unit">{{ uec }}</span>
            </div>
            <div class="availability__tile__sub">
              <template v-if="timeRangeLabel(section.prices[0])">
                {{ timeRangeLabel(section.prices[0]) }} ·
              </template>
              {{
                t("labels.availability.locations", {
                  count: section.prices.length,
                })
              }}
            </div>
          </div>
        </div>

        <div class="availability__scroll">
          <template v-for="section in sections" :key="section.key">
            <div class="availability__head">
              <span>{{ section.label }}</span>
              <span class="availability__head__unit">{{ uec }}</span>
            </div>
            <ul class="availability__list">
              <li
                v-for="price in section.prices"
                :key="price.id"
                class="availability__item"
              >
                <span class="availability__loc">
                  <a
                    v-if="price.locationUrl"
                    :href="price.locationUrl"
                    class="availability__shop"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {{ shopName(price) }}
                  </a>
                  <span v-else class="availability__shop">
                    {{ shopName(price) }}
                  </span>
                  <span v-if="placeName(price)" class="availability__place">
                    {{ placeName(price) }}
                  </span>
                </span>
                <span
                  v-if="section.mixedPeriods && price.timeRange"
                  class="availability__range"
                >
                  {{ timeRangeLabel(price) }}
                </span>
                <span
                  v-if="premium(price, section.prices[0]) > 0"
                  class="availability__premium"
                >
                  +{{ premium(price, section.prices[0]) }}%
                </span>
                <span
                  class="availability__price"
                  :class="{
                    'availability__price--best':
                      price.id === section.prices[0].id,
                  }"
                >
                  {{ toNumber(price.price, "integer") }}
                </span>
              </li>
            </ul>
          </template>
        </div>

        <div class="availability__footer">
          <a href="https://uexcorp.space" target="_blank" rel="noopener">
            {{ t("model.poweredByUex") }}
          </a>
        </div>
      </template>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
// The modal body scrolls on its own, so an inner scroller with its own
// max-height would nest two scrollbars. Capping the whole card at that height
// instead keeps the tiles and the UEX credit put while only the lists move.
.availability {
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 16rem);
}

.availability__empty {
  margin: 0;
  color: $gray-light;
}

.availability__tiles {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 18px;
}

.availability__tile {
  flex: 1 1 150px;
  display: flex;
  flex-direction: column;
  gap: 5px;
  padding: 11px 14px;
  min-width: 0;
  overflow: hidden;
  container-type: inline-size;
  background: $gray-black;
  border: 1px solid rgba($gray-light, 0.28);
  border-radius: 6px;

  &--primary {
    border-color: rgba($gold, 0.5);

    .availability__tile__value {
      color: $gold;
    }
  }

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 9px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: $gray;
  }

  &__value {
    display: flex;
    align-items: baseline;
    gap: 5px;
    font-family: "Orbitron", tahoma, sans-serif;
    font-weight: 700;
    // Capitals run to eight figures, so the value scales with the tile rather
    // than outgrowing it.
    font-size: clamp(14px, 13cqw, 22px);
    line-height: 1;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
  }

  &__unit {
    font-family: "Open Sans", sans-serif;
    font-weight: 600;
    font-size: 11px;
    letter-spacing: 0.08em;
    color: $gray-light;
  }

  &__sub {
    font-size: 11px;
    color: $gray;
  }
}

.availability__scroll {
  flex: 1 1 auto;
  min-height: 0;
  overflow-x: hidden;
  overflow-y: auto;
}

.availability__head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 10px;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 9px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: $gray;
  padding-bottom: 6px;
  border-bottom: 1px solid rgba($gray-light, 0.28);

  &:not(:first-child) {
    margin-top: 22px;
  }

  &__unit {
    font-family: "Open Sans", sans-serif;
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: none;
    color: $gray;
  }
}

.availability__list {
  list-style: none;
  margin: 0;
  padding: 0;
}

.availability__item {
  display: flex;
  align-items: baseline;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px solid rgba($gray-light, 0.18);

  &:last-child {
    border-bottom: 0;
  }
}

.availability__loc {
  flex: 1 1 auto;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.availability__shop,
.availability__place {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.availability__shop {
  font-size: 13px;
  color: lighten($text-color, 15%);
}

.availability__place {
  font-size: 11px;
  color: $gray;
}

.availability__range,
.availability__premium {
  flex: none;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 8.5px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: $gray;
  white-space: nowrap;
}

.availability__price {
  flex: none;
  font-size: 13px;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  color: lighten($text-color, 15%);
  white-space: nowrap;

  &--best {
    color: $gold;
  }
}

.availability__footer {
  margin-top: 14px;
  font-size: 11px;
  color: $gray;
}
</style>
