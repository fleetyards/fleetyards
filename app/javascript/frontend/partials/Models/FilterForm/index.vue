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
      v-model="form.manufacturerSlugIn"
      :label="t('labels.filters.models.manufacturer')"
      :name="`${prefix}-manufacturer`"
      :fetch="fetchManufacturers"
      value-attr="slug"
      icon-attr="logo"
      paginated
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.productionStatusIn"
      :label="t('labels.filters.models.productionStatus')"
      :name="`${prefix}-production-status`"
      :fetch="fetchProductionStatus"
      multiple
    />
    <FilterGroup
      v-model="form.classificationIn"
      :label="t('labels.filters.models.classification')"
      :name="`${prefix}-classification`"
      :fetch="fetchClassifications"
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.focusIn"
      :label="t('labels.filters.models.focus')"
      :name="`${prefix}-focus`"
      :fetch="fetchFocus"
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.sizeIn"
      :label="t('labels.filters.models.size')"
      :name="`${prefix}-size`"
      :fetch="fetchSize"
      multiple
    />
    <FilterGroup
      :options="priceOptions"
      v-model="form.priceIn"
      :label="t('labels.filters.models.price')"
      :name="`${prefix}-price`"
      multiple
    />
    <RadioList
      :label="t('labels.filters.models.onSale')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      v-model="form.onSaleEq"
      :name="`${prefix}-sale`"
    />
    <Btn
      v-if="!hideButtons"
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
  props: {
    hideButtons: {
      type: Boolean,
      default: false,
    },
    prefix: {
      type: String,
      default: 'filter',
    },
  },
  data() {
    const query = this.$route.query.q || {}
    return {
      loading: false,
      form: {
        nameOrDescriptionCont: query.nameOrDescriptionCont,
        onSaleEq: query.onSaleEq,
        manufacturerSlugIn: query.manufacturerSlugIn || [],
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        productionStatusIn: query.productionStatusIn || [],
        priceIn: query.priceIn || [],
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
        manufacturerSlugIn: query.manufacturerSlugIn || [],
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        productionStatusIn: query.productionStatusIn || [],
        priceIn: query.priceIn || [],
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
    clearOnSale() {
      this.form.onSaleEq = null
    },
  },
}
</script>
