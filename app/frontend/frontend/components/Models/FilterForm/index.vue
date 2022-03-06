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
      {{ $t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script>
import Filters from '@/frontend/mixins/Filters'
import RadioList from '@/frontend/core/components/Form/RadioList/index.vue'
import FilterGroup from '@/frontend/core/components/Form/FilterGroup/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import {
  booleanOptions,
  priceOptions,
  pledgePriceOptions,
} from '@/frontend/utils/FilterOptions'

export default {
  name: 'ModelFilterForm',

  components: {
    Btn,
    FilterGroup,
    FormInput,
    RadioList,
  },

  mixins: [Filters],

  data() {
    const query = this.$route.query.q || {}
    return {
      form: {
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        lengthGteq: query.lengthGteq,
        lengthLteq: query.lengthLteq,
        manufacturerIn: query.manufacturerIn || [],
        nameCont: query.nameCont,
        onSaleEq: query.onSaleEq,
        pledgePriceGteq: query.pledgePriceGteq,
        pledgePriceIn: query.pledgePriceIn || [],
        pledgePriceLteq: query.pledgePriceLteq,
        priceGteq: query.priceGteq,
        priceIn: query.priceIn || [],
        priceLteq: query.priceLteq,
        productionStatusIn: query.productionStatusIn || [],
        searchCont: query.searchCont,
        sizeIn: query.sizeIn || [],
        willItFit: query.willItFit,
      },
      loading: false,
    }
  },

  computed: {
    booleanOptions() {
      return booleanOptions
    },

    pledgePriceOptions() {
      return pledgePriceOptions
    },

    priceOptions() {
      return priceOptions
    },
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}

      this.form = {
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        lengthGteq: query.lengthGteq,
        lengthLteq: query.lengthLteq,
        manufacturerIn: query.manufacturerIn || [],
        nameCont: query.nameCont,
        onSaleEq: query.onSaleEq,
        pledgePriceGteq: query.pledgePriceGteq,
        pledgePriceIn: query.pledgePriceIn || [],
        pledgePriceLteq: query.pledgePriceLteq,
        priceGteq: query.priceGteq,
        priceIn: query.priceIn || [],
        priceLteq: query.priceLteq,
        productionStatusIn: query.productionStatusIn || [],
        searchCont: query.searchCont,
        sizeIn: query.sizeIn || [],
        willItFit: query.willItFit,
      }
    },
  },
}
</script>
