<script lang="ts">
export default {
  name: "ShipHistoryPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Chart from "@/shared/components/Chart/index.vue";
import MetricsList from "@/shared/components/MetricsList/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import {
  type Model,
  useModelSales as useModelSalesQuery,
  useModelWishlistHistory as useModelWishlistHistoryQuery,
  useModelChanges as useModelChangesQuery,
  useModelPriceHistory as useModelPriceHistoryQuery,
} from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t, tExists, l, toNumber, toDollar } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const route = useRoute();

const modelSlug = computed(() => route.params.slug as string);

const { data: sales } = useModelSalesQuery(modelSlug);
const { data: wishlistHistory, ...wishlistHistoryStatus } =
  useModelWishlistHistoryQuery(modelSlug);
const { data: changes } = useModelChangesQuery(modelSlug);
const { data: priceHistory } = useModelPriceHistoryQuery(modelSlug);

const metaTitle = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return t("title.shipHistory", { name: props.model.name });
});

const crumbs = computed<Crumb[]>(() => {
  if (!props.model) {
    return [];
  }

  return [
    {
      to: { name: "ships", hash: `#${props.model.slug}` },
      label: t("nav.ships.index"),
    },
    {
      to: { name: "ship", params: { slug: modelSlug.value } },
      label: props.model.name,
    },
  ];
});

const date = (value?: string | null) =>
  value ? l(value, "datetime.formats.date") : "—";

/*
 * Recording started on 2026-09-02, so a ship with nothing here is the normal
 * case for months rather than a fault. Every panel says "nothing recorded yet"
 * rather than showing an empty frame.
 */
const saleMetrics = computed(() => [
  {
    id: "count",
    label: t("labels.shipHistory.salesCount"),
    value: String(sales.value?.salesCount ?? 0),
  },
  {
    id: "last",
    label: t("labels.shipHistory.lastSale"),
    value: date(sales.value?.lastSaleAt),
  },
  {
    id: "gap",
    label: t("labels.shipHistory.averageGap"),
    value: sales.value?.averageDaysBetweenSales
      ? t("labels.shipHistory.days", {
          count: sales.value.averageDaysBetweenSales,
        })
      : "—",
  },
]);

/*
 * `field` is the column name the diff was recorded under. Eleven of the twenty-one
 * diffable facts already have a label on the ship page; the rest fall back to
 * the column made readable, which beats showing `hull_health` to a reader.
 */
const fieldLabel = (field: string) => {
  const key = `labels.model.${field.replace(/_(\w)/g, (_, c) => c.toUpperCase())}`;

  if (tExists(key)) {
    return t(key);
  }

  const words = field.replace(/_/g, " ");

  return words.charAt(0).toUpperCase() + words.slice(1);
};

const priceChange = (from?: number | null, to?: number | null) => {
  if (from === null || from === undefined)
    return t("labels.shipHistory.firstPriced");
  if (to === null || to === undefined)
    return t("labels.shipHistory.priceRemoved");

  return `${toDollar(from)} → ${toDollar(to)}`;
};

const updateTitle = () => {
  if (!props.model) {
    return;
  }

  updateMetaInfo({
    title: metaTitle.value,
    description: props.model.description || undefined,
    image: props.model.media.storeImage?.largeUrl,
    type: "article",
  });
};

onMounted(() => updateTitle());

watch(() => props.model, updateTitle);
</script>

<template>
  <div class="row">
    <div class="col-12">
      <BreadCrumbs :crumbs="crumbs" />
      <h1>{{ metaTitle }}</h1>
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.shipHistory.sales") }}
        </PanelHeading>
        <PanelBody>
          <MetricsList :metrics="saleMetrics" />
          <Empty
            v-if="!sales?.sales?.length"
            inline
            hide-actions
            :name="t('labels.shipHistory.sales')"
          >
            <template #info>{{
              t("labels.shipHistory.notRecordedYet")
            }}</template>
          </Empty>
          <ul v-else class="ship-history-list" data-test="ship-sales">
            <li v-for="sale in sales.sales" :key="sale.id">
              <span>{{ date(sale.startedAt) }}</span>
              <span>
                {{
                  sale.ongoing
                    ? t("labels.shipHistory.ongoing")
                    : t("labels.shipHistory.days", {
                        count: sale.durationInDays || 0,
                      })
                }}
              </span>
            </li>
          </ul>
        </PanelBody>
      </Panel>
    </div>

    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.shipHistory.priceHistory") }}
        </PanelHeading>
        <PanelBody>
          <Empty
            v-if="!priceHistory?.length"
            inline
            hide-actions
            :name="t('labels.shipHistory.priceHistory')"
          >
            <template #info>{{
              t("labels.shipHistory.notRecordedYet")
            }}</template>
          </Empty>
          <ul v-else class="ship-history-list" data-test="ship-price-history">
            <li v-for="point in priceHistory" :key="point.changedAt">
              <span>{{ date(point.changedAt) }}</span>
              <span>{{ priceChange(point.from, point.to) }}</span>
            </li>
          </ul>
        </PanelBody>
      </Panel>
    </div>
  </div>

  <div class="row">
    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.shipHistory.wishlist") }}
        </PanelHeading>
        <PanelBody>
          <Chart
            key="ship-wishlist-history"
            name="ship-wishlist-history"
            :async-status="wishlistHistoryStatus"
            :options="wishlistHistory"
            type="column"
          />
        </PanelBody>
      </Panel>
    </div>

    <div class="col-12 col-md-6">
      <Panel>
        <PanelHeading :level="HeadingLevelEnum.H2">
          {{ t("labels.shipHistory.patchChanges") }}
        </PanelHeading>
        <PanelBody>
          <Empty
            v-if="!changes?.length"
            inline
            hide-actions
            :name="t('labels.shipHistory.patchChanges')"
          >
            <template #info>{{
              t("labels.shipHistory.notRecordedYet")
            }}</template>
          </Empty>
          <ul v-else class="ship-history-list" data-test="ship-changes">
            <li v-for="change in changes" :key="change.id">
              <span>{{ change.toVersion }}</span>
              <span>{{ fieldLabel(change.field) }}</span>
              <span>
                {{ change.oldValue === null ? "—" : toNumber(change.oldValue) }}
                →
                {{ change.newValue === null ? "—" : toNumber(change.newValue) }}
              </span>
            </li>
          </ul>
        </PanelBody>
      </Panel>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.ship-history-list {
  margin: 0;
  padding: 0;
  list-style: none;

  li {
    display: flex;
    justify-content: space-between;
    gap: 1rem;
    padding: 0.5rem 0;
    border-bottom: 1px solid rgb(255 255 255 / 8%);

    &:last-child {
      border-bottom: 0;
    }
  }
}
</style>
