<template>
  <form @submit.prevent="filter">
    <div class="form-group">
      <label :for="idFor('user-vehicle-name')">
        {{ t('labels.filters.vehicles.name') }}
      </label>
      <input
        :id="idFor('user-vehicle-name')"
        v-model="form.nameCont"
        :placeholder="t('placeholders.filters.vehicles.name')"
        type="text"
        class="form-control"
      >
      <a
        v-if="form.nameCont"
        class="btn btn-clear"
        @click="clearName"
        v-html="'&times;'"/>
    </div>
    <div class="form-group">
      <label :for="idFor('model-name-or-description')">
        {{ t('labels.filters.models.nameOrDescription') }}
      </label>
      <input
        :id="idFor('model-name-or-description')"
        v-model="form.modelNameOrModelDescriptionCont"
        :placeholder="t('placeholders.filters.models.nameOrDescription')"
        type="text"
        class="form-control"
      >
      <a
        v-if="form.modelNameOrModelDescriptionCont"
        class="btn btn-clear"
        @click="clearModelNameOrDescription"
        v-html="'&times;'"/>
    </div>
    <FilterGroup
      v-model="form.modelManufacturerSlugIn"
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
      v-model="form.modelProductionStatusIn"
      :label="t('labels.filters.models.productionStatus')"
      :name="`${prefix}-production-status`"
      :fetch="fetchProductionStatus"
      multiple
    />
    <FilterGroup
      v-model="form.modelClassificationIn"
      :label="t('labels.filters.models.classification')"
      :name="`${prefix}-classification`"
      :fetch="fetchClassifications"
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.modelFocusIn"
      :label="t('labels.filters.models.focus')"
      :name="`${prefix}-focus`"
      :fetch="fetchFocus"
      searchable
      multiple
    />
    <FilterGroup
      v-model="form.modelSizeIn"
      :label="t('labels.filters.models.size')"
      :name="`${prefix}-size`"
      :fetch="fetchSize"
      multiple
    />
    <FilterGroup
      :options="pledgePriceOptions"
      v-model="form.modelPledgePriceIn"
      :label="t('labels.filters.models.pledgePrice')"
      :name="`${prefix}-pledge-price`"
      multiple
    />
    <FilterGroup
      :options="priceOptions"
      v-model="form.modelPriceIn"
      :label="t('labels.filters.models.price')"
      :name="`${prefix}-price`"
      multiple
    />
    <FilterGroup
      v-if="hangarGroupsOptions.length > 0"
      :options="hangarGroupsOptions.map(item => {
        return {
          value: item.slug,
          name: item.name,
        }
      })"
      v-model="form.hangarGroupsSlugIn"
      :label="t('labels.filters.vehicles.group')"
      :name="`${prefix}-hangar-group`"
      multiple
    />
    <RadioList
      v-if="$route.name === 'hangar'"
      :label="t('labels.filters.vehicles.purchased')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      v-model="form.purchasedEq"
      :name="`${prefix}-purchased`"
    />
    <RadioList
      :label="t('labels.filters.models.onSale')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      v-model="form.modelOnSaleEq"
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
    hangarGroupsOptions: {
      type: Array,
      default() {
        return []
      },
    },
    prefix: {
      type: String,
      default: 'filter',
    },
  },
  data() {
    const query = this.$route.query.q || {}
    return {
      form: {
        nameCont: query.nameCont,
        modelNameOrModelDescriptionCont: query.modelNameOrModelDescriptionCont,
        modelOnSaleEq: query.modelOnSaleEq,
        purchasedEq: query.purchasedEq,
        modelManufacturerSlugIn: query.modelManufacturerSlugIn || [],
        modelClassificationIn: query.modelClassificationIn || [],
        modelFocusIn: query.modelFocusIn || [],
        modelSizeIn: query.modelSizeIn || [],
        modelPriceIn: query.modelPriceIn || [],
        modelPledgePriceIn: query.modelPledgePriceIn || [],
        modelProductionStatusIn: query.modelProductionStatusIn || [],
        hangarGroupsSlugIn: query.hangarGroupsSlugIn || [],
      },
    }
  },
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameCont: query.nameCont,
        modelNameOrModelDescriptionCont: query.modelNameOrModelDescriptionCont,
        modelOnSaleEq: query.modelOnSaleEq,
        purchasedEq: query.purchasedEq,
        modelManufacturerSlugIn: query.modelManufacturerSlugIn || [],
        modelClassificationIn: query.modelClassificationIn || [],
        modelFocusIn: query.modelFocusIn || [],
        modelSizeIn: query.modelSizeIn || [],
        modelPriceIn: query.modelPriceIn || [],
        modelPledgePriceIn: query.modelPledgePriceIn || [],
        modelProductionStatusIn: query.modelProductionStatusIn || [],
        hangarGroupsSlugIn: query.hangarGroupsSlugIn || [],
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
    clearName() {
      this.form.nameCont = null
    },
    clearModelNameOrDescription() {
      this.form.modelNameOrModelDescriptionCont = null
    },
  },
}
</script>
