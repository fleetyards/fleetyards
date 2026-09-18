<script lang="ts">
export default {
  name: "ComponentsFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComponentFilters } from "@/frontend/composables/useComponentFilters";
import {
  type ComponentQuery,
  useComponentCategoriesFilters,
  useComponentSubTypesFilters,
} from "@/services/fyApi";

type Props = {
  hideQuicksearch?: boolean;
};

withDefaults(defineProps<Props>(), {
  hideQuicksearch: false,
});

const { t } = useI18n();

// A local copy prefilled from the URL, pushed back through `filter` on every
// change -- the same shape the ships form uses, so a reload restores what was
// chosen and the back button works.
// A single value in the URL comes back from `route.query` as a string, not an
// array -- vue-router does no normalising -- so a multi-select handed one
// straight through gets a string where it expects a list. That was already the
// case for anyone reloading with exactly one category chosen, and every
// click-to-filter link in the table lands on it.
const asList = (value: unknown): string[] => {
  if (Array.isArray(value)) return value as string[];

  return value ? [value as string] : [];
};

const prefillFormValues = (): ComponentQuery => ({
  nameCont: filters.value.nameCont,
  descriptionCont: filters.value.descriptionCont,
  manufacturerNameCont: filters.value.manufacturerNameCont,
  categoryIn: asList(filters.value.categoryIn),
  componentSubTypeIn: asList(filters.value.componentSubTypeIn),
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useComponentFilters(setupForm);

const form = ref<ComponentQuery>(prefillFormValues());

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const handleSubmit = () => {
  filter(form.value);
};

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
  <form @submit.prevent="handleSubmit">
    <!-- The name search belongs in the header, where every other list puts it. -->
    <Teleport v-if="!hideQuicksearch" to="#header-left">
      <FormInput
        v-model="form.nameCont"
        :size="InputSizesEnum.MEDIUM"
        name="search"
        translation-key="filters.components.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <FormInput
      v-model="form.descriptionCont"
      name="descriptionCont"
      translation-key="filters.components.description"
      :no-label="true"
      :clearable="true"
    />

    <FormInput
      v-model="form.manufacturerNameCont"
      name="manufacturerNameCont"
      translation-key="filters.components.manufacturer"
      :no-label="true"
      :clearable="true"
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

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
