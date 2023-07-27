<template>
  <form @submit.prevent="filter">
    <FormInput
      id="model-name"
      v-model="form.nameCont"
      translation-key="filters.models.name"
      :no-label="true"
      :clearable="true"
    />

    <FilterGroup
      v-model="form.manufacturerIn"
      :label="$t('labels.filters.models.manufacturer')"
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
      :label="$t('labels.filters.models.productionStatus')"
      fetch-path="models/production-states"
      name="production-status"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.classificationIn"
      :label="$t('labels.filters.models.classification')"
      fetch-path="models/classifications"
      name="classification"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.focusIn"
      :label="$t('labels.filters.models.focus')"
      fetch-path="models/focus"
      name="focus"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.sizeIn"
      :label="$t('labels.filters.models.size')"
      fetch-path="models/sizes"
      name="size"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.pledgePriceIn"
      :options="pledgePriceOptions"
      :label="$t('labels.filters.models.pledgePrice')"
      name="pldege-price"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.priceIn"
      :options="priceOptions"
      :label="$t('labels.filters.models.price')"
      name="price"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.willItFit"
      :label="$t('labels.filters.models.willItFit')"
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
      :label="$t('labels.filters.models.onSale')"
      :reset-label="$t('labels.all')"
      :options="booleanOptions"
      name="sale"
    />

    <Btn
      :disabled="!isFilterSelected"
      :block="true"
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ $t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import RadioList from "@/shared/components/Form/RadioList/index.vue";
import FilterGroup from "@/shared/components/Form/FilterGroup/index.vue";
import Btn from "@/shared/components/BaseBtn/index.vue";
import FormInput from "@/shared/components/Form/FormInput/index.vue";
import {
  booleanOptions,
  priceOptions,
  pledgePriceOptions,
} from "@/shared/utils/FilterOptions";

//   data() {
//     const query = this.$route.query.q || {};
//     return {
//       loading: false,
//       form: {
//         searchCont: query.searchCont,
//         nameCont: query.nameCont,
//         onSaleEq: query.onSaleEq,
//         priceLteq: query.priceLteq,
//         priceGteq: query.priceGteq,
//         pledgePriceLteq: query.pledgePriceLteq,
//         pledgePriceGteq: query.pledgePriceGteq,
//         lengthLteq: query.lengthLteq,
//         lengthGteq: query.lengthGteq,
//         beamLteq: query.beamLteq,
//         beamGteq: query.beamGteq,
//         heightLteq: query.heightLteq,
//         heightGteq: query.heightGteq,
//         willItFit: query.willItFit,
//         manufacturerIn: query.manufacturerIn || [],
//         classificationIn: query.classificationIn || [],
//         focusIn: query.focusIn || [],
//         productionStatusIn: query.productionStatusIn || [],
//         priceIn: query.priceIn || [],
//         pledgePriceIn: query.pledgePriceIn || [],
//         sizeIn: query.sizeIn || [],
//       },
//     };
//   },

//   computed: {
//     booleanOptions() {
//       return booleanOptions;
//     },

//     priceOptions() {
//       return priceOptions;
//     },

//     pledgePriceOptions() {
//       return pledgePriceOptions;
//     },
//   },

//   watch: {
//     $route() {
//       const query = this.$route.query.q || {};

//       this.form = {
//         searchCont: query.searchCont,
//         nameCont: query.nameCont,
//         onSaleEq: query.onSaleEq,
//         priceLteq: query.priceLteq,
//         priceGteq: query.priceGteq,
//         pledgePriceLteq: query.pledgePriceLteq,
//         pledgePriceGteq: query.pledgePriceGteq,
//         lengthLteq: query.lengthLteq,
//         lengthGteq: query.lengthGteq,
//         beamLteq: query.beamLteq,
//         beamGteq: query.beamGteq,
//         heightLteq: query.heightLteq,
//         heightGteq: query.heightGteq,
//         willItFit: query.willItFit,
//         manufacturerIn: query.manufacturerIn || [],
//         classificationIn: query.classificationIn || [],
//         focusIn: query.focusIn || [],
//         productionStatusIn: query.productionStatusIn || [],
//         priceIn: query.priceIn || [],
//         pledgePriceIn: query.pledgePriceIn || [],
//         sizeIn: query.sizeIn || [],
//       };
//     },
//   },
// };
</script>

<script lang="ts">
export default {
  name: "ModelsFilterForm",
};
</script>
