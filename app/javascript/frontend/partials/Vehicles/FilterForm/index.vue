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
      name="pledge-price"
      multiple
    />
    <FilterGroup
      :options="priceOptions"
      v-model="form.priceIn"
      :label="t('labels.filters.models.price')"
      name="price"
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
      v-model="form.hangarGroupsIn"
      :label="t('labels.filters.vehicles.group')"
      name="hangar-group"
      multiple
    />
    <RadioList
      v-if="$route.name === 'hangar'"
      :label="t('labels.filters.vehicles.purchased')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      v-model="form.purchasedEq"
      name="purchased"
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
  props: {
    hangarGroupsOptions: {
      type: Array,
      default() {
        return []
      },
    },
  },
  data() {
    const query = this.$route.query.q || {}
    return {
      form: {
        nameCont: query.nameCont,
        modelNameOrModelDescriptionCont: query.modelNameOrModelDescriptionCont,
        onSaleEq: query.onSaleEq,
        purchasedEq: query.purchasedEq,
        manufacturerIn: query.manufacturerIn || [],
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        sizeIn: query.sizeIn || [],
        priceIn: query.priceIn || [],
        pledgePriceIn: query.pledgePriceIn || [],
        productionStatusIn: query.productionStatusIn || [],
        hangarGroupsIn: query.hangarGroupsIn || [],
      },
    }
  },
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameCont: query.nameCont,
        modelNameOrModelDescriptionCont: query.modelNameOrModelDescriptionCont,
        onSaleEq: query.onSaleEq,
        purchasedEq: query.purchasedEq,
        manufacturerIn: query.manufacturerIn || [],
        classificationIn: query.classificationIn || [],
        focusIn: query.focusIn || [],
        sizeIn: query.sizeIn || [],
        priceIn: query.priceIn || [],
        pledgePriceIn: query.pledgePriceIn || [],
        productionStatusIn: query.productionStatusIn || [],
        hangarGroupsIn: query.hangarGroupsIn || [],
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
