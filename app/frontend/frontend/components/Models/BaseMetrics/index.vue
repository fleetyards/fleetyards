<script lang="ts">
export default {
  name: "ModelBaseMetrics",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { Model } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

const { t, toNumber, toDollar, toUEC } = useI18n();

const comlink = useComlink();

type Props = {
  model: Model;
  extended?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  extended: false,
});

const soldAt = computed(() => props.model.availability.soldAt);
const rentalAt = computed(() => props.model.availability.rentalAt);

const displayLength = computed(() => {
  if (props.extended && props.model.metrics.extendedLength) {
    return props.model.metrics.extendedLength;
  }

  return props.model.metrics.length;
});

const displayBeam = computed(() => {
  if (props.extended && props.model.metrics.extendedBeam) {
    return props.model.metrics.extendedBeam;
  }

  return props.model.metrics.beam;
});

const displayHeight = computed(() => {
  if (props.extended && props.model.metrics.extendedHeight) {
    return props.model.metrics.extendedHeight;
  }

  return props.model.metrics.height;
});

const hasPrice = computed(
  () => !!props.model.price || !!props.model.pledgePrice,
);

const openAvailability = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Models/AvailabilityModal/index.vue"),
    props: {
      soldAt: soldAt.value,
      rentalAt: rentalAt.value,
    },
  });
};
</script>

<template>
  <MetricsCard :title="t('labels.metrics.base')" class="base-panel">
    <template #head>
      <span v-if="model.classificationLabel" class="base-panel__chip">
        {{ model.classificationLabel }}
      </span>
    </template>

    <div class="metrics-card__hero metrics-card__hero--grid">
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">{{ t("model.length") }}</div>
        <div class="metrics-card__tile__value">
          {{ toNumber(displayLength || "", "distance") }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">{{ t("model.beam") }}</div>
        <div class="metrics-card__tile__value">
          {{ toNumber(displayBeam || "", "distance") }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">{{ t("model.height") }}</div>
        <div class="metrics-card__tile__value">
          {{ toNumber(displayHeight || "", "distance") }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">{{ t("model.mass") }}</div>
        <div class="metrics-card__tile__value">
          {{ toNumber(model.metrics.mass || "", "weight") }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">{{ t("model.cargo") }}</div>
        <div class="metrics-card__tile__value">
          {{ toNumber(model.metrics.cargo || "", "integer") }}
          <span class="metrics-card__tile__unit">SCU</span>
        </div>
      </div>
      <div v-if="model.metrics.personalInventory" class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("model.personalInventory") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ toNumber(model.metrics.personalInventory) }}
          <span class="metrics-card__tile__unit">SCU</span>
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">{{ t("model.size") }}</div>
        <div class="metrics-card__tile__value">
          {{ model.metrics.sizeLabel }}
        </div>
      </div>
    </div>

    <template v-if="hasPrice">
      <div class="metrics-card__section-label">
        {{ t("labels.base.price") }}
      </div>
      <div class="metrics-card__rows metrics-card__rows--split">
        <div v-if="model.price" class="metrics-card__row">
          <span class="metrics-card__row__label">
            {{ t("labels.base.priceInGame") }}
          </span>
          <!-- eslint-disable vue/no-v-html -->
          <span
            v-tooltip="{ content: toUEC(model.price), html: true }"
            class="metrics-card__row__value"
            v-html="toUEC(model.price)"
          />
          <!-- eslint-enable vue/no-v-html -->
        </div>
        <div v-if="model.pledgePrice" class="metrics-card__row">
          <span class="metrics-card__row__label">
            {{ t("labels.base.pricePledge") }}
          </span>
          <span class="metrics-card__row__value">
            {{ toDollar(model.pledgePrice) }}
          </span>
        </div>
      </div>
    </template>

    <div class="metrics-card__actions">
      <button
        type="button"
        class="metrics-card__toggle"
        @click="openAvailability"
      >
        {{ t("labels.base.availability") }}
      </button>
    </div>

    <div v-if="model.lastUpdatedAt" class="metrics-card__footer">
      <span class="base-panel__updated">
        <span class="base-panel__updated-label">
          {{ t("model.lastUpdatedAt") }}
        </span>
        {{ model.lastUpdatedAtLabel }}
      </span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.base-panel {
  &__chip {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: $gray-light;
    border: 1px solid rgba($gray-light, 0.4);
    border-radius: 999px;
    padding: 4px 11px;
    white-space: nowrap;
  }

  // Not `__hint`: that is sized for the explanatory sentences the other cards
  // end on, and this is a value people actually read off the card.
  &__updated {
    font-size: 13px;
    color: $text-color;
    font-variant-numeric: tabular-nums;

    &-label {
      color: $gray-light;
    }
  }
}
</style>
