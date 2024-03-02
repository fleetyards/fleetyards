<template>
  <form @submit.prevent="handleSubmit">
    <FormInput
      v-model="form.nameCont"
      name="model-name"
      translation-key="filters.models.name"
      :no-label="true"
      :clearable="true"
    />

    <ManufacturerFilterGroup
      v-model="form.manufacturerIn"
      name="manufacturer"
    />

    <ProductionStatusFilterGroup
      v-model="form.productionStatusIn"
      name="production-status"
    />

    <ClassificationFilterGroup
      v-model="form.classificationIn"
      name="classification"
    />

    <FocusFilterGroup v-model="form.focusIn" name="focus" />

    <SizeFilterGroup v-model="form.sizeIn" name="size" />

    <FilterGroup
      v-model="form.pledgePriceIn"
      :options="pledgePriceOptions"
      :label="t('labels.filters.models.pledgePrice')"
      name="pledge-price"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.priceIn"
      :options="priceOptions"
      :label="t('labels.filters.models.price')"
      name="price"
      :multiple="true"
      :no-label="true"
    />

    <WillItFitFilterGroup v-model="form.willItFit" name="will-it-fit" />

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.lengthGteq"
          name="model-length-gteq"
          type="number"
          translation-key="filters.models.lengthGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          v-model="form.lengthLteq"
          name="model-length-lteq"
          type="number"
          translation-key="filters.models.lengthLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.beamGteq"
          name="model-beam-gteq"
          type="number"
          translation-key="filters.models.beamGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          v-model="form.beamLteq"
          name="model-beam-lteq"
          type="number"
          translation-key="filters.models.beamLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.heightGteq"
          name="model-height-gteq"
          type="number"
          translation-key="filters.models.heightGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          v-model="form.heightLteq"
          name="model-height-lteq"
          type="number"
          translation-key="filters.models.heightLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.pledgePriceGteq"
          name="model-pledge-price-gteq"
          type="number"
          translation-key="filters.models.pledgePriceGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.pledgePriceLteq"
          name="model-pledge-price-lteq"
          type="number"
          translation-key="filters.models.pledgePriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <FormInput
      v-model="form.priceGteq"
      name="model-price-gteq"
      type="number"
      translation-key="filters.models.priceGt"
      :no-placeholder="true"
    />

    <FormInput
      v-model="form.priceLteq"
      name="model-price-lteq"
      type="number"
      translation-key="filters.models.priceLt"
      :no-placeholder="true"
    />

    <RadioList
      v-model="form.onSaleEq"
      :label="t('labels.filters.models.onSale')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="sale"
    />

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import RadioList from "@/shared/components/base/RadioList/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import ManufacturerFilterGroup from "@/frontend/components/base/ManufacturerFilterGroup/index.vue";
import ProductionStatusFilterGroup from "@/frontend/components/base/ProductionStatusFilterGroup/index.vue";
import ClassificationFilterGroup from "@/frontend/components/base/ModelClassificationFilterGroup/index.vue";
import FocusFilterGroup from "@/frontend/components/base/ModelFocusFilterGroup/index.vue";
import SizeFilterGroup from "@/frontend/components/base/ModelSizeFilterGroup/index.vue";
import WillItFitFilterGroup from "@/frontend/components/base/ModelWillItFitFilterGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { type ModelQuery } from "@/services/fyApi";
import { Form } from "vee-validate";
import { useFilters } from "@/shared/composables/useFilters2";

const { t } = useI18n();

const prefillFormValues = () => {
  return {
    searchCont: routeQuery.value.searchCont,
    nameCont: routeQuery.value.nameCont,
    onSaleEq: routeQuery.value.onSaleEq,
    priceLteq: routeQuery.value.priceLteq,
    priceGteq: routeQuery.value.priceGteq,
    pledgePriceLteq: routeQuery.value.pledgePriceLteq,
    pledgePriceGteq: routeQuery.value.pledgePriceGteq,
    lengthLteq: routeQuery.value.lengthLteq,
    lengthGteq: routeQuery.value.lengthGteq,
    beamLteq: routeQuery.value.beamLteq,
    beamGteq: routeQuery.value.beamGteq,
    heightLteq: routeQuery.value.heightLteq,
    heightGteq: routeQuery.value.heightGteq,
    willItFit: routeQuery.value.willItFit,
    manufacturerIn: routeQuery.value.manufacturerIn || [],
    classificationIn: routeQuery.value.classificationIn || [],
    focusIn: routeQuery.value.focusIn || [],
    productionStatusIn: routeQuery.value.productionStatusIn || [],
    priceIn: routeQuery.value.priceIn || [],
    pledgePriceIn: routeQuery.value.pledgePriceIn || [],
    sizeIn: routeQuery.value.sizeIn || [],
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

interface AllowedFilters extends ModelQuery {
  fleetchart?: boolean;
}

const { filter, resetFilter, isFilterSelected, routeQuery } =
  useFilters<AllowedFilters>(
    [
      "searchCont",
      "nameCont",
      "onSaleEq",
      "priceLteq",
      "priceGteq",
      "pledgePriceLteq",
      "pledgePriceGteq",
      "lengthLteq",
      "lengthGteq",
      "beamLteq",
      "beamGteq",
      "heightLteq",
      "heightGteq",
      "willItFit",
      "manufacturerIn",
      "classificationIn",
      "focusIn",
      "productionStatusIn",
      "priceIn",
      "pledgePriceIn",
      "sizeIn",
      "fleetchart",
    ],
    ["fleetchart"],
    setupForm,
  );

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<ModelQuery>(prefillFormValues());

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);

const { booleanOptions, priceOptions, pledgePriceOptions } =
  useFilterOptions(t);
</script>

<script lang="ts">
export default {
  name: "ModelsFilterForm",
};
</script>
