<template>
  <form @submit.prevent="filter">
    <FormInput
      id="shop-name"
      v-model="form.nameCont"
      translation-key="filters.shopItems.name"
      :no-label="true"
      :clearable="true"
    />

    <FilterGroup
      v-model="form.categoryIn"
      :options="categoryOptions"
      :label="$t('labels.filters.shopItems.category')"
      name="category"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.subCategoryIn"
      :label="$t('labels.filters.shopItems.subCategory')"
      :fetch="fetchSubCategories"
      name="sub-category"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.manufacturerIn"
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
import Filters from '@/frontend/mixins/Filters'
import FilterGroup from '@/frontend/core/components/Form/FilterGroup/index.vue'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'

export default {
  name: 'ShopsItemFilterForm',

  components: {
    Btn,
    FilterGroup,
    FormInput,
  },

  mixins: [Filters],

  data() {
    const query = this.$route.query.q || {}

    return {
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

      form: {
        categoryIn: query.categoryIn || [],
        manufacturerIn: query.manufacturerIn || [],
        nameCont: query.nameCont,
        priceGteq: query.priceGteq,
        priceLteq: query.priceLteq,
        subCategoryIn: query.subCategoryIn || [],
      },

      loading: false,
    }
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        categoryIn: query.categoryIn || [],
        manufacturerIn: query.manufacturerIn || [],
        nameCont: query.nameCont,
        priceGteq: query.priceGteq,
        priceLteq: query.priceLteq,
        subCategoryIn: query.subCategoryIn || [],
      }
    },
  },

  methods: {
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

    fetchSubCategories() {
      return this.$api.get('filters/shop-commodities/sub-categories')
    },
  },
}
</script>
