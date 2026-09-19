<script lang="ts">
export default {
  name: "BlueprintsFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useBlueprintFilters } from "@/frontend/composables/useBlueprintFilters";
import { useSessionStore } from "@/frontend/stores/session";
import {
  type BlueprintQuery,
  BlueprintCraftableTypeEnum,
  useFiltersBlueprintsMaterials,
} from "@/services/fyApi";

type Props = {
  hideQuicksearch?: boolean;
};

withDefaults(defineProps<Props>(), {
  hideQuicksearch: false,
});

const { t } = useI18n();

const sessionStore = useSessionStore();

// A single value in the URL comes back from `route.query` as a string rather
// than an array -- vue-router does no normalising -- so a multi-select handed
// one straight through gets a string where it expects a list. Every
// click-to-filter link on a row lands on exactly that case.
const asList = (value: unknown): string[] => {
  if (Array.isArray(value)) return value as string[];

  return value ? [value as string] : [];
};

const prefillFormValues = (): BlueprintQuery => ({
  nameCont: filters.value.nameCont,
  craftableTypeIn: asList(
    filters.value.craftableTypeIn ?? filters.value.craftableTypeEq,
  ) as BlueprintCraftableTypeEnum[],
  consumingCommodityIn: asList(
    filters.value.consumingCommodityIn ?? filters.value.consumingCommodity,
  ),
  withKnownSource: filters.value.withKnownSource,
  owned: filters.value.owned,
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useBlueprintFilters(setupForm);

const form = ref<BlueprintQuery>(prefillFormValues());

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const handleSubmit = () => {
  filter(form.value);
};

// What the recipe makes.
//
// Commodity is left out. The association allows it and the API enum names it,
// but no blueprint in the build makes one: the four outputs that classify as
// commodities are mission carryables -- Probe, two Metamaterial Test samples,
// the TH-01 Propulsor -- which are named outside the commodity namespace and
// so resolve to no commodity at all. Offering it would be a filter that can
// only ever come back empty, which is what the deprecated component `classes`
// and `item-types` filters already are.
//
// Sourced from the generated enum rather than retyped, so if a patch ever does
// add one the option appears by removing one line rather than by remembering.
const UNCRAFTED_TYPES: BlueprintCraftableTypeEnum[] = [
  BlueprintCraftableTypeEnum.COMMODITY,
];

const craftableTypes = computed(() =>
  Object.values(BlueprintCraftableTypeEnum)
    .filter((value) => !UNCRAFTED_TYPES.includes(value))
    .map((value) => ({
      value,
      label: t(`labels.blueprint.craftableTypes.${value}`),
    })),
);

// Three states, not a checkbox: "only recipes I can go and get", "only the
// ones nothing hands out", and no opinion. A checkbox could not say the
// middle one, and 901 of the 1,607 recipes are in it -- more of the catalogue
// than the other case.
const sourceOptions = computed(() => [
  { value: "true", label: t("labels.filters.blueprints.withSource") },
  { value: "false", label: t("labels.filters.blueprints.withoutSource") },
]);

// The 37 materials recipes actually ask for, which is what the endpoint
// answers with -- not the 232-row commodity catalogue.
const { data: materials } = useFiltersBlueprintsMaterials();

// Kept as the string the option carries, never cast to a boolean here.
// `useFilters` drops every falsy value before it builds the route, so a
// `withKnownSource` of `false` was deleted on its way out and "no known
// source" quietly returned the whole catalogue. "false" is truthy and
// survives, and the API casts it -- which is what the URL would have carried
// either way, since a query string has only strings in it.
const sourceValue = computed({
  get: () => {
    const value = form.value.withKnownSource;
    if (value === undefined || value === null) return undefined;

    return String(value);
  },
  set: (value?: string) => {
    form.value = {
      ...form.value,
      withKnownSource: value as unknown as boolean | undefined,
    };
  },
});

// Signed out this can only ask for nothing or for everything, so it is not
// offered -- the API still answers it, because a URL somebody shared is not
// theirs to break.
const ownedVisible = computed(() => sessionStore.isAuthenticated);

const ownedOptions = computed(() => [
  { value: "true", label: t("labels.filters.blueprints.owned") },
  { value: "false", label: t("labels.filters.blueprints.notOwned") },
]);

// A string for the reason `sourceValue` carries one: `useFilters` drops every
// falsy value on its way into the route, so a boolean `false` was deleted and
// "the ones I do not have" quietly returned the whole catalogue.
const ownedValue = computed({
  get: () => {
    const value = form.value.owned;
    if (value === undefined || value === null) return undefined;

    return String(value);
  },
  set: (value?: string) => {
    form.value = {
      ...form.value,
      owned: value as unknown as boolean | undefined,
    };
  },
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
        translation-key="filters.blueprints.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <BaseSelect
      v-model="form.craftableTypeIn"
      name="craftableType"
      :options="craftableTypes"
      :label="t('labels.filters.blueprints.craftableType')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="form.consumingCommodityIn"
      name="material"
      :options="materials ?? []"
      :label="t('labels.filters.blueprints.material')"
      :no-label="true"
      multiple
      searchable
    />

    <BaseSelect
      v-if="ownedVisible"
      v-model="ownedValue"
      name="owned"
      :options="ownedOptions"
      :label="t('labels.filters.blueprints.ownedFilter')"
      :no-label="true"
    />

    <BaseSelect
      v-model="sourceValue"
      name="withKnownSource"
      :options="sourceOptions"
      :label="t('labels.filters.blueprints.source')"
      :no-label="true"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
