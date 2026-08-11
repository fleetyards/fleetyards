<script lang="ts">
export default {
  name: "ModelBaseMetrics",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import type { Model } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t, toNumber, toDollar, toUEC } = useI18n();

type Props = {
  model: Model;
  extended?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  extended: false,
});

const soldAt = computed(() => props.model.availability.soldAt);
const rentalAt = computed(() => props.model.availability.rentalAt);

const hasAvailability = computed(
  () => !!soldAt.value?.length || !!rentalAt.value?.length,
);

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

const hasFuel = computed(
  () =>
    !!props.model.metrics.hydrogenFuelTankSize ||
    !!props.model.metrics.quantumFuelTankSize,
);

const hasAvailability = computed(
  () => !!soldAt.value?.length || !!rentalAt.value?.length,
);

const availabilityVisible = ref(false);
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

    <template v-if="hasFuel">
      <div v-if="hasPrice" class="metrics-card__divider" />
      <div class="metrics-card__section-label">
        {{ t("labels.base.fuel") }}
      </div>
      <div class="metrics-card__rows metrics-card__rows--split">
        <div
          v-if="model.metrics.hydrogenFuelTankSize"
          class="metrics-card__row"
        >
          <span class="metrics-card__row__label">
            {{ t("labels.base.fuelHydrogen") }}
          </span>
          <span class="metrics-card__row__value">
            {{ toNumber(model.metrics.hydrogenFuelTankSize, "cargo") }}
          </span>
        </div>
        <div v-if="model.metrics.quantumFuelTankSize" class="metrics-card__row">
          <span class="metrics-card__row__label">
            {{ t("labels.base.fuelQuantum") }}
          </span>
          <span class="metrics-card__row__value">
            {{ toNumber(model.metrics.quantumFuelTankSize, "cargo") }}
          </span>
        </div>
      </div>
    </template>

    <div v-if="hasAvailability" class="metrics-card__actions">
      <button
        type="button"
        class="metrics-card__toggle"
        @click="availabilityVisible = !availabilityVisible"
      >
        {{ t("labels.base.availability") }}
      </button>
      <Collapsed :visible="availabilityVisible">
        <div class="metrics-card__breakdown">
          <div class="metrics-card__rows metrics-card__rows--split">
            <div
              v-if="soldAt && soldAt.length"
              class="metrics-card__row metrics-card__row--stack"
            >
              <span class="metrics-card__row__label">
                {{ t("model.soldAt") }}
              </span>
              <span class="metrics-card__row__value">
                <ul class="base-panel__locations">
                  <li v-for="modelPrice in soldAt" :key="modelPrice.id">
                    {{ modelPrice.location }}
                  </li>
                </ul>
              </span>
            </div>
            <div
              v-if="rentalAt && rentalAt.length"
              class="metrics-card__row metrics-card__row--stack"
            >
              <span class="metrics-card__row__label">
                {{ t("model.rentalAt") }}
              </span>
              <span class="metrics-card__row__value">
                <ul class="base-panel__locations">
                  <li v-for="modelPrice in rentalAt" :key="modelPrice.id">
                    {{ modelPrice.location }}
                  </li>
                </ul>
              </span>
            </div>
            <div v-if="hasAvailability" class="col-12">
              <div class="metrics-attribution">
                <a href="https://uexcorp.space" target="_blank" rel="noopener">
                  {{ t("model.poweredByUex") }}
                </a>
              </div>
            </div>
          </div>
        </div>
      </Collapsed>
    </div>

    <div v-if="model.lastUpdatedAt" class="metrics-card__footer">
      <span class="metrics-card__hint">
        {{ t("model.lastUpdatedAt") }} {{ model.lastUpdatedAtLabel }}
      </span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/metricsCard";

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

  &__locations {
    list-style: none;
    margin: 0;
    padding: 0;
    font-size: 13px;
    font-weight: 400;
    color: $text-color;

    li {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
  }
}
</style>
