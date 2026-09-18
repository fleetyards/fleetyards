<script lang="ts">
export default {
  name: "ComponentPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useComponentStats } from "@/frontend/composables/useComponentStats";
import { categoryIcon } from "@/frontend/components/Models/Hardpoints/categoryIcon";
import { useComponent as useComponentQuery } from "@/services/fyApi";

const { t, tExists } = useI18n();
const { updateMetaInfo } = useMetaInfo();
const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: component, ...asyncStatus } = useComponentQuery(slug);

const stats = useComponentStats(component);

// The renderer already marks the figures worth leading with. Those become hero
// tiles and the rest fall into the split list below, which is the metrics
// card's own division rather than a new one -- see metricsCard.scss.
const heroStats = computed(() => stats.value.filter((stat) => stat.primary));
const restStats = computed(() => stats.value.filter((stat) => !stat.primary));

// One crumb, not two. `/catalogue/` only redirects here, so a "Catalogue" step
// above would be a link back to the page the reader is already on the way to.
//
// `BreadCrumbs` resolves it through `useBreadCrumbs`, so the way back carries
// the filters and the page the reader left the list on rather than dropping
// them at an unfiltered page one.
const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "components" },
    label: t("nav.components.index"),
  },
]);

const icon = computed(() => categoryIcon(component.value?.category));

// The payload carries the game's own category string ("quantumdrive"). The
// hardpoint list already names all of them, in every locale, so the label comes
// from there rather than a second vocabulary -- falling back to the raw key
// spaced and capitalised, the way the server's filter labels do, for a category
// a patch introduces before anyone writes a label for it.
const labelFor = (key: string, scope: string) => {
  const path = `labels.hardpoint.${scope}.${key}`;
  if (tExists(path)) return t(path);

  return key
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
};

const details = computed(() => {
  const value = component.value;
  if (!value) return [];

  return [
    {
      label: t("labels.component.category"),
      value: value.category
        ? labelFor(value.category, "categories")
        : undefined,
    },
    { label: t("labels.component.subType"), value: value.subType },
    {
      label: t("headlines.component.requiredTags"),
      value: value.requiredTags?.join(" · "),
      stack: true,
    },
  ].filter((entry) => entry.value);
});

watch(
  component,
  (value) => {
    if (!value) return;

    updateMetaInfo({
      title: t("title.component", { name: value.name }),
      description: value.description ?? undefined,
    });
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="component" class="component-page">
        <BreadCrumbs :crumbs="crumbs" />

        <div class="component-page__masthead">
          <img
            v-if="icon?.kind === 'svg'"
            :src="icon.src"
            class="component-page__icon"
            alt=""
          />
          <span
            v-else-if="icon?.kind === 'fa'"
            class="component-page__icon component-page__icon--glyph"
          >
            <i :class="icon.className" />
          </span>

          <div class="component-page__title">
            <h1 class="component-page__name">{{ component.name }}</h1>
            <div v-if="component.manufacturer" class="component-page__sub">
              {{ component.manufacturer.name }}
            </div>
          </div>

          <div class="component-page__badges">
            <!-- Labelled rather than three identical pills: "3" and "B" say
                 nothing on their own, and the label/value pairing is the
                 metrics card's own. Class carries the accent instead of a
                 label, being the one that reads on its own. -->
            <span v-if="component.size" class="component-page__badge">
              <span class="component-page__badge-label">
                {{ t("labels.hardpoint.size") }}
              </span>
              <span class="component-page__badge-value">{{
                component.size
              }}</span>
            </span>
            <span v-if="component.gradeLabel" class="component-page__badge">
              <span class="component-page__badge-label">
                {{ t("labels.component.grade") }}
              </span>
              <span class="component-page__badge-value">
                {{ component.gradeLabel }}
              </span>
            </span>
            <span
              v-if="component.itemClassLabel"
              class="component-page__badge component-page__badge--accent"
            >
              <span class="component-page__badge-value">
                {{ component.itemClassLabel }}
              </span>
            </span>
            <!-- A component the current build no longer describes. It stays
                 reachable because a ship's older loadout points at it, so it
                 says so rather than serving stale figures as current. -->
            <Chip v-if="component.retired" :state="ChipStatesEnum.EXCLUDED">
              {{ t("labels.component.retired") }}
            </Chip>
          </div>
        </div>

        <p v-if="component.description" class="component-page__description">
          {{ component.description }}
        </p>

        <div class="component-page__columns">
          <MetricsCard :title="t('headlines.component.metrics')">
            <div v-if="heroStats.length" class="metrics-card__hero">
              <!-- The accent marks the headline, so exactly one tile carries
                   it. A category can name more than one key figure -- a gun
                   names sustained and burst DPS -- and accenting both says
                   neither is the one to read first. -->
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
              v-if="restStats.length"
              class="metrics-card__rows metrics-card__rows--split"
            >
              <div
                v-for="stat in restStats"
                :key="stat.label"
                class="metrics-card__row"
                :class="{ 'metrics-card__row--stack': stat.wide }"
              >
                <span class="metrics-card__row__label">{{ stat.label }}</span>
                <span class="metrics-card__row__value">{{ stat.value }}</span>
              </div>
            </div>

            <!-- Said out loud: 301 components carry no metric keys at all, and
                 an empty card reads as something having failed to load. -->
            <p v-if="!stats.length" class="component-page__empty">
              {{ t("labels.component.noMetrics") }}
            </p>
          </MetricsCard>

          <MetricsCard
            v-if="details.length"
            :title="t('headlines.component.identity')"
            variant="slim"
          >
            <div class="metrics-card__rows">
              <div
                v-for="entry in details"
                :key="entry.label"
                class="metrics-card__row"
                :class="{ 'metrics-card__row--stack': entry.stack }"
              >
                <span class="metrics-card__row__label">{{ entry.label }}</span>
                <span class="metrics-card__row__value">{{ entry.value }}</span>
              </div>
            </div>
          </MetricsCard>
        </div>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "index";
</style>
