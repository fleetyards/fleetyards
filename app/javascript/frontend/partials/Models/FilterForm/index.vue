<template>
  <form @submit.prevent="filter">
    <div class="form-group">
      <label :for="idFor('model-name-or-description')">
        {{ t('labels.filters.models.nameOrDescription') }}
      </label>
      <input
        :id="idFor('model-name-or-description')"
        v-model="form.nameOrDescriptionCont"
        :placeholder="t('placeholders.filters.models.nameOrDescription')"
        type="text"
        class="form-control"
      >
      <a
        v-if="form.nameOrDescriptionCont"
        class="btn btn-clear"
        @click="clearNameOrDescription"
        v-html="'&times;'"
      />
    </div>
    <FilterGroup
      v-model="form.manufacturerIn"
      :label="t('labels.filters.models.manufacturer')"
      :fetch="fetchManufacturers"
      name="manufacturer"
      value-attr="slug"
      icon-attr="logo"
      paginated
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.productionStatusIn"
      :label="t('labels.filters.models.productionStatus')"
      :fetch="fetchProductionStatus"
      name="production-status"
      multiple
    />
    <FilterGroup
      v-model="form.classificationIn"
      :label="t('labels.filters.models.classification')"
      :fetch="fetchClassifications"
      name="classification"
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.focusIn"
      :label="t('labels.filters.models.focus')"
      :fetch="fetchFocus"
      name="focus"
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.sizeIn"
      :label="t('labels.filters.models.size')"
      :fetch="fetchSize"
      name="size"
      multiple
    />
    <FilterGroup
      :options="pledgePriceOptions"
      v-model="form.pledgePriceIn"
      :label="t('labels.filters.models.pledgePrice')"
      name="pldege-price"
      multiple
    />
    <FilterGroup
      :options="priceOptions"
      v-model="form.priceIn"
      :label="t('labels.filters.models.price')"
      name="price"
      multiple
    />
    <RadioList
      :label="t('labels.filters.models.onSale')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      v-model="form.onSaleEq"
      name="sale"
    />
    <Btn
      :disabled="!isFilterSelected"
      block
      @click.native="reset"
    >
      <i class="fal fa-times" />
      {{ t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Filters from 'frontend/mixins/Filters'
import RadioList from 'frontend/components/Form/RadioList'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    RadioList,
    FilterGroup,
    Btn,
  },
  mixins: [I18n, Filters],
  data() {
    const query = this.$route.query.q || {}
    return {
      loading: false,
      form: {
        nameOrDescriptionCont: query.nameOrDescriptionCont,
        onSaleEq: query.onSaleEq,
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
        nameOrDescriptionCont: query.nameOrDescriptionCont,
        onSaleEq: query.onSaleEq,
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
  methods: {
    clearNameOrDescription() {
      this.form.nameOrDescriptionCont = null
    },
  },
}
</script>
