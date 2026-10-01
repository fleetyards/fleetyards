<script lang="ts">
export default {
  name: "StatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import LoadingLine from "@/shared/components/LoadingLine/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { catalogueTokenIcon } from "@/shared/utils/CatalogueTokens";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";
import {
  type StatsCardBadge,
  type StatsCardKind,
  type StatsCardStatus,
} from "./types";

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
  // A lookup that settled without a record -- a failed request, or a
  // reference to something the API no longer has. Said out loud so the card
  // does not look as if it were still loading.
  unavailable?: boolean;
  // What the compact card's icon, eyebrow and link are worded for.
  kind?: StatsCardKind;
  // Named after the type in the eyebrow: a component's category, a ship's
  // classification.
  category?: string;
  subtitle?: string;
  status?: StatsCardStatus;
  image?: string;
  description?: string;
  badges?: StatsCardBadge[];
  // Badges that are the figures worth reading, such as a commodity's prices,
  // set as equal tiles rather than a strip of specs.
  prominentBadges?: boolean;
  to?: RouteLocationRaw;
  maxStats?: number;
};

const props = withDefaults(defineProps<Props>(), {
  stats: () => [],
  compact: false,
  variant: "default",
  emptyText: undefined,
  loading: false,
  unavailable: false,
  kind: undefined,
  category: undefined,
  subtitle: undefined,
  status: undefined,
  image: undefined,
  description: undefined,
  badges: () => [],
  prominentBadges: false,
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

const typeLabel = computed(() =>
  props.kind ? t(`labels.statsCard.types.${props.kind}`) : undefined,
);

const eyebrow = computed(
  () => [typeLabel.value, props.category].filter(Boolean).join(" · ") || "",
);

const linkLabel = computed(() =>
  props.kind
    ? t(`labels.statsCard.open.${props.kind}`)
    : t("actions.showDetails"),
);

// Short specs (a size, a grade) take only their own width and the last one
// takes what is left, so a long class name gets the room instead of a third.
const badgeColumns = computed(() => {
  const count = props.badges.length;

  if (props.prominentBadges || count < 2) {
    return `repeat(${count}, minmax(0, 1fr))`;
  }

  // `minmax(0, …)` so a cell that runs long still shrinks to the card rather
  // than pushing the strip past its edge.
  return `repeat(${count - 1}, minmax(0, max-content)) minmax(0, 1fr)`;
});

// Without a name the generic text, rather than "Loading" and a blank.
const loadingLabel = computed(() =>
  props.title
    ? t("labels.statsCard.loading", { name: props.title })
    : undefined,
);

// Only a ship's card carries an image, and a fetched one would otherwise grow
// by its height the moment the record lands.
const showsImage = computed(() => !!props.image && !props.loading);

const holdsImage = computed(() => props.loading && props.kind === "Model");

const hasBody = computed(
  () =>
    !!props.description ||
    heroStats.value.length > 0 ||
    hasRows.value ||
    hidden.value > 0 ||
    (!props.stats.length && !!props.emptyText) ||
    !!slots.default,
);
</script>

<template>
  <div v-if="compact" class="stats-card" data-test="stats-card">
    <LoadingLine :loading="loading" :label="loadingLabel" />

    <span
      v-if="holdsImage"
      class="skeleton-well stats-card__image-well"
      aria-hidden="true"
    />

    <div v-if="showsImage" class="stats-card__media">
      <img :src="image" :alt="title" class="stats-card__image" loading="lazy" />
      <span
        v-if="status"
        class="stats-card__status stats-card__status--over-image"
        :class="`stats-card__status--${status.tone}`"
        data-test="stats-card-status"
      >
        {{ status.label }}
      </span>
    </div>

    <div class="stats-card__head">
      <span v-if="kind" class="stats-card__icon">
        <i :class="catalogueTokenIcon(kind)" aria-hidden="true" />
      </span>
      <div class="stats-card__heading">
        <div v-if="eyebrow || status" class="stats-card__eyebrow-row">
          <span v-if="eyebrow" class="stats-card__eyebrow">{{ eyebrow }}</span>
          <span
            v-if="status && !loading && !showsImage"
            class="stats-card__status"
            :class="`stats-card__status--${status.tone}`"
            data-test="stats-card-status"
          >
            {{ status.label }}
          </span>
        </div>
        <div class="stats-card__title">{{ title }}</div>
        <div v-if="subtitle && !loading" class="stats-card__subtitle">
          {{ subtitle }}
        </div>
      </div>
    </div>

    <!-- Still on purpose, as every skeleton here is: the line above carries
         the motion, so the shape only has to hold the card's size. -->
    <div
      v-if="loading"
      class="stats-card__skeleton"
      aria-hidden="true"
      data-test="stats-card-skeleton"
    >
      <div
        class="stats-card__specs"
        :style="{
          gridTemplateColumns: 'max-content max-content minmax(0, 1fr)',
        }"
      >
        <div
          v-for="width in [28, 36, 72]"
          :key="width"
          class="stats-card__spec"
        >
          <span class="skeleton-bar stats-card__skeleton-label" />
          <span
            class="skeleton-bar stats-card__skeleton-value"
            :style="{ width: `${width}px` }"
          />
        </div>
      </div>
      <div class="stats-card__body">
        <span class="skeleton-bar stats-card__skeleton-hero" />
        <span class="skeleton-bar stats-card__skeleton-line" />
        <span
          class="skeleton-bar stats-card__skeleton-line"
          :style="{ width: '70%' }"
        />
      </div>
    </div>

    <p
      v-else-if="unavailable"
      class="stats-card__unavailable"
      data-test="stats-card-unavailable"
    >
      <i class="fa-light fa-circle-exclamation" aria-hidden="true" />
      {{ t("labels.statsCard.unavailable") }}
    </p>

    <template v-else>
      <div
        v-if="badges.length"
        class="stats-card__specs"
        :class="{ 'stats-card__specs--prominent': prominentBadges }"
        :style="{ gridTemplateColumns: badgeColumns }"
      >
        <div
          v-for="badge in badges"
          :key="badge.key"
          class="stats-card__spec"
          data-test="stats-card-spec"
        >
          <span class="stats-card__label">{{ badge.label }}</span>
          <span class="stats-card__spec-value" :title="badge.value">
            {{ badge.value }}
            <span v-if="badge.unit" class="stats-card__unit">
              {{ badge.unit }}
            </span>
          </span>
        </div>
      </div>

      <div v-if="hasBody" class="stats-card__body">
        <p v-if="description" class="stats-card__description">
          {{ description }}
        </p>

        <div
          v-for="stat in heroStats"
          :key="stat.label"
          class="stats-card__hero"
          data-test="stats-card-hero"
        >
          <span class="stats-card__label">{{ stat.label }}</span>
          <span class="stats-card__hero-value">{{ stat.value }}</span>
        </div>

        <div v-if="hasRows" class="stats-card__rows">
          <div
            v-for="stat in rowStats"
            :key="stat.label"
            class="stats-card__row"
            :class="{ 'stats-card__row--wide': stat.wide }"
            data-test="stats-card-row"
          >
            <span class="stats-card__label">{{ stat.label }}</span>
            <span class="stats-card__row-value" :title="stat.value">
              {{ stat.value }}
            </span>
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
      </div>
    </template>

    <router-link
      v-if="to"
      :to="to"
      class="stats-card__link"
      data-test="stats-card-link"
      @click="emit('navigate')"
    >
      {{ linkLabel }}
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
