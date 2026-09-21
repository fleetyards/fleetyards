<script lang="ts">
export default {
  name: "CommoditiesFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useCommodityFilters } from "@/frontend/composables/useCommodityFilters";
import {
  type CommodityQuery,
  useCommodityTypesFilters,
} from "@/services/fyApi";

type Props = {
  hideQuicksearch?: boolean;
};

withDefaults(defineProps<Props>(), {
  hideQuicksearch: false,
});

const { t } = useI18n();

// A single value in the URL comes back from `route.query` as a string, not an
// array — vue-router does no normalising — so a multi-select handed one
// straight through gets a string where it expects a list. Every
// click-to-filter link in the row lands on exactly that.
const asList = (value: unknown): string[] => {
  if (Array.isArray(value)) return value as string[];

  return value ? [value as string] : [];
};

// `buyPriceNotNull` rides in the query as the string "true", the way every
// other boolean filter does.
const asBoolean = (value: unknown): boolean =>
  value === true || value === "true";

const prefillFormValues = (): CommodityQuery => ({
  nameCont: filters.value.nameCont,
  descriptionCont: filters.value.descriptionCont,
  commodityTypeIn: asList(filters.value.commodityTypeIn),
  buyPriceNotNull: asBoolean(filters.value.buyPriceNotNull),
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useCommodityFilters(setupForm);

const form = ref<CommodityQuery>(prefillFormValues());

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const handleSubmit = () => {
  filter(form.value);
};

const { data: types } = useCommodityTypesFilters();
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <!-- The name search belongs in the header, where every other list puts it. -->
    <Teleport v-if="!hideQuicksearch" to="#header-left">
      <FormInput
        v-model="form.nameCont"
        :size="InputSizesEnum.MEDIUM"
        name="search"
        translation-key="filters.commodities.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <FormInput
      v-model="form.descriptionCont"
      name="descriptionCont"
      translation-key="filters.commodities.description"
      :no-label="true"
      :clearable="true"
    />

    <BaseSelect
      v-model="form.commodityTypeIn"
      name="commodityType"
      :options="types ?? []"
      :label="t('labels.filters.commodities.commodityType')"
      :no-label="true"
      multiple
    />

    <!-- 108 of the 232 are priced nowhere we know of, so this is not a niche
         narrowing — it is the difference between the catalogue and the part of
         it a trader can act on. Only the buy direction: a commodity a terminal
         sells is one a terminal also buys, in all but a handful of cases, and
         two toggles for one question is a worse control. -->
    <FormToggle
      v-model="form.buyPriceNotNull"
      name="buyPriceNotNull"
      :label="t('labels.filters.commodities.traded')"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
