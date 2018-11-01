<template>
  <form @submit.prevent="filter">
    <div class="form-group">
      <input
        v-model="form.nameCont"
        :placeholder="t('placeholders.filters.shopItems.name')"
        type="text"
        class="form-control form-control-filter"
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
      name="category"
      multiple
    />
    <FilterGroup
      v-model="form.subCategoryIn"
      :label="t('labels.filters.shopItems.subCategory')"
      :fetch="fetchSubCategories"
      name="sub-category"
      multiple
    />
    <FilterGroup
      v-model="form.manufacturerIn"
      :label="t('labels.filters.shopItems.manufacturer')"
      :fetch="fetchCommodityManufacturers"
      name="manufacturer"
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
        v-model="form.priceGteq"
        :placeholder="t('placeholders.filters.shopItems.minPrice')"
        type="number"
        class="form-control"
      >
      <a
        v-if="form.priceGteq"
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
        v-model="form.priceLteq"
        :placeholder="t('placeholders.filters.shopItems.maxPrice')"
        type="number"
        class="form-control"
      >
      <a
        v-if="form.priceLteq"
        class="btn btn-clear"
        @click="clearMaxPrice"
        v-html="'&times;'"
      />
    </div>
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
import FilterGroup from 'frontend/components/Form/FilterGroup'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    FilterGroup,
    Btn,
  },
  mixins: [I18n, Filters],
  data() {
    const query = this.$route.query.q || {}
    return {
      loading: false,
      form: {
        nameCont: query.nameCont,
        categoryIn: query.categoryeIn || [],
        subCategoryIn: query.subCategoryIn || [],
        manufacturerIn: query.manufacturerIn || [],
        priceGteq: query.priceGteq,
        priceLteq: query.priceLteq,
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
        manufacturerIn: query.manufacturerIn || [],
        priceGteq: query.priceGteq,
        priceLteq: query.priceLteq,
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
      this.form.priceGteq = null
    },
    clearMaxPrice() {
      this.form.priceLteq = null
    },
    fetchSubCategories() {
      return this.$api.get('filters/shop-commodities/sub-categories')
    },
    fetchCommodityManufacturers({ page, search, missingValue }) {
      const query = {
        q: {},
      }
      if (search) {
        query.q.nameCont = search
      } else if (missingValue) {
        query.q.nameIn = missingValue
      } else if (page) {
        query.page = page
      }
      return this.$api.get('manufacturers', query)
    },
  },
}
</script>
