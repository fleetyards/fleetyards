<script lang="ts">
export default {
  name: "ToolsTradeRoutesPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import RunBar from "@/frontend/components/TradeRoutes/RunBar/index.vue";
import BestRun from "@/frontend/components/TradeRoutes/BestRun/index.vue";
import RunRow from "@/frontend/components/TradeRoutes/RunRow/index.vue";
import { useTradeRouteRun } from "@/frontend/composables/useTradeRouteRun";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  TradeRouteSortingEnum,
  useModel,
  type TradeRoute,
  useTradeRoutes,
} from "@/services/fyApi";

const { t } = useI18n();

const route = useRoute();

const comlink = useComlink();

const { modelSlug, origin, sort, apiQuery, update } = useTradeRouteRun();

const { data: ship } = useModel(
  computed(() => modelSlug.value || ""),
  {
    query: { enabled: computed(() => !!modelSlug.value) },
  },
);

// The ship as the page resolved it, not the slug in the URL: a link to a ship
// that is gone gets no ship figures from the API, so it gets no ship-only
// sorts or columns either.
const hasShip = computed(() => !!ship.value);

const PER_PAGE = "25";

const page = ref(1);

const queryParams = computed(() => ({
  page: String(page.value),
  perPage: PER_PAGE,
  q: apiQuery.value,
}));

const {
  data: tradeRoutes,
  isLoading,
  isFetching,
} = useTradeRoutes(queryParams);

/*
 * Accumulated rather than replaced, so "Show more runs" grows the list. A
 * changed run starts it again: page 1 of a different question is not page 4
 * of this one.
 */
const items = ref<TradeRoute[]>([]);

watch(
  () => JSON.stringify(apiQuery.value),
  () => {
    page.value = 1;
    items.value = [];
  },
);

watch(
  tradeRoutes,
  (value) => {
    if (!value) return;

    const fresh = value.items ?? [];

    items.value =
      page.value === 1
        ? fresh
        : [
            ...items.value,
            ...fresh.filter(
              (item) => !items.value.some((held) => held.id === item.id),
            ),
          ];
  },
  { immediate: true },
);

const hasMore = computed(
  () => page.value < (tradeRoutes.value?.meta?.pagination?.totalPages ?? 1),
);

const loadMore = () => {
  page.value += 1;
};

// An ungrouped list of one purchase's destinations has no single best run.
const showBestRun = computed(() => !origin.value);

// Only a run the ship can fly earns the card. The API ranks those first, so
// when the first one can't be flown, none can, and every run stays a row.
const bestRun = computed(() => {
  const first = items.value[0];

  return showBestRun.value && first && !first.unflyableReason
    ? first
    : undefined;
});

const rows = computed(() =>
  bestRun.value ? items.value.slice(1) : items.value,
);

const firstRank = computed(() => (bestRun.value ? 2 : 1));

const topValue = computed(() =>
  Math.max(
    0,
    ...rows.value.map((item) =>
      hasShip.value ? (item.profitPerRun ?? 0) : item.profitPerScu,
    ),
  ),
);

const sortOptions = computed(() =>
  hasShip.value
    ? [
        {
          value: TradeRouteSortingEnum.PROFIT_PER_RUN_DESC,
          label: t("labels.tradeRoutes.profitPerRun"),
        },
        {
          value: TradeRouteSortingEnum.PROFIT_PER_DISTANCE_DESC,
          label: t("labels.tradeRoutes.profitPerDistance"),
        },
        {
          value: TradeRouteSortingEnum.PROFIT_PER_SCU_DESC,
          label: t("labels.tradeRoutes.profitPerScu"),
        },
      ]
    : [
        {
          value: TradeRouteSortingEnum.PROFIT_PER_SCU_DESC,
          label: t("labels.tradeRoutes.profitPerScu"),
        },
        {
          value: TradeRouteSortingEnum.DISTANCE_ASC,
          label: t("labels.tradeRoutes.shortest"),
        },
      ],
);

const activeSort = computed(
  () =>
    sortOptions.value.find((option) => option.value === sort.value)?.value ??
    sortOptions.value[0].value,
);

const othersLink = (commodity: string, originId: string) => ({
  name: route.name as string,
  query: { ...route.query, commodity, origin: originId },
});

const openPicker = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/TradeRoutes/PickerModal/index.vue"),
    wide: true,
  });
};

const setShip = async (slug?: string) => {
  await update({ ship: slug, s: undefined });
};

const offModelPicked = ref<() => void>();

onMounted(() => {
  offModelPicked.value = comlink.on("trade-routes-model-picked", setShip);
});

onUnmounted(() => {
  offModelPicked.value?.();
});
</script>

<template>
  <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>

  <p class="trade-routes__intro">{{ t("labels.tradeRoutes.intro") }}</p>

  <div class="trade-routes">
    <RunBar :ship="ship" @pick-ship="openPicker" />

    <div v-if="origin" class="trade-routes__origin">
      <span>
        {{
          t("labels.tradeRoutes.everyBuyer", {
            commodity: items[0]?.commodity.name ?? "",
            terminal: items[0]?.originTerminal.name ?? "",
          })
        }}
      </span>
      <Btn @click="update({ origin: undefined, commodity: undefined })">
        {{ t("actions.tradeRoutes.backToRuns") }}
      </Btn>
    </div>

    <RowsSkeleton v-if="isLoading && !items.length" :count="6" meta trailing />

    <p v-else-if="!items.length" class="trade-routes__empty">
      {{ t("labels.tradeRoutes.empty") }}
    </p>

    <template v-else>
      <div class="trade-routes__lead">
        <BestRun
          v-if="bestRun"
          :route="bestRun"
          :ship-cargo="ship?.metrics.cargo ?? undefined"
        >
          <template #others>
            <router-link
              v-if="bestRun.otherDestinations"
              :to="
                othersLink(bestRun.commodity.slug, bestRun.originTerminal.id)
              "
            >
              {{
                t("labels.tradeRoutes.otherBuyers", {
                  count: bestRun.otherDestinations,
                })
              }}
            </router-link>
          </template>
        </BestRun>

        <a
          class="trade-routes__credit"
          href="https://uexcorp.space"
          target="_blank"
          rel="noopener"
        >
          {{ t("labels.tradeRoutes.poweredByUex") }}
        </a>
      </div>

      <section class="trade-routes__more" aria-labelledby="more-runs">
        <div class="trade-routes__more-head">
          <h2 id="more-runs" class="trade-routes__more-title">
            {{
              bestRun
                ? t("labels.tradeRoutes.moreRuns")
                : t("labels.tradeRoutes.runs")
            }}
          </h2>
          <div class="trade-routes__sort">
            <span class="trade-routes__sort-label">
              {{ t("labels.tradeRoutes.rankBy") }}
            </span>
            <BtnGroup segmented>
              <Btn
                v-for="option in sortOptions"
                :key="option.value"
                :active="activeSort === option.value"
                @click="update({ s: option.value })"
              >
                {{ option.label }}
              </Btn>
            </BtnGroup>
          </div>
        </div>

        <div
          v-if="rows.length"
          class="trade-routes__table"
          :class="{
            'trade-routes__table--ship': hasShip,
            'is-fetching': isFetching && page === 1,
          }"
          role="table"
          :aria-label="t('labels.tradeRoutes.runs')"
        >
          <div class="trade-routes__table-head" role="row">
            <span role="columnheader">#</span>
            <span role="columnheader">
              {{ t("labels.tradeRoutes.commodity") }}
            </span>
            <span role="columnheader">
              {{ t("labels.tradeRoutes.buySell") }}
            </span>
            <span v-if="hasShip" role="columnheader">
              {{ t("labels.tradeRoutes.load") }}
            </span>
            <span v-if="hasShip" role="columnheader">
              {{ t("labels.tradeRoutes.spend") }}
            </span>
            <span role="columnheader">
              {{ t("labels.tradeRoutes.distance") }}
            </span>
            <span role="columnheader">
              {{ t("labels.tradeRoutes.prices") }}
            </span>
            <span role="columnheader" class="trade-routes__right">
              {{ t("labels.tradeRoutes.profit") }}
            </span>
          </div>
          <RunRow
            v-for="(item, index) in rows"
            :key="item.id"
            :route="item"
            :rank="firstRank + index"
            :top-value="topValue"
            :ship-name="ship?.name"
          />
        </div>
        <div v-if="hasMore" class="trade-routes__more-action">
          <Btn :loading="isFetching" @click="loadMore">
            {{ t("actions.tradeRoutes.showMore") }}
          </Btn>
        </div>
      </section>
    </template>

    <footer class="trade-routes__footer">
      {{ t("labels.tradeRoutes.loadExplained") }}
    </footer>
  </div>
</template>

<style lang="scss" scoped>
.trade-routes__intro {
  max-width: 640px;
  color: var(--color-text-dim, #959595);
}

.trade-routes {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.trade-routes__origin {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 12px 16px;
  border: 1px solid $gray-dark;
  border-radius: 10px;
}

.trade-routes__empty {
  padding: 32px;
  border: 1px dashed $gray-dark;
  border-radius: 10px;
  color: var(--color-text-dim, #959595);
  text-align: center;
}

.trade-routes__more {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.trade-routes__more-head {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.trade-routes__more-title {
  margin: 0;
  color: #fff;
  font-size: 1.15rem;
  font-weight: 700;
}

.trade-routes__sort {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
}

.trade-routes__sort-label {
  color: var(--color-text-dim, #959595);
}

.trade-routes__table {
  --run-row-columns: 40px minmax(0, 1.2fr) minmax(0, 2.6fr) 80px 110px
    minmax(0, 180px);

  overflow: hidden;
  border: 1px solid $gray-dark;
  border-radius: 10px;
  background: $panel-bg;
  transition: opacity 0.15s;

  &.is-fetching {
    opacity: 0.6;
  }
}

.trade-routes__table--ship {
  --run-row-columns: 40px minmax(0, 1.2fr) minmax(0, 2.6fr) 110px 110px 80px
    110px minmax(0, 180px);
}

.trade-routes__table-head {
  display: grid;
  grid-template-columns: var(--run-row-columns);
  gap: 16px;
  padding: 12px 20px;
  border-bottom: 1px solid $gray-dark;
  color: var(--color-text-dim, #959595);
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.trade-routes__more-action {
  display: flex;
  justify-content: center;
}

.trade-routes__right {
  text-align: right;
}

.trade-routes__lead {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.trade-routes__credit {
  align-self: flex-end;
  font-size: 0.85rem;
}

.trade-routes__footer {
  color: var(--color-text-dim, #959595);
  font-size: 0.85rem;
}

@media (max-width: $desktop-breakpoint) {
  .trade-routes__table-head {
    display: none;
  }
}
</style>
