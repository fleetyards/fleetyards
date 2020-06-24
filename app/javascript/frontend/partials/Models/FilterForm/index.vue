<template>
  <form @submit.prevent="filter">
    <FormInput
      id="model-name"
      v-model="form.nameCont"
      translation-key="filters.models.name"
      no-label
      clearable
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
          no-placeholder
        />
      </div>

      <div class="col-6">
        <FormInput
          id="model-length-lteq"
          v-model="form.lengthLteq"
          type="number"
          translation-key="filters.models.lengthLt"
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
          translation-key="filters.models.pledgePriceGt"
          no-placeholder
        />
      </div>
      <div class="col-6">
        <FormInput
          id="model-pledge-price-lteq"
          v-model="form.pledgePriceLteq"
          type="number"
          translation-key="filters.models.pledgePriceLt"
          no-placeholder
        />
      </div>
    </div>

    <FormInput
      id="model-price-gteq"
      v-model="form.priceGteq"
      type="number"
      translation-key="filters.models.priceGt"
      no-placeholder
    />

    <FormInput
      id="model-price-lteq"
      v-model="form.priceLteq"
      type="number"
      translation-key="filters.models.priceLt"
      no-placeholder
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
import Filters from 'frontend/mixins/Filters'
import RadioList from 'frontend/components/Form/RadioList'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import Btn from 'frontend/components/Btn'
import FormInput from 'frontend/components/Form/FormInput'
import {
  booleanOptions,
  priceOptions,
  pledgePriceOptions,
} from 'frontend/utils/Filters'

export default {
  components: {
    RadioList,
    FilterGroup,
    Btn,
    FormInput,
  },

  mixins: [Filters],

  data() {
    const query = this.$route.query.q || {}
    return {
      loading: false,
      form: {
        searchCont: query.searchCont,
        nameCont: query.nameCont,
        onSaleEq: query.onSaleEq,
        priceLteq: query.priceLteq,
        priceGteq: query.priceGteq,
        pledgePriceLteq: query.pledgePriceLteq,
        pledgePriceGteq: query.pledgePriceGteq,
        lengthLteq: query.lengthLteq,
        lengthGteq: query.lengthGteq,
        willItFit: query.willItFit,
        manufacturerIn: query.manufacturerIn || [],
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        productionStatusIn: query.productionStatusIn || [],
        priceIn: query.priceIn || [],
        pledgePriceIn: query.pledgePriceIn || [],
        sizeIn: query.sizeIn || [],
      },
    }
  },

  computed: {
    booleanOptions() {
      return booleanOptions
    },

    priceOptions() {
      return priceOptions
    },

    pledgePriceOptions() {
      return pledgePriceOptions
    },
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}

      this.form = {
        searchCont: query.searchCont,
        nameCont: query.nameCont,
        onSaleEq: query.onSaleEq,
        priceLteq: query.priceLteq,
        priceGteq: query.priceGteq,
        pledgePriceLteq: query.pledgePriceLteq,
        pledgePriceGteq: query.pledgePriceGteq,
        lengthLteq: query.lengthLteq,
        lengthGteq: query.lengthGteq,
        willItFit: query.willItFit,
        manufacturerIn: query.manufacturerIn || [],
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        productionStatusIn: query.productionStatusIn || [],
        priceIn: query.priceIn || [],
        pledgePriceIn: query.pledgePriceIn || [],
        sizeIn: query.sizeIn || [],
      }
    },
  },
}
</script>
