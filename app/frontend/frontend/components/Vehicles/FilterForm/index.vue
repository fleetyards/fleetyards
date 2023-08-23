<template>
  <form @submit.prevent="filter">
    <FormInput
      id="vehicle-name"
      v-model="form.nameCont"
      translation-key="filters.vehicles.name"
      :no-label="true"
      :clearable="true"
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

    <FilterGroup
      v-if="hangarGroupsOptions.length > 0"
      v-model="form.hangarGroupsIn"
      :options="
        hangarGroupsOptions.map((item) => {
          return {
            value: item.slug,
            name: item.name,
          };
        })
      "
      :label="t('labels.filters.vehicles.group')"
      name="hangar-group"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.boughtViaEq"
      fetch-path="vehicles/filters/bought-via"
      :label="t('labels.filters.vehicles.boughtVia')"
      translation-key="filters.vehicles.boughtVia"
      name="boughtVia"
      :no-label="true"
    />

    <div class="row">
      <div class="col-6">
        <FormInput
          id="vehicle-length-gteq"
          v-model="form.lengthGteq"
          type="number"
          translation-key="filters.vehicles.lengthGt"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          id="vehicle-length-lteq"
          v-model="form.lengthLteq"
          type="number"
          translation-key="filters.vehicles.lengthLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <FormInput
          id="vehicle-pledge-price-gteq"
          v-model="form.pledgePriceGteq"
          type="number"
          translation-key="filters.vehicles.pledgePriceGt"
          :no-placeholder="true"
        />
      </div>

      <div class="col-6">
        <FormInput
          id="vehicle-pledge-price-lteq"
          v-model="form.pledgePriceLteq"
          type="number"
          translation-key="filters.vehicles.pledgePriceLt"
          :no-placeholder="true"
        />
      </div>
    </div>

    <FormInput
      id="vehicle-price-gteq"
      v-model="form.priceGteq"
      type="number"
      translation-key="filters.vehicles.priceGt"
      :no-placeholder="true"
    />

    <FormInput
      id="vehicle-price-lteq"
      v-model="form.priceLteq"
      type="number"
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
          name: t('labels.show'),
          value: 'true',
        },
        {
          name: t('labels.only'),
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

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import RadioList from "@/frontend/core/components/Form/RadioList/index.vue";
import FilterGroup from "@/frontend/core/components/Form/FilterGroup/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { useFilters } from "@/shared/composables/useFilters";

const { t } = useI18n();

const { booleanOptions, priceOptions, pledgePriceOptions } =
  useFilterOptions(t);

const { filter, isFilterSelected, resetFilter } = useFilters();

type Props = {
  hangarGroupsOptions?: Array<{ slug: string; name: string }>;
};

withDefaults(defineProps<Props>(), {
  hangarGroupsOptions: () => [],
});

type VehiclesForm = {
  nameCont: string;
  nameEq: string;
  nameIn: string[];
  manufacturerIn: string[];
  classificationIn: string[];
  focusIn: string[];
  sizeIn: string[];
  priceIn: string[];
  pledgePriceIn: string[];
  productionStatusIn: string[];
  hangarGroupsIn: string[];
  hangarGroupsNotIn: string[];
  onSaleEq: string;
  wantedEq: string;
  loanerEq: string;
  publicEq: string;
  priceLteq: string;
  priceGteq: string;
  pledgePriceLteq: string;
  pledgePriceGteq: string;
  lengthLteq: string;
  lengthGteq: string;
  boughtViaEq: string;
};

const form = ref<Partial<VehiclesForm>>({});

const route = useRoute();

const query = computed(() => {
  return (route.query.q || {}) as Partial<VehiclesForm>;
});

const setupForm = () => {
  form.value = {
    nameCont: query.value.nameCont,
    onSaleEq: query.value.onSaleEq,
    wantedEq: query.value.wantedEq,
    loanerEq: query.value.loanerEq,
    publicEq: query.value.publicEq,
    priceLteq: query.value.priceLteq,
    priceGteq: query.value.priceGteq,
    pledgePriceLteq: query.value.pledgePriceLteq,
    pledgePriceGteq: query.value.pledgePriceGteq,
    lengthLteq: query.value.lengthLteq,
    lengthGteq: query.value.lengthGteq,
    boughtViaEq: query.value.boughtViaEq,
    manufacturerIn: query.value.manufacturerIn || [],
    classificationIn: query.value.classificationIn || [],
    focusIn: query.value.focusIn || [],
    sizeIn: query.value.sizeIn || [],
    priceIn: query.value.priceIn || [],
    pledgePriceIn: query.value.pledgePriceIn || [],
    productionStatusIn: query.value.productionStatusIn || [],
    hangarGroupsIn: query.value.hangarGroupsIn || [],
    hangarGroupsNotIn: query.value.hangarGroupsNotIn || [],
  };
};

onMounted(() => {
  setupForm();
});

watch(
  () => route.query,
  () => {
    setupForm();
  },
  { deep: true },
);
</script>

<script lang="ts">
export default {
  name: "VehiclesFilterForm",
};
</script>
