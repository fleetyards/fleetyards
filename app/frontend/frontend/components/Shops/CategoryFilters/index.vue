<script lang="ts">
export default {
  name: "ShopCategoryFilters",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type ShopCategory } from "@/services/fyApi";

type Props = {
  categories: ShopCategory[];
  total: number;
};

defineProps<Props>();

const { t } = useI18n();
const route = useRoute();

const selected = computed(() => {
  const value = route.query.categoryIn;

  if (Array.isArray(value)) return value as string[];

  return value ? [value as string] : [];
});

// One category at a time, as a link: the filter form beside the list picks
// several. `page` is dropped, a smaller result rarely has the page you were on.
const linkTo = (categoryId?: string) => ({
  name: route.name as string,
  params: route.params,
  query: { ...route.query, page: undefined, categoryIn: categoryId },
});

const isOnly = (categoryId: string) =>
  selected.value.length === 1 && selected.value[0] === categoryId;

const label = (category: ShopCategory) =>
  category.label ?? t(`labels.location.shopItemTypes.${category.itemType}`);
</script>

<!-- Every category the shop sells, with how many things are in it. -->
<template>
  <BtnGroup class="shop-category-filters" data-test="shop-category-filters">
    <Btn :to="linkTo()" :active="!selected.length">
      {{ t("labels.shopPage.all") }}
      <span class="shop-category-filters__count">{{ total }}</span>
    </Btn>
    <Btn
      v-for="category in categories"
      :key="category.id"
      :to="linkTo(category.id)"
      :active="isOnly(category.id)"
      :data-test="`shop-category-${category.id}`"
    >
      {{ label(category) }}
      <span class="shop-category-filters__count">{{ category.count }}</span>
    </Btn>
  </BtnGroup>
</template>

<style lang="scss" scoped>
.shop-category-filters {
  flex-wrap: wrap;
  margin-bottom: 12px;

  &__count {
    margin-left: 6px;
    color: var(--color-text-dim, #959595);
    font-variant-numeric: tabular-nums;
  }
}
</style>
