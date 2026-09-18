<script lang="ts">
export default {
  name: "ComponentsFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComponentFilters } from "@/frontend/composables/useComponentFilters";
import {
  type ComponentQuery,
  useComponentCategoriesFilters,
  useComponentSubTypesFilters,
} from "@/services/fyApi";

const { t } = useI18n();

// A local copy prefilled from the URL, pushed back through `filter` on every
// change -- the same shape the ships form uses, so a reload restores what was
// chosen and the back button works.
const prefillFormValues = (): ComponentQuery => ({
  nameCont: filters.value.nameCont,
  descriptionCont: filters.value.descriptionCont,
  manufacturerNameCont: filters.value.manufacturerNameCont,
  categoryIn: filters.value.categoryIn || [],
  componentSubTypeIn: filters.value.componentSubTypeIn || [],
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, filters } = useComponentFilters(setupForm);

const form = ref<ComponentQuery>(prefillFormValues());

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const { data: categories } = useComponentCategoriesFilters();

// Narrowed by the chosen category, the way the endpoint expects -- unnarrowed
// it answers with 39 sub types spanning every category at once. Passed as
// `options` rather than through the select's own `query`, whose params carry
// only search/page and cannot take a category.
const subTypeParams = computed(() => {
  const chosen = form.value.categoryIn;

  return { category: Array.isArray(chosen) ? chosen[0] : chosen };
});

const { data: subTypes } = useComponentSubTypesFilters(subTypeParams);
</script>

<template>
  <form class="components-filter-form" @submit.prevent>
    <FormInput
      v-model="form.nameCont"
      :label="t('labels.filters.components.name')"
      name="nameCont"
      clearable
    />

    <FormInput
      v-model="form.descriptionCont"
      :label="t('labels.filters.components.description')"
      name="descriptionCont"
      clearable
    />

    <FormInput
      v-model="form.manufacturerNameCont"
      :label="t('labels.filters.components.manufacturer')"
      name="manufacturerNameCont"
      clearable
    />

    <!-- The two filter endpoints that match something. `classes` and
         `item-types` are deprecated: no component in the current build carries
         either column, so both could only ever return nothing. -->
    <BaseSelect
      v-model="form.categoryIn"
      name="category"
      :options="categories ?? []"
      :label="t('labels.filters.components.category')"
      multiple
    />

    <BaseSelect
      v-model="form.componentSubTypeIn"
      name="subType"
      :options="subTypes ?? []"
      :label="t('labels.filters.components.subType')"
      multiple
    />
  </form>
</template>

<style lang="scss" scoped>
.components-filter-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
