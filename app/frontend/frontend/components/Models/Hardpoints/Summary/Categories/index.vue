<script lang="ts">
export default {
  name: "HardpointsSummaryCategories",
};
</script>

<script lang="ts" setup>
import CategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import { HardpointCategoryEnum } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { type MinimalCategory } from "../../summaryRows";
import SummaryRow from "../Row/index.vue";

interface Props {
  categories: MinimalCategory[];
}

defineProps<Props>();

const { t } = useI18n();

const categoryLabel = (category: HardpointCategoryEnum) =>
  category === HardpointCategoryEnum.WEAPONS
    ? t("labels.hardpoints.guns")
    : t(`labels.hardpoint.categories.${category}`);
</script>

<template>
  <div
    v-for="{ category, rows } in categories"
    :key="category"
    class="summary-category"
    :class="{ 'summary-category--bare': rows[0]?.total }"
  >
    <div v-if="!rows[0]?.total" class="summary-category__label">
      <CategoryIcon :category="category" class="summary-category__icon" />
      {{ categoryLabel(category) }}
    </div>
    <SummaryRow v-for="row in rows" :key="row.key" :row="row" />
  </div>
</template>

<style lang="scss" scoped>
.summary-category {
  margin-top: 10px;

  &:first-child {
    margin-top: 0;
  }

  &--bare {
    margin-top: 0;
  }

  &__label {
    --hardpoint-category-icon-size: 16px;

    display: flex;
    align-items: center;
    gap: 6px;
    margin-bottom: 2px;
    color: var(--color-text-dim);
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 0.625rem;
    letter-spacing: 0.16em;
    text-transform: uppercase;
  }

  &__icon {
    color: var(--color-muted);
  }
}
</style>
