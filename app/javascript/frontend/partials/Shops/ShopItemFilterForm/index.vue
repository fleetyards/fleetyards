<template>
  <form @submit.prevent="filter">
    <FormInput
      v-model="form.nameCont"
      :placeholder="$t('placeholders.filters.shopItems.name')"
    />

    <FilterGroup
      v-model="form.categoryIn"
      :options="categoryOptions"
      :label="$t('labels.filters.shopItems.category')"
      name="category"
      multiple
    />

    <FilterGroup
      v-model="form.subCategoryIn"
      :label="$t('labels.filters.shopItems.subCategory')"
      :fetch="fetchSubCategories"
      name="sub-category"
      multiple
    />

    <FilterGroup
      v-model="form.manufacturerIn"
      :label="$t('labels.filters.shopItems.manufacturer')"
      :fetch="fetchCommodityManufacturers"
      name="manufacturer"
      value-attr="slug"
      icon-attr="logo"
      paginated
      searchable
      multiple
    />

    <FormInput
      :id="idFor('shopitems-min-price')"
      v-model="form.priceGteq"
      :label="$t('labels.filters.shopItems.minPrice')"
      :placeholder="$t('placeholders.filters.shopItems.minPrice')"
      type="number"
    />

    <FormInput
      :id="idFor('shopitems-max-price')"
      v-model="form.priceLteq"
      :label="$t('labels.filters.shopItems.maxPrice')"
      :placeholder="$t('placeholders.filters.shopItems.maxPrice')"
      type="number"
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
import FilterGroup from 'frontend/components/Form/FilterGroup'
import FormInput from 'frontend/components/Form/FormInput'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    FilterGroup,
    FormInput,
    Btn,
  },
  mixins: [Filters],
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
      }, {
        name: 'Module',
        value: 'ModelModule',
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
