<template>
  <form @submit.prevent="filter">
    <FormInput
      id="model-name"
      v-model="form.nameCont"
      translation-key="filters.models.name"
      :no-label="true"
      :clearable="true"
    />

    // TODO: migrate to new FilterGroup props
    <FilterGroup
      v-model="form.manufacturerIn"
      :label="t('labels.filters.models.manufacturer')"
      fetch-path="manufacturers/with-models"
      name="manufacturer"
      value-attr="slug"
      icon-attr="logo"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.productionStatusIn"
      :label="t('labels.filters.models.productionStatus')"
      fetch-path="models/production-states"
      name="production-status"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.classificationIn"
      :label="t('labels.filters.models.classification')"
      fetch-path="models/classifications"
      name="classification"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.focusIn"
      :label="t('labels.filters.models.focus')"
      fetch-path="models/focus"
      name="focus"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.sizeIn"
      :label="t('labels.filters.models.size')"
      fetch-path="models/sizes"
      name="size"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.pledgePriceIn"
      :options="pledgePriceOptions"
      :label="t('labels.filters.models.pledgePrice')"
      name="pldege-price"
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

    <FilterGroup
      v-model="form.willItFit"
      :label="t('labels.filters.models.willItFit')"
      fetch-path="models/with-docks"
      value-attr="slug"
      name="will-it-fit"
      :searchable="true"
    />

    <div class="row">
      <div class="col-6">
        <FormInput
          id="model-length-gteq"
          v-model="form.lengthGteq"
          type="number"
          translation-key="filters.models.lengthGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          id="model-length-lteq"
          v-model="form.lengthLteq"
          type="number"
          translation-key="filters.models.lengthLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          id="model-beam-gteq"
          v-model="form.beamGteq"
          type="number"
          translation-key="filters.models.beamGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          id="model-beam-lteq"
          v-model="form.beamLteq"
          type="number"
          translation-key="filters.models.beamLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          id="model-height-gteq"
          v-model="form.heightGteq"
          type="number"
          translation-key="filters.models.heightGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          id="model-height-lteq"
          v-model="form.heightLteq"
          type="number"
          translation-key="filters.models.heightLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          id="model-pledge-price-gteq"
          v-model="form.pledgePriceGteq"
          type="number"
          translation-key="filters.models.pledgePriceGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          id="model-pledge-price-lteq"
          v-model="form.pledgePriceLteq"
          type="number"
          translation-key="filters.models.pledgePriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <FormInput
      id="model-price-gteq"
      v-model="form.priceGteq"
      type="number"
      translation-key="filters.models.priceGt"
      :no-placeholder="true"
    />

    <FormInput
      id="model-price-lteq"
      v-model="form.priceLteq"
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
import RadioList from "@/shared/components/Form/RadioList/index.vue";
import FilterGroup from "@/shared/components/Form/FilterGroup/index.vue";
import FormInput from "@/shared/components/Form/FormInput/index.vue";
import Btn from "@/shared/components/BaseBtn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { ModelQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

const { t } = useI18n();

const setupForm = () => {
  form.value = {
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

const { filter, resetFilter, isFilterSelected, routeQuery } =
  useFilters<ModelQuery>(setupForm);

const form = ref<ModelQuery>({});

const { booleanOptions, priceOptions, pledgePriceOptions } =
  useFilterOptions(t);
</script>

<script lang="ts">
export default {
  name: "ModelsFilterForm",
};
</script>
