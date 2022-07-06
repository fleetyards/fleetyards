<template>
  <form @submit.prevent="filter">
    <FormInput
      id="shop-name"
      v-model="search"
      translation-key="filters.shopItems.name"
      :no-label="true"
      :clearable="true"
    />

    <FilterGroup
      v-model="form.category"
      :options="categoryOptions"
      :label="$t('labels.filters.shopItems.category')"
      name="category"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.subCategory"
      :label="$t('labels.filters.shopItems.subCategory')"
      :fetch="fetchSubCategories"
      name="sub-category"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.manufacturerSlug"
      :label="$t('labels.filters.shopItems.manufacturer')"
      :fetch="fetchCommodityManufacturers"
      name="manufacturer"
      value-attr="slug"
      icon-attr="logo"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FormInput
      id="shopitems-min-price"
      v-model="form.priceGteq"
      translation-key="filters.shopItems.minPrice"
      type="number"
    />

    <FormInput
      id="shopitems-max-price"
      v-model="form.priceLteq"
      translation-key="filters.shopItems.maxPrice"
      type="number"
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
import debounce from 'lodash.debounce'
import FilterGroup from '@/frontend/core/components/Form/FilterGroup/index.vue'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import { getFilters, isFilterSelected } from '@/frontend/utils/Filters'

export default {
  name: 'ShopsItemFilterForm',

  components: {
    FilterGroup,
    FormInput,
    Btn,
  },

  data() {
    const query = this.$route.query.query || {}

    return {
      loading: false,
      filter: debounce(this.debouncedFilter, 500),
      search: this.$route.query.search,
      form: {
        category: query.category || [],
        subCategory: query.subCategory || [],
        manufacturerSlug: query.manufacturerSlug || [],
        priceGteq: query.priceGteq,
        priceLteq: query.priceLteq,
      },
      categoryOptions: [
        {
          name: 'Ship',
          value: 'Model',
        },
        {
          name: 'Component',
          value: 'Component',
        },
        {
          name: 'Equipment',
          value: 'Equipment',
        },
        {
          name: 'Commodity',
          value: 'Commodity',
        },
        {
          name: 'Module',
          value: 'ModelModule',
        },
      ],
    }
  },

  computed: {
    isFilterSelected() {
      return (
        isFilterSelected(this.$route.query.query) || this.$route.query.search
      )
    },
  },

  watch: {
    search() {
      this.filter()
    },

    form: {
      handler() {
        this.filter()
      },
      deep: true,
    },

    $route() {
      this.search = this.$route.query.search

      const query = this.$route.query.query || {}
      this.form = {
        category: query.category || [],
        subCategory: query.subCategory || [],
        manufacturerSlug: query.manufacturer || [],
        priceGteq: query.priceGteq,
        priceLteq: query.priceLteq,
      }
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

    resetFilter() {
      this.$router
        .replace({
          name: this.$route.name || undefined,
          query: {},
        })
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        .catch((_err) => {})
    },

    debouncedFilter() {
      const query = {
        ...this.$route.query,
        query: getFilters(this.form),
      }

      if (this.search) {
        query.search = this.search
      } else {
        delete query.search
      }

      this.$router
        .replace({
          name: this.$route.name || undefined,
          query,
        })
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        .catch((_err) => {})
    },
  },
}
</script>
