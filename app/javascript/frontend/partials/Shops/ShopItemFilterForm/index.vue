<template>
  <form @submit.prevent="filter">
    <div class="form-group">
      <label :for="idFor('shopitems-name')">
        {{ t('labels.filters.shopItems.name') }}
      </label>
      <input
        :id="idFor('shopitems-name')"
        v-model="form.nameCont"
        :placeholder="t('placeholders.filters.shopItems.name')"
        type="text"
        class="form-control"
      >
      <a
        v-if="form.nameCont"
        class="btn btn-clear"
        @click="clearName"
        v-html="'&times;'"
      />
    </div>
    <FilterGroup
      :options="categoryOptions"
      v-model="form.categoryIn"
      :label="t('labels.filters.shopItems.category')"
      :name="`${prefix}-category`"
      multiple
    />
    <FilterGroup
      v-model="form.subCategoryIn"
      :label="t('labels.filters.shopItems.subCategory')"
      :name="`${prefix}-sub-category`"
      :fetch="fetchSubCategories"
      multiple
    />
    <FilterGroup
      v-model="form.manufacturerSlugIn"
      :label="t('labels.filters.shopItems.manufacturer')"
      :name="`${prefix}-manufacturer`"
      :fetch="fetchManufacturers"
      value-attr="slug"
      icon-attr="logo"
      paginated
      searchable
      multiple
    />
    <div class="form-group">
      <label :for="idFor('shopitems-min-price')">
        {{ t('labels.filters.shopItems.minPrice') }}
      </label>
      <input
        :id="idFor('shopitems-min-price')"
        v-model="form.minPrice"
        :placeholder="t('placeholders.filters.shopItems.minPrice')"
        type="number"
        class="form-control"
      >
      <a
        v-if="form.minPrice"
        class="btn btn-clear"
        @click="clearMinPrice"
        v-html="'&times;'"
      />
    </div>
    <div class="form-group">
      <label :for="idFor('shopitems-max-price')">
        {{ t('labels.filters.shopItems.maxPrice') }}
      </label>
      <input
        :id="idFor('shopitems-max-price')"
        v-model="form.maxPrice"
        :placeholder="t('placeholders.filters.shopItems.maxPrice')"
        type="number"
        class="form-control"
      >
      <a
        v-if="form.maxPrice"
        class="btn btn-clear"
        @click="clearMaxPrice"
        v-html="'&times;'"
      />
    </div>
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
        nameCont: query.nameCont,
        categoryIn: query.categoryeIn || [],
        subCategoryIn: query.subCategoryIn || [],
        manufacturerSlugIn: query.manufacturerSlugIn || [],
        minPrice: query.minPrice,
        maxPrice: query.maxPrice,
      },
      categoryOptions: [{
        name: 'Ship',
        value: 'Model',
      }, {
        name: 'Component',
        value: 'Component',
      }, {
        name: 'Equipment',
        value: 'Equipment',
      }, {
        name: 'Commodity',
        value: 'Commodity',
      }],
    }
  },
  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        nameCont: query.nameCont,
        categoryIn: query.categoryIn || [],
        subCategoryIn: query.subCategoryIn || [],
        manufacturerSlugIn: query.manufacturerSlugIn || [],
        minPrice: query.minPrice,
        maxPrice: query.maxPrice,
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
    clearMinPrice() {
      this.form.minPrice = null
    },
    clearMaxPrice() {
      this.form.maxPrice = null
    },
    fetchSubCategories() {
      return this.$api.get('filters/shop-commodities/sub-categories')
    },
  },
}
</script>
