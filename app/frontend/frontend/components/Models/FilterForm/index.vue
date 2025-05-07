<script lang="ts">
export default {
  name: "ModelsFilterForm",
};
</script>

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
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { type ModelQuery } from "@/services/fyApi";
import { useModelFilters } from "@/frontend/composables/useModelFilters";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";

type Props = {
  hideQuicksearch?: boolean;
};

withDefaults(defineProps<Props>(), {
  hideQuicksearch: false,
});

const { t } = useI18n();

const prefillFormValues = () => {
  return {
    searchCont: filters.value.searchCont,
    nameCont: filters.value.nameCont,
    onSaleEq: filters.value.onSaleEq,
    priceLteq: filters.value.priceLteq,
    priceGteq: filters.value.priceGteq,
    pledgePriceLteq: filters.value.pledgePriceLteq,
    pledgePriceGteq: filters.value.pledgePriceGteq,
    lengthLteq: filters.value.lengthLteq,
    lengthGteq: filters.value.lengthGteq,
    beamLteq: filters.value.beamLteq,
    beamGteq: filters.value.beamGteq,
    heightLteq: filters.value.heightLteq,
    heightGteq: filters.value.heightGteq,
    willItFit: filters.value.willItFit,
    manufacturerIn: filters.value.manufacturerIn || [],
    classificationIn: filters.value.classificationIn || [],
    focusIn: filters.value.focusIn || [],
    productionStatusIn: filters.value.productionStatusIn || [],
    priceIn: filters.value.priceIn || [],
    pledgePriceIn: filters.value.pledgePriceIn || [],
    sizeIn: filters.value.sizeIn || [],
    withCargo: filters.value.withCargo,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useModelFilters(setupForm);

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

const { booleanOptions, priceOptions, pledgePriceOptions } = useFilterOptions();
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport v-if="!hideQuicksearch" to="#header-left">
      <FormInput
        v-model="form.searchCont"
        name="search"
        translation-key="filters.models.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>
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
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.models.lengthGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          v-model="form.lengthLteq"
          name="model-length-lteq"
          :type="InputTypesEnum.NUMBER"
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
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.models.beamGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          v-model="form.beamLteq"
          name="model-beam-lteq"
          :type="InputTypesEnum.NUMBER"
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
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.models.heightGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          v-model="form.heightLteq"
          name="model-height-lteq"
          :type="InputTypesEnum.NUMBER"
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
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.models.pledgePriceGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.pledgePriceLteq"
          name="model-pledge-price-lteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.models.pledgePriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <FormInput
      v-model="form.priceGteq"
      name="model-price-gteq"
      :type="InputTypesEnum.NUMBER"
      translation-key="filters.models.priceGt"
      :no-placeholder="true"
    />

    <FormInput
      v-model="form.priceLteq"
      name="model-price-lteq"
      :type="InputTypesEnum.NUMBER"
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

    <FormCheckbox
      v-model="form.withCargo"
      :label="t('labels.filters.models.withCargo')"
      name="withCargo"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
