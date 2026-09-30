<script lang="ts">
export default {
  name: "StatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";
import { type StatsCardBadge } from "./types";

type Props = {
  title: string;
  subtitle?: string;
  badges?: StatsCardBadge[];
  stats?: HardpointStat[];
  to?: RouteLocationRaw;
  loading?: boolean;
  // A card that floats over a list has to stay a glance; the detail page is
  // one link away for everything past this.
  maxStats?: number;
};

const props = withDefaults(defineProps<Props>(), {
  subtitle: undefined,
  badges: () => [],
  stats: () => [],
  to: undefined,
  loading: false,
  maxStats: 10,
});

const emit = defineEmits<{ navigate: [] }>();

const { t } = useI18n();

// Only the first key figure is a tile, as on the detail page: a gun marks both
// sustained and burst DPS, and two accented tiles say neither is the headline.
const headline = computed(() => props.stats.find((stat) => stat.primary));

const rest = computed(() =>
  props.stats.filter((stat) => stat !== headline.value),
);

const shown = computed(() => rest.value.slice(0, props.maxStats));

const hidden = computed(() => rest.value.length - shown.value.length);
</script>

<template>
  <div class="stats-card" data-test="stats-card">
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
      <div v-if="headline" class="metrics-card__hero">
        <div class="metrics-card__tile metrics-card__tile--primary">
          <div class="metrics-card__tile__label">{{ headline.label }}</div>
          <div class="metrics-card__tile__value">{{ headline.value }}</div>
        </div>
      </div>

      <div v-if="shown.length" class="metrics-card__rows">
        <div
          v-for="stat in shown"
          :key="stat.label"
          class="metrics-card__row"
          :class="{ 'metrics-card__row--stack': stat.wide }"
        >
          <span class="metrics-card__row__label">{{ stat.label }}</span>
          <span class="metrics-card__row__value">{{ stat.value }}</span>
        </div>
      </div>

      <p v-if="hidden > 0" class="stats-card__more">
        {{ t("labels.statsCard.more", { count: hidden }) }}
      </p>

      <p v-if="!stats.length" class="stats-card__empty">
        {{ t("labels.component.noMetrics") }}
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
</template>

<style lang="scss" scoped>
@import "index";
</style>
