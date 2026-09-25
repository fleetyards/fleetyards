<script lang="ts">
export default {
  name: "CommodityPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Availability from "@/frontend/components/Availability/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Chart from "@/shared/components/Chart/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import CommodityIcon from "@/frontend/components/Commodities/Icon/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import { type ChartSeries } from "@/shared/components/Chart/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import {
  useBlueprints as useBlueprintsQuery,
  useCommodity as useCommodityQuery,
  useCommodityPriceHistory as usePriceHistoryQuery,
} from "@/services/fyApi";

const { t, tExists, l, toNumber } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: commodity, ...asyncStatus } = useCommodityQuery(slug);

// The 90-day window, folded to a row per day in Postgres. A query of its own
// rather than part of the payload: it is a few hundred rows for one commodity
// and nothing in a list wants it.
const { data: priceHistory, ...priceHistoryStatus } =
  usePriceHistoryQuery(slug);

// Which recipes consume this. The reverse link is a filter on the blueprints
// endpoint rather than a block on this payload — `Blueprint.consuming_commodity`
// already resolves the cost options — so the page asks for it only once the
// commodity has answered with a slug.
const { data: blueprints, isPending: recipesPending } = useBlueprintsQuery(
  computed(() => ({ q: { consumingCommodity: commodity.value?.slug } })),
  { query: { enabled: computed(() => Boolean(commodity.value?.slug)) } },
);

const recipes = computed(() => blueprints.value?.items || []);

// One crumb, not two. `/catalogue/` is a redirect rather than a page of its own,
// so a "Catalogue" step above would point at whichever tenant happens to be
// first rather than at anything a reader recognises as where they came from.
const crumbs = computed<Crumb[]>(() => [
  { to: { name: "commodities" }, label: t("nav.commodities.index") },
]);

const typeLabel = computed(() => {
  const key = commodity.value?.commodityType;
  if (!key) return undefined;

  const path = `labels.commodity.types.${key}`;

  return tExists(path) ? t(path) : key;
});

const days = computed(() => priceHistory.value || []);

const categories = computed(() =>
  days.value.map((day) => l(day.recordedOn, "datetime.formats.date")),
);

// Shop-perspective, as `item_prices` stores it: `sold` is the shop selling,
// which is where a reader buys. The legend says it the reader's way round.
//
// Dashed for what a terminal pays, solid for what it charges, so the two bands
// stay apart when they overlap — six lines in one colour ramp read as noise.
const series = computed<ChartSeries[]>(() => [
  {
    name: t("labels.commodity.chart.buyHighest"),
    data: days.value.map((day) => day.soldHighest ?? null),
  },
  {
    name: t("labels.commodity.chart.buyAverage"),
    data: days.value.map((day) => day.soldAverage ?? null),
  },
  {
    name: t("labels.commodity.chart.buyLowest"),
    data: days.value.map((day) => day.soldLowest ?? null),
  },
  {
    name: t("labels.commodity.chart.sellHighest"),
    data: days.value.map((day) => day.boughtHighest ?? null),
    dashStyle: "ShortDash",
  },
  {
    name: t("labels.commodity.chart.sellAverage"),
    data: days.value.map((day) => day.boughtAverage ?? null),
    dashStyle: "ShortDash",
  },
  {
    name: t("labels.commodity.chart.sellLowest"),
    data: days.value.map((day) => day.boughtLowest ?? null),
    dashStyle: "ShortDash",
  },
]);

const details = computed(() => {
  const value = commodity.value;
  if (!value) return [];

  return [
    { label: t("labels.commodity.commodityType"), value: typeLabel.value },
    {
      // Every size the game packages it in, from the hand-carried forms below
      // one SCU up to the 32 freight crates.
      label: t("labels.commodity.containerSizes"),
      value: value.containerSizes?.length
        ? value.containerSizes.map((size) => toNumber(size)).join(" · ")
        : undefined,
      stack: true,
    },
    {
      // Only the counted ones have a single figure: a bulk commodity's unit is
      // a crate, sold in seven sizes, so there is no one volume to state.
      label: t("labels.commodity.pieceVolume"),
      value:
        value.pieceVolume != null ? toNumber(value.pieceVolume) : undefined,
    },
    {
      label: t("labels.commodity.consumable"),
      value: value.consumable ? t("labels.true") : undefined,
    },
  ].filter((entry) => entry.value);
});

watch(
  commodity,
  (value) => {
    if (!value) return;

    updateMetaInfo({
      title: t("title.commodity", { name: value.name }),
      description: value.description ?? undefined,
    });
  },
  { immediate: true },
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <div v-if="commodity" class="commodity-page">
        <BreadCrumbs :crumbs="crumbs" />

        <div class="commodity-page__masthead">
          <CommodityIcon :commodity="commodity" class="commodity-page__icon" />

          <div class="commodity-page__title">
            <h1 class="commodity-page__name">{{ commodity.name }}</h1>
            <div v-if="typeLabel" class="commodity-page__sub">
              {{ typeLabel }}
            </div>
          </div>

          <div class="commodity-page__badges">
            <!-- A commodity the current build no longer describes. It stays
                 reachable because an inventory ledger entry points at it, so it
                 says so rather than serving the last build's figures as
                 current. -->
            <Chip v-if="commodity.retired" :state="ChipStatesEnum.EXCLUDED">
              {{ t("labels.commodity.retired") }}
            </Chip>
          </div>
        </div>

        <p v-if="commodity.description" class="commodity-page__description">
          {{ commodity.description }}
        </p>

        <div class="commodity-page__columns">
          <!-- The one catalogue page on the site that can open with a chart
               rather than a table. The window is 90 days; the snapshots only
               began in September, so it is short and grows. -->
          <MetricsCard :title="t('headlines.commodity.priceHistory')">
            <Chart
              :key="`commodity-prices-${commodity.slug}`"
              name="commodity-prices"
              type="line"
              :async-status="priceHistoryStatus"
              :series="series"
              :categories="categories"
              :value-suffix="t('number.units.uec')"
              :height="360"
            />
          </MetricsCard>

          <div class="commodity-page__rail">
            <MetricsCard
              v-if="
                details.length ||
                commodity.refinesInto ||
                commodity.refinedFrom?.length
              "
              :title="t('headlines.commodity.identity')"
              variant="slim"
            >
              <div class="metrics-card__rows">
                <div
                  v-for="entry in details"
                  :key="entry.label"
                  class="metrics-card__row"
                  :class="{ 'metrics-card__row--stack': entry.stack }"
                >
                  <span class="metrics-card__row__label">{{
                    entry.label
                  }}</span>
                  <span class="metrics-card__row__value">{{
                    entry.value
                  }}</span>
                </div>

                <router-link
                  v-if="commodity.refinesInto"
                  :to="{
                    name: 'commodity',
                    params: { slug: commodity.refinesInto.slug },
                  }"
                  class="metrics-card__row commodity-page__link-row"
                >
                  <span class="metrics-card__row__label">
                    {{ t("labels.commodity.refinesInto") }}
                  </span>
                  <span class="metrics-card__row__value">
                    {{ commodity.refinesInto.name }}
                  </span>
                </router-link>

                <!-- One row per raw form, labelled once: construction
                     materials have three that share a target. -->
                <router-link
                  v-for="(source, index) in commodity.refinedFrom"
                  :key="source.id"
                  :to="{ name: 'commodity', params: { slug: source.slug } }"
                  class="metrics-card__row commodity-page__link-row"
                >
                  <span class="metrics-card__row__label">
                    {{ index === 0 ? t("labels.commodity.refinedFrom") : "" }}
                  </span>
                  <span class="metrics-card__row__value">
                    {{ source.name }}
                  </span>
                </router-link>
              </div>
            </MetricsCard>

            <!-- Above the recipe card, because when nothing trades a commodity
                 the answer it gives is "it is a crafting material". -->
            <Availability
              :availability="commodity.availability"
              :retired="commodity.retired"
              scope="commodity"
              :craftable="recipes.length > 0"
              :loading="recipesPending"
            />

            <MetricsCard
              v-if="recipes.length"
              :title="t('headlines.commodity.usedIn')"
              variant="slim"
            >
              <div class="metrics-card__rows">
                <router-link
                  v-for="recipe in recipes"
                  :key="recipe.id"
                  :to="{ name: 'blueprint', params: { slug: recipe.slug } }"
                  class="metrics-card__row metrics-card__row--stack commodity-page__link-row"
                >
                  <span class="metrics-card__row__label">
                    {{ recipe.name }}
                  </span>
                  <span class="metrics-card__row__value">
                    {{
                      (recipe.materials || []).map((m) => m.name).join(" · ")
                    }}
                  </span>
                </router-link>
              </div>
            </MetricsCard>
          </div>
        </div>
      </div>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
@import "index";
</style>
