<script lang="ts">
export default {
  name: "FleetFilterForm",
};
</script>

<script lang="ts" setup>
import RadioList from "@/shared/components/base/RadioList/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import ManufacturerSelect from "@/frontend/components/base/ManufacturerSelect/index.vue";
import ProductionStatusSelect from "@/frontend/components/base/ProductionStatusSelect/index.vue";
import ClassificationSelect from "@/frontend/components/base/ModelClassificationSelect/index.vue";
import FocusSelect from "@/frontend/components/base/ModelFocusSelect/index.vue";
import SizeSelect from "@/frontend/components/base/ModelSizeSelect/index.vue";
import FleetMemberSelect from "@/frontend/components/base/FleetMemberSelect/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";

const { t } = useI18n();
const { booleanOptions, priceOptions, pledgePriceOptions } = useFilterOptions();

const route = useRoute();

type FleetsFilterForm = {
  searchCont?: string;
  modelNameCont?: string;
  onSaleEq?: string;
  loanerEq?: string;
  priceLteq?: string;
  priceGteq?: string;
  pledgePriceLteq?: string;
  pledgePriceGteq?: string;
  lengthLteq?: string;
  lengthGteq?: string;
  manufacturerIn?: string[];
  classificationIn?: string[];
  focusIn?: string[];
  sizeIn?: string[];
  priceIn?: string[];
  pledgePriceIn?: string[];
  productionStatusIn?: string[];
  memberIn?: string[];
};

const prefillFormValues = () => {
  return {
    searchCont: filters.value.searchCont,
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
    memberIn: filters.value.memberIn || [],
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { resetFilter, isFilterSelected, filter, filters } =
  useFilters<FleetsFilterForm>({
    updateCallback: setupForm,
  });

const form = ref<FleetsFilterForm>(prefillFormValues());

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);

const submit = () => {
  filter(form.value);
};
</script>

<template>
  <form @submit.prevent="submit">
    <Teleport to="#header-left">
      <FormInput
        name="search"
        :size="InputSizesEnum.MEDIUM"
        v-model="form.searchCont"
        translation-key="filters.models.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <FormInput
      id="model-name"
      name="model-name"
      v-model="form.modelNameCont"
      translation-key="filters.models.name"
      :no-label="true"
      :clearable="true"
    />

    <FleetMemberSelect
      v-model="form.memberIn"
      :fleet-slug="route.params.slug as string"
      name="member"
    />

    <ManufacturerSelect v-model="form.manufacturerIn" name="manufacturer" />

    <ProductionStatusSelect
      v-model="form.productionStatusIn"
      name="production-status"
    />

    <ClassificationSelect
      v-model="form.classificationIn"
      name="classification"
    />

    <FocusSelect v-model="form.focusIn" name="focus" />

    <SizeSelect v-model="form.sizeIn" name="size" />

    <BaseSelect
      v-model="form.pledgePriceIn"
      :options="pledgePriceOptions"
      :label="t('labels.filters.models.pledgePrice')"
      name="pledge-price"
      :multiple="true"
      :no-label="true"
    />

    <BaseSelect
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
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
