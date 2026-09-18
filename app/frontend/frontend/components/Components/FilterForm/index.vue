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
import ManufacturerSelect from "@/frontend/components/base/ManufacturerSelect/index.vue";
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
  manufacturerSlugIn: asList(filters.value.manufacturerSlugIn),
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
// Narrowed only while exactly one category is chosen. The endpoint takes a
// single category, so picking the first of several offered sub types belonging
// to that one and hid every sub type of the rest -- a combination the reader
// had selected and then could not complete. Unnarrowed is the honest answer
// there: all 29, of which the ones that match are a subset.
//
// An empty object rather than `{category: undefined}`: the key the query is
// cached under is built from whatever is passed, and a key carrying an
// undefined is not the key an unnarrowed request should have.
const subTypeParams = computed(() => {
  const chosen = form.value.categoryIn;
  const categories = Array.isArray(chosen) ? chosen : [chosen].filter(Boolean);

  return categories.length === 1 ? { category: categories[0] } : {};
});

const { data: subTypes } = useComponentSubTypesFilters(subTypeParams);

// A sub type the control cannot show is one the reader cannot remove. Dropping
// a category narrows this list, and a sub type belonging to the category just
// removed stayed in the filter while disappearing from the select -- the
// catalogue came back empty with nothing on screen saying why.
//
// Only once options have arrived: they are undefined on the first render, and
// pruning against nothing would clear a selection restored from the URL.
watch(subTypes, (options) => {
  if (!options?.length) return;

  const available = new Set(options.map((option) => option.value));
  const chosen = form.value.componentSubTypeIn || [];
  const kept = chosen.filter((value) => available.has(value));

  if (kept.length !== chosen.length) {
    form.value = { ...form.value, componentSubTypeIn: kept };
  }
});
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

    <!-- The same control the ships form uses, by slug rather than by a
         substring of the name: "Aegis" also matches nothing else, but a maker
         whose name is inside another's would quietly bring both. -->
    <ManufacturerSelect v-model="form.manufacturerSlugIn" name="manufacturer" />

    <!-- The two filter endpoints that match something. `classes` and
         `item-types` are deprecated: no component in the current build carries
         either column, so both could only ever return nothing. -->
    <!-- `no-label` puts the label inside the control as its prompt rather than
         above it, which is what `ManufacturerSelect` beside it does and what
         the ships form looks like. A stack of three selects with two labelled
         and one not reads as a mistake. -->
    <BaseSelect
      v-model="form.categoryIn"
      name="category"
      :options="categories ?? []"
      :label="t('labels.filters.components.category')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="form.componentSubTypeIn"
      name="subType"
      :options="subTypes ?? []"
      :label="t('labels.filters.components.subType')"
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
