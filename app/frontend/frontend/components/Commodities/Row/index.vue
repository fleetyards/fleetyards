<script lang="ts">
export default {
  name: "CommodityRow",
};
</script>

<script lang="ts" setup>
import CommodityIcon from "@/frontend/components/Commodities/Icon/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import { type RowListItemBadge } from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Commodity } from "@/services/fyApi";

type Props = {
  commodity: Commodity;
};

const props = defineProps<Props>();

const { t, tExists, toNumber } = useI18n();

const route = useRoute();

// Every value the catalogue can be narrowed by is a link that narrows it. The
// filters live in the route query rather than in a store, so this is a plain
// link: shareable, undone by the back button, and read back by the filter form.
//
// `page` is dropped — the row that was clicked is almost never on the same page
// of a different, smaller result set.
const filterLink = (key: string, value: string) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

const typeLabel = computed(() => {
  const key = props.commodity.commodityType;
  if (!key) return undefined;

  const path = `labels.commodity.types.${key}`;

  return tExists(path) ? t(path) : key;
});

// Shop-perspective, as `item_prices` stores it: what a terminal sells it for is
// what the reader pays, so `sellPrice` is the figure to buy at. Naming them the
// other way round in the row is how a trade list is read.
const paidFor = computed(() => props.commodity.buyPrice);
const costsToBuy = computed(() => props.commodity.sellPrice);

const price = (value?: number | null) =>
  value == null ? undefined : toNumber(value, "integer");

// Nothing at all rather than a dash when the commodity is traded nowhere: 108
// of the 232 are, and a column of dashes says less than a column of nothing.
const badges = computed<RowListItemBadge[]>(() => {
  const list: RowListItemBadge[] = [];

  if (costsToBuy.value != null) {
    list.push({
      key: "buy",
      label: t("labels.commodity.buyPrice"),
      value: String(price(costsToBuy.value)),
    });
  }

  if (paidFor.value != null) {
    list.push({
      key: "sell",
      label: t("labels.commodity.sellPrice"),
      value: String(price(paidFor.value)),
    });
  }

  return list;
});
</script>

<template>
  <RowListItem
    class="commodity-row"
    :to="{ name: 'commodity', params: { slug: commodity.slug } }"
    :badges="badges"
  >
    <template #leading>
      <CommodityIcon :commodity="commodity" />
    </template>

    <template #name>{{ commodity.name }}</template>

    <template #sub>
      <router-link
        v-if="commodity.commodityType"
        :to="filterLink('commodityTypeIn', commodity.commodityType)"
      >
        {{ typeLabel }}
      </router-link>
      <Chip v-if="commodity.retired" :state="ChipStatesEnum.EXCLUDED">
        {{ t("labels.commodity.retired") }}
      </Chip>
    </template>
  </RowListItem>
</template>
