<template>
  <form @submit.prevent="submit">
    <FormInput
      id="model-name"
      v-model="form.modelNameCont"
      translation-key="filters.models.name"
      :no-label="true"
      :clearable="true"
    />

    <FilterGroup
      v-model="form.memberIn"
      :label="t('labels.filters.fleets.member')"
      :fetch-path="`fleets/${$route.params.slug}/members`"
      name="member"
      value-attr="username"
      label-attr="username"
      icon-attr="avatar"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

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
          v-model="form.lengthGteq"
          type="number"
          translation-key="filters.vehicles.lengthGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          id="model-length-lteq"
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
          v-model="form.pledgePriceGteq"
          type="number"
          translation-key="filters.vehicles.pledgePriceGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          id="model-pledge-price-lteq"
          v-model="form.pledgePriceLteq"
          type="number"
          translation-key="filters.vehicles.pledgePriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <FormInput
      id="model-price-gteq"
      v-model="form.priceGteq"
      type="number"
      translation-key="filters.vehicles.priceGt"
    />

    <FormInput
      id="model-price-lteq"
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
          name: 'Show',
          value: 'true',
        },
        {
          name: 'Only',
          value: 'only',
        },
      ]"
      name="loaner"
    />

    <Btn
      :disabled="!isFilterSelected"
      :block="true"
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import RadioList from "@/frontend/core/components/Form/RadioList/index.vue";
import FilterGroup from "@/frontend/core/components/Form/FilterGroup/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import {
  booleanOptions as booleanFilterOptions,
  priceOptions as priceFilterOptions,
  pledgePriceOptions as pledgePriceFilterOptions,
} from "@/frontend/utils/FilterOptions";
import { useI18n } from "@/frontend/composables/useI18n";
import { useFilters } from "@/frontend/composables/useFilters";

type FleetsFilterForm = {
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

const query = computed(() => (route.query.q || {}) as FleetsFilterForm);

const form = ref<FleetsFilterForm>({});

const booleanOptions = booleanFilterOptions;
const priceOptions = priceFilterOptions;
const pledgePriceOptions = pledgePriceFilterOptions;

const { t } = useI18n();

const route = useRoute();

const { resetFilter, isFilterSelected, filter } = useFilters();

watch(
  () => route.query,
  () => {
    setupForm();
  },
  { deep: true }
);

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true }
);

onMounted(() => {
  setupForm();
});

const setupForm = () => {
  form.value = {
    modelNameCont: query.value.modelNameCont,
    onSaleEq: query.value.onSaleEq,
    loanerEq: query.value.loanerEq,
    priceLteq: query.value.priceLteq,
    priceGteq: query.value.priceGteq,
    pledgePriceLteq: query.value.pledgePriceLteq,
    pledgePriceGteq: query.value.pledgePriceGteq,
    lengthLteq: query.value.lengthLteq,
    lengthGteq: query.value.lengthGteq,
    manufacturerIn: query.value.manufacturerIn || [],
    classificationIn: query.value.classificationIn || [],
    focusIn: query.value.focusIn || [],
    sizeIn: query.value.sizeIn || [],
    priceIn: query.value.priceIn || [],
    pledgePriceIn: query.value.pledgePriceIn || [],
    productionStatusIn: query.value.productionStatusIn || [],
    memberIn: query.value.memberIn || [],
  };
};

const submit = () => {
  filter(form.value);
};
</script>

<script lang="ts">
export default {
  name: "FleetFilterForm",
};
</script>
