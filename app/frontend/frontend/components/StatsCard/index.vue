<script lang="ts">
export default {
  name: "StatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";
import { type StatsCardBadge } from "./types";

type Props = {
  title: string;
  stats?: HardpointStat[];
  // The detail page shows every figure in a metrics card; a compact card
  // floats over a list, names its record, stays a glance, and links to the page
  // for the rest.
  compact?: boolean;
  variant?: "default" | "slim";
  emptyText?: string;
  loading?: boolean;
  subtitle?: string;
  badges?: StatsCardBadge[];
  to?: RouteLocationRaw;
  maxStats?: number;
};

const props = withDefaults(defineProps<Props>(), {
  stats: () => [],
  compact: false,
  variant: "default",
  emptyText: undefined,
  loading: false,
  subtitle: undefined,
  badges: () => [],
  to: undefined,
  maxStats: 10,
});

const emit = defineEmits<{ navigate: [] }>();

const slots = useSlots();

const { t } = useI18n();

// The renderer marks the figures worth leading with, and those become tiles.
// Exactly one carries the accent: a gun marks both sustained and burst DPS, and
// two accented tiles say neither is the one to read first. The compact card
// keeps only that one.
const heroStats = computed(() => {
  const primary = props.stats.filter((stat) => stat.primary);

  return props.compact ? primary.slice(0, 1) : primary;
});

const restStats = computed(() =>
  props.stats.filter((stat) => !heroStats.value.includes(stat)),
);

const rowStats = computed(() =>
  props.compact ? restStats.value.slice(0, props.maxStats) : restStats.value,
);

const hidden = computed(() => restStats.value.length - rowStats.value.length);

const hasRows = computed(() => rowStats.value.length > 0 || !!slots.rows);
</script>

<template>
  <div v-if="compact" class="stats-card" data-test="stats-card">
    <div class="stats-card__head">
      <div class="stats-card__title">{{ title }}</div>
      <div v-if="subtitle" class="stats-card__subtitle">{{ subtitle }}</div>
      <div v-if="badges.length" class="stats-card__badges">
        <span
          v-for="badge in badges"
          :key="badge.key"
          class="stats-card__badge"
        >
          <span class="stats-card__badge-label">{{ badge.label }}</span>
          {{ badge.value }}
        </span>
      </div>
    </div>

    <div v-if="loading" class="stats-card__loading">
      <SmallLoader :loading="true" />
    </div>

    <template v-else>
      <div v-if="heroStats.length" class="metrics-card__hero">
        <div
          v-for="stat in heroStats"
          :key="stat.label"
          class="metrics-card__tile metrics-card__tile--primary"
        >
          <div class="metrics-card__tile__label">{{ stat.label }}</div>
          <div class="metrics-card__tile__value">{{ stat.value }}</div>
        </div>
      </div>

      <div v-if="hasRows" class="metrics-card__rows">
        <div
          v-for="stat in rowStats"
          :key="stat.label"
          class="metrics-card__row"
          :class="{ 'metrics-card__row--stack': stat.wide }"
        >
          <span class="metrics-card__row__label">{{ stat.label }}</span>
          <span class="metrics-card__row__value">{{ stat.value }}</span>
        </div>
        <slot name="rows" />
      </div>

      <p v-if="hidden > 0" class="stats-card__note">
        {{ t("labels.statsCard.more", { count: hidden }) }}
      </p>

      <p v-if="!stats.length && emptyText" class="stats-card__note">
        {{ emptyText }}
      </p>

      <slot />
    </template>

    <router-link
      v-if="to"
      :to="to"
      class="stats-card__link"
      data-test="stats-card-link"
      @click="emit('navigate')"
    >
      {{ t("actions.showDetails") }}
      <i class="fa-light fa-arrow-right" aria-hidden="true" />
    </router-link>
  </div>

  <MetricsCard
    v-else
    :title="title"
    :variant="variant"
    :loading="loading"
    data-test="stats-card"
  >
    <div v-if="heroStats.length" class="metrics-card__hero">
      <div
        v-for="(stat, index) in heroStats"
        :key="stat.label"
        class="metrics-card__tile"
        :class="{ 'metrics-card__tile--primary': index === 0 }"
      >
        <div class="metrics-card__tile__label">{{ stat.label }}</div>
        <div class="metrics-card__tile__value">{{ stat.value }}</div>
      </div>
    </div>

    <div
      v-if="hasRows"
      class="metrics-card__rows"
      :class="{ 'metrics-card__rows--split': variant === 'default' }"
    >
      <div
        v-for="stat in rowStats"
        :key="stat.label"
        class="metrics-card__row"
        :class="{ 'metrics-card__row--stack': stat.wide }"
      >
        <span class="metrics-card__row__label">{{ stat.label }}</span>
        <span class="metrics-card__row__value">{{ stat.value }}</span>
      </div>
      <slot name="rows" />
    </div>

    <!-- Said out loud: an empty card reads as something having failed to
         load. -->
    <p v-if="!stats.length && emptyText" class="stats-card__note">
      {{ emptyText }}
    </p>

    <slot />
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "index";
</style>
