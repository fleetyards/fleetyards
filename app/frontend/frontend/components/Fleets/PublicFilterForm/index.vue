<script lang="ts">
export default {
  name: "PublicFleetFilterForm",
};
</script>

<script lang="ts" setup>
import RadioList from "@/shared/components/base/RadioList/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import ManufacturerFilterGroup from "@/frontend/components/base/ManufacturerFilterGroup/index.vue";
import ProductionStatusFilterGroup from "@/frontend/components/base/ProductionStatusFilterGroup/index.vue";
import ClassificationFilterGroup from "@/frontend/components/base/ModelClassificationFilterGroup/index.vue";
import FocusFilterGroup from "@/frontend/components/base/ModelFocusFilterGroup/index.vue";
import SizeFilterGroup from "@/frontend/components/base/ModelSizeFilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { FleetVehicleQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

const { t } = useI18n();

const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<FleetVehicleQuery>({ updateCallback: setupForm });

function setupForm() {
  form.value = {
    modelNameCont: filters.value.modelNameCont,
    onSaleEq: filters.value.onSaleEq,
    loanerEq: filters.value.loanerEq,
    priceLteq: filters.value.priceLteq,
    priceGteq: filters.value.priceGteq,
    pledgePriceLteq: filters.value.pledgePriceLteq,
    pledgePriceGteq: filters.value.pledgePriceGteq,
    lengthLteq: filters.value.lengthLteq,
    lengthGteq: filters.value.lengthGteq,
    manufacturerIn: filters.value.manufacturerIn || [],
    classificationIn: filters.value.classificationIn || [],
    focusIn: filters.value.focusIn || [],
    sizeIn: filters.value.sizeIn || [],
    priceIn: filters.value.priceIn || [],
    pledgePriceIn: filters.value.pledgePriceIn || [],
    productionStatusIn: filters.value.productionStatusIn || [],
  };
}

const form = ref<FleetVehicleQuery>({});

const { booleanOptions, priceOptions, pledgePriceOptions } = useFilterOptions();
</script>

<template>
  <form @submit.prevent="filter(form)">
    <FormInput
      id="model-name"
      name="model-name"
      v-model="form.modelNameCont"
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

    <div class="row">
      <div class="col-6">
        <FormInput
          id="model-length-gteq"
          name="model-length-gteq"
          v-model="form.lengthGteq"
          type="number"
          translation-key="filters.vehicles.lengthGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          id="model-length-lteq"
          name="model-length-lteq"
          v-model="form.lengthLteq"
          type="number"
          translation-key="filters.vehicles.lengthLt"
          no-placeholder
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          id="model-pledge-price-gteq"
          name="model-pledge-price-gteq"
          v-model="form.pledgePriceGteq"
          type="number"
          translation-key="filters.vehicles.pledgePriceGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          id="model-pledge-price-lteq"
          name="model-pledge-price-lteq"
          v-model="form.pledgePriceLteq"
          type="number"
          translation-key="filters.vehicles.pledgePriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <FormInput
      id="model-price-gteq"
      name="model-price-gteq"
      v-model="form.priceGteq"
      type="number"
      translation-key="filters.vehicles.priceGt"
    />

    <FormInput
      id="model-price-lteq"
      name="model-price-lteq"
      v-model="form.priceLteq"
      type="number"
      translation-key="filters.vehicles.priceLt"
    />

    <RadioList
      v-model="form.onSaleEq"
      :label="t('labels.filters.models.onSale')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="sale"
    />

    <RadioList
      v-model="form.loanerEq"
      :label="t('labels.filters.vehicles.loaner')"
      :reset-label="t('labels.hide')"
      :options="[
        {
          label: 'Show',
          value: 'true',
        },
        {
          label: 'Only',
          value: 'only',
        },
      ]"
      name="loaner"
    />

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
