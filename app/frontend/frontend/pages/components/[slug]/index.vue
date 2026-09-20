<script lang="ts">
export default {
  name: "ComponentPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import Availability from "@/frontend/components/Components/Availability/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useComponentStats } from "@/frontend/composables/useComponentStats";
import { categoryIcon } from "@/frontend/components/Models/Hardpoints/categoryIcon";
import {
  type Component,
  useBlueprints as useBlueprintsQuery,
  BlueprintCraftableTypeEnum,
} from "@/services/fyApi";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const { t, tExists } = useI18n();
const { updateMetaInfo } = useMetaInfo();

// The shell above resolved it, so every reader below is the prop rather than a
// query of its own -- the history tab is a sibling route and would otherwise
// fetch the same component a second time.
const component = computed(() => props.component);

const stats = useComponentStats(component);

// What this can be crafted from. Asked only once the component has arrived,
// since the recipe is looked up by its id -- 476 of the catalogue's components
// have one, so most pages get an empty answer and no card.
const { data: blueprints, isPending: recipesPending } = useBlueprintsQuery(
  computed(() => ({
    q: {
      craftableTypeEq: BlueprintCraftableTypeEnum.COMPONENT,
      craftableIdEq: component.value?.id,
    },
  })),
  {
    query: { enabled: computed(() => Boolean(component.value?.id)) },
  },
);

const recipes = computed(() => blueprints.value?.items || []);

// The renderer already marks the figures worth leading with. Those become hero
// tiles and the rest fall into the split list below, which is the metrics
// card's own division rather than a new one -- see metricsCard.scss.
const heroStats = computed(() => stats.value.filter((stat) => stat.primary));
const restStats = computed(() => stats.value.filter((stat) => !stat.primary));

// One crumb, not two. `/catalogue/` is a redirect rather than a page of its
// own, so a "Catalogue" step above would point at whichever tenant happens to
// be first rather than at anything a reader recognises as where they came from.
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
    // The other half of "what fits where". Listed after the port's demands
    // because it is the longer of the two and carries flags -- `flightReady`,
    // `weaponMountUsable` -- beside the tags a port actually matches on.
    {
      label: t("headlines.component.tags"),
      value: value.tags?.join(" · "),
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
          <span class="component-page__badge-value">{{ component.size }}</span>
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

    <router-link
      class="component-page__history-link"
      :to="{ name: 'component-history', params: { slug: component.slug } }"
    >
      <i class="fa-light fa-clock-rotate-left" aria-hidden="true" />
      <span>{{ t("nav.componentHistory") }}</span>
    </router-link>

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

      <div class="component-page__rail">
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

        <!-- Above the recipe card, because when nothing sells a component the
             answer it gives is "made from the recipe below". -->
        <Availability
          :component="component"
          :craftable="recipes.length > 0"
          :loading="recipesPending"
        />

        <MetricsCard
          v-if="recipes.length"
          :title="t('headlines.component.craftedFrom')"
          variant="slim"
        >
          <div class="metrics-card__rows">
            <router-link
              v-for="recipe in recipes"
              :key="recipe.id"
              :to="{ name: 'blueprint', params: { slug: recipe.slug } }"
              class="metrics-card__row metrics-card__row--stack component-page__recipe"
            >
              <span class="metrics-card__row__label">{{ recipe.name }}</span>
              <span class="metrics-card__row__value">
                {{ (recipe.materials || []).map((m) => m.name).join(" · ") }}
              </span>
            </router-link>
          </div>
        </MetricsCard>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
