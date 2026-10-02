<script lang="ts">
export default {
  name: "ShopItemRow",
};
</script>

<script lang="ts" setup>
import RowListItem from "@/shared/components/RowListItem/index.vue";
import { type RowListItemBadge } from "@/shared/components/RowListItem/types";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";
import { catalogueTokenIcon } from "@/shared/utils/CatalogueTokens";
import { useI18n } from "@/shared/composables/useI18n";
import { type ShopItem } from "@/services/fyApi";

type Props = {
  item: ShopItem;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const to = computed(() =>
  catalogueItemRoute({ type: props.item.itemType, slug: props.item.slug }),
);

const category = computed(
  () =>
    props.item.categoryLabel ??
    t(`labels.location.shopItemTypes.${props.item.itemType}`),
);

const price = (value: number) =>
  `${toNumber(value, "integer")} ${t("number.units.uec")}`;

const badges = computed<RowListItemBadge[]>(() =>
  [
    {
      key: "buy",
      label: t("labels.availability.buy"),
      value: props.item.buyPrice,
    },
    {
      key: "rent",
      label: t("labels.availability.rent"),
      value: props.item.rentalPrice,
    },
    {
      key: "sell",
      label: t("labels.availability.sell"),
      value: props.item.sellPrice,
    },
  ]
    .filter((badge) => badge.value !== null && badge.value !== undefined)
    .map((badge) => ({ ...badge, value: price(badge.value as number) })),
);
</script>

<template>
  <RowListItem class="shop-item-row" :to="to" :badges="badges">
    <template #leading>
      <span class="shop-item-row__icon" aria-hidden="true">
        <i :class="catalogueTokenIcon(item.itemType)" />
      </span>
    </template>

    <template #name>{{ item.name }}</template>

    <template #sub>
      <span v-if="item.manufacturer">{{ item.manufacturer.name }}</span>
      <span>{{ category }}</span>
    </template>
  </RowListItem>
</template>

<style lang="scss" scoped>
.shop-item-row__icon {
  display: inline-flex;
  flex: none;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  font-size: 20px;
  color: var(--color-muted, #7a8288);
}
</style>
