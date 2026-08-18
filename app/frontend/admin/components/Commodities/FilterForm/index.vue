<script lang="ts">
export default {
  name: "CommoditiesFilterForm",
};
</script>

<script lang="ts" setup>
import {
  InputSizesEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import CommodityTypeFilterGroup from "@/admin/components/base/CommodityTypeFilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { type CommodityQuery } from "@/services/fyAdminApi";
import { useCommodityFilters } from "@/admin/composables/useCommodityFilters";

const { t } = useI18n();

const { booleanOptions } = useFilterOptions();

const prefillFormValues = () => {
  return {
    nameCont: filters.value.nameCont,
    commodityTypeIn: filters.value.commodityTypeIn || [],
    uexCodeCont: filters.value.uexCodeCont,
    storeImageBlank: filters.value.storeImageBlank,
    buyPriceGteq: filters.value.buyPriceGteq,
    buyPriceLteq: filters.value.buyPriceLteq,
    sellPriceGteq: filters.value.sellPriceGteq,
    sellPriceLteq: filters.value.sellPriceLteq,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useCommodityFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<CommodityQuery>(prefillFormValues());

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport to="#header-left">
      <FormInput
        :size="InputSizesEnum.MEDIUM"
        v-model="form.nameCont"
        name="search"
        translation-key="filters.commodities.name"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <CommodityTypeFilterGroup
      v-model="form.commodityTypeIn"
      name="commodity-type"
    />

    <FormInput
      v-model="form.uexCodeCont"
      name="uexCode"
      translation-key="filters.commodities.uexCode"
      :clearable="true"
    />

    <RadioList
      v-model="form.storeImageBlank"
      :label="t('labels.filters.commodities.storeImageBlank')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="storeImageBlank"
    />

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.buyPriceGteq"
          name="commodity-buy-price-gteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.commodities.buyPriceGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.buyPriceLteq"
          name="commodity-buy-price-lteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.commodities.buyPriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.sellPriceGteq"
          name="commodity-sell-price-gteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.commodities.sellPriceGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.sellPriceLteq"
          name="commodity-sell-price-lteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.commodities.sellPriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
