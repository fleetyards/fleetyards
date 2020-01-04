<template>
  <form @submit.prevent="filter">
    <FormInput
      v-model="form.nameCont"
      :placeholder="$t('placeholders.filters.models.name')"
      :aria-label="$t('placeholders.filters.models.name')"
    />

    <FilterGroup
      v-model="form.manufacturerIn"
      :label="$t('labels.filters.models.manufacturer')"
      fetch-path="manufacturers/with-models"
      name="manufacturer"
      value-attr="slug"
      icon-attr="logo"
      paginated
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.productionStatusIn"
      :label="$t('labels.filters.models.productionStatus')"
      fetch-path="models/production-states"
      name="production-status"
      multiple
    />

    <FilterGroup
      v-model="form.classificationIn"
      :label="$t('labels.filters.models.classification')"
      fetch-path="models/classifications"
      name="classification"
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.focusIn"
      :label="$t('labels.filters.models.focus')"
      fetch-path="models/focus"
      name="focus"
      searchable
      multiple
    />

    <FilterGroup
      v-model="form.sizeIn"
      :label="$t('labels.filters.models.size')"
      fetch-path="models/sizes"
      name="size"
      multiple
    />

    <FilterGroup
      v-model="form.pledgePriceIn"
      :options="pledgePriceOptions"
      :label="$t('labels.filters.models.pledgePrice')"
      name="pldege-price"
      multiple
    />

    <FilterGroup
      v-model="form.priceIn"
      :options="priceOptions"
      :label="$t('labels.filters.models.price')"
      name="price"
      multiple
    />

    <FilterGroup
      v-model="form.willItFit"
      :label="$t('labels.filters.models.willItFit')"
      fetch-path="models/with-docks"
      value-attr="slug"
      name="will-it-fit"
      searchable
    />

    <div class="row">
      <div class="col-xs-6">
        <FormInput
          v-model="form.lengthGteq"
          type="number"
          :label="$t('labels.filters.models.lengthGt')"
          :aria-label="$t('labels.filters.models.lengthGt')"
        />
      </div>

      <div class="col-xs-6">
        <FormInput
          v-model="form.lengthLteq"
          type="number"
          :label="$t('labels.filters.models.lengthLt')"
          :aria-label="$t('labels.filters.models.lengthLt')"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-xs-6">
        <FormInput
          v-model="form.pledgePriceGteq"
          type="number"
          :label="$t('labels.filters.models.pledgePriceGt')"
          :aria-label="$t('labels.filters.models.pledgePriceGt')"
        />
      </div>
      <div class="col-xs-6">
        <FormInput
          v-model="form.pledgePriceLteq"
          type="number"
          :label="$t('labels.filters.models.pledgePriceLt')"
          :aria-label="$t('labels.filters.models.pledgePriceLt')"
        />
      </div>
    </div>

    <FormInput
      v-model="form.priceGteq"
      type="number"
      :label="$t('labels.filters.models.priceGt')"
      :aria-label="$t('labels.filters.models.priceGt')"
    />

    <FormInput
      v-model="form.priceLteq"
      type="number"
      :label="$t('labels.filters.models.priceLt')"
      :aria-label="$t('labels.filters.models.priceLt')"
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
      block
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

export default {
  components: {
    RadioList,
    FilterGroup,
    Btn,
    FormInput,
  },

  mixins: [
    Filters,
  ],

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

      this.$store.commit('setFilters', { [this.$route.name]: this.form })
    },

    form: {
      handler() {
        this.filter()
      },
      deep: true,
    },
  },
}
</script>
