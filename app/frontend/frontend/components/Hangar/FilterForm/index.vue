<script lang="ts">
export default {
  name: "HangarFilterForm",
};
</script>

<script lang="ts" setup>
import RadioList from "@/shared/components/base/RadioList/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import ManufacturerFilterGroup from "@/frontend/components/base/ManufacturerFilterGroup/index.vue";
import ProductionStatusFilterGroup from "@/frontend/components/base/ProductionStatusFilterGroup/index.vue";
import ClassificationFilterGroup from "@/frontend/components/base/ModelClassificationFilterGroup/index.vue";
import FocusFilterGroup from "@/frontend/components/base/ModelFocusFilterGroup/index.vue";
import SizeFilterGroup from "@/frontend/components/base/ModelSizeFilterGroup/index.vue";
import WillItFitFilterGroup from "@/frontend/components/base/ModelWillItFitFilterGroup/index.vue";
import HangarGroupsFilterGroup from "@/frontend/components/base/HangarGroupsFilterGroup/index.vue";
import BoughtViaFilterGroup from "@/frontend/components/base/BoughtViaFilterGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { useHangarFilters } from "@/frontend/composables/useHangarFilters";
import { type HangarQuery } from "@/services/fyApi";
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
    loanerEq: filters.value.loanerEq,
    publicEq: filters.value.publicEq,
    boughtViaEq: filters.value.boughtViaEq,
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
    hangarGroupsIn: filters.value.hangarGroupsIn || [],
    hangarGroupsNotIn: filters.value.hangarGroupsNotIn || [],
    manufacturerIn: filters.value.manufacturerIn || [],
    classificationIn: filters.value.classificationIn || [],
    focusIn: filters.value.focusIn || [],
    productionStatusIn: filters.value.productionStatusIn || [],
    priceIn: filters.value.priceIn || [],
    pledgePriceIn: filters.value.pledgePriceIn || [],
    sizeIn: filters.value.sizeIn || [],
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useHangarFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<HangarQuery>(prefillFormValues());

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
    <Teleport v-if="!hideQuicksearch" to="#quicksearch">
      <FormInput
        v-model="form.searchCont"
        name="vehicle-search"
        translation-key="filters.vehicles.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>
    <FormInput
      v-model="form.nameCont"
      name="vehicle-name"
      translation-key="filters.vehicles.name"
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

    <WillItFitFilterGroup
      v-model="form.willItFit"
      name="will-it-fit"
      no-label
    />

    <HangarGroupsFilterGroup v-model="form.hangarGroupsIn" name="will-it-fit" />

    <BoughtViaFilterGroup v-model="form.boughtViaEq" name="bought-via" />

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.lengthGteq"
          name="vehicle-length-gteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.vehicles.lengthGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.lengthLteq"
          name="vehicle-length-lteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.vehicles.lengthLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.pledgePriceGteq"
          name="vehicle-pledge-price-gteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.vehicles.pledgePriceGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          v-model="form.pledgePriceLteq"
          name="vehicle-pledge-price-lteq"
          :type="InputTypesEnum.NUMBER"
          translation-key="filters.vehicles.pledgePriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <FormInput
      v-model="form.priceGteq"
      name="vehicle-price-gteq"
      :type="InputTypesEnum.NUMBER"
      translation-key="filters.vehicles.priceGt"
      :no-placeholder="true"
    />

    <FormInput
      v-model="form.priceLteq"
      name="vehicle-price-lteq"
      :type="InputTypesEnum.NUMBER"
      translation-key="filters.vehicles.priceLt"
      :no-placeholder="true"
    />

    <RadioList
      v-if="$route.name === 'hangar' || $route.name === 'hangar-wishlist'"
      v-model="form.loanerEq"
      :label="t('labels.filters.vehicles.loaner')"
      :reset-label="t('labels.hide')"
      :options="[
        {
          label: t('labels.show'),
          value: 'true',
        },
        {
          label: t('labels.only'),
          value: 'only',
        },
      ]"
      name="loaner"
    />

    <RadioList
      v-model="form.onSaleEq"
      :label="t('labels.filters.models.onSale')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="sale"
    />

    <RadioList
      v-if="$route.name === 'hangar' || $route.name === 'hangar-wishlist'"
      v-model="form.publicEq"
      :label="t('labels.filters.vehicles.public')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="public"
    />

    <br />

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
