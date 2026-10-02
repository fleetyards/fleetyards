<script lang="ts">
export default {
  name: "ShopFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import { type ShopCategory, type ShopItemQuery } from "@/services/fyApi";

type Props = {
  categories: ShopCategory[];
};

const props = defineProps<Props>();

const { t } = useI18n();

// A single value in the URL comes back from `route.query` as a string, not an
// array -- which is what a quick filter above the list writes.
const asList = (value: unknown): string[] => {
  if (Array.isArray(value)) return value as string[];

  return value ? [value as string] : [];
};

const prefillFormValues = (): ShopItemQuery => ({
  nameCont: filters.value.nameCont,
  categoryIn: asList(filters.value.categoryIn),
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<ShopItemQuery>({ updateCallback: setupForm });

const form = ref<ShopItemQuery>(prefillFormValues());

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const categoryLabel = (category: ShopCategory) =>
  category.label ?? t(`labels.location.shopItemTypes.${category.itemType}`);

const categoryOptions = computed(() =>
  props.categories.map((category) => ({
    value: category.id,
    label: `${categoryLabel(category)} (${category.count})`,
  })),
);
</script>

<template>
  <form @submit.prevent="filter(form)">
    <FormInput
      v-model="form.nameCont"
      name="nameCont"
      :label="t('labels.shopPage.search')"
      :placeholder="t('labels.shopPage.search')"
      :no-label="true"
      :clearable="true"
    />

    <BaseSelect
      v-model="form.categoryIn"
      name="categoryIn"
      :options="categoryOptions"
      :label="t('labels.shopPage.categories')"
      :no-label="true"
      multiple
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
