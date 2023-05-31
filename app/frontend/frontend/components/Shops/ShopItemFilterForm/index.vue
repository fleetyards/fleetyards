<template>
  <form @submit.prevent="filter">
    <FormInput
      id="shop-name"
      v-model="form.nameCont"
      translation-key="filters.shopItems.name"
      :no-label="true"
      :clearable="true"
    />

    <FilterGroup2
      v-model="form.categoryIn"
      :options="categoryOptions"
      :label="$t('labels.filters.shopItems.category')"
      name="category"
      :multiple="true"
      :no-label="true"
    />

    <!-- <FilterGroup
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
    /> -->

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
      {{ $t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script>
import Btn from "@/frontend/core/components/Btn/index.vue";
import FilterGroup2 from "@/frontend/core/components/Form/FilterGroup2/index.vue";
import FilterGroup from "@/frontend/core/components/Form/FilterGroup/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import Filters from "@/frontend/mixins/Filters";

export default {
  name: "ShopsItemFilterForm",

  components: {
    FilterGroup,
    FilterGroup2,
    FormInput,
    Btn,
  },

  mixins: [Filters],

  data() {
    const query = this.$route.query.q || {};

    return {
      loading: false,
      form: {
        nameCont: query.nameCont,
        categoryIn: query.categoryIn || [],
        subCategoryIn: query.subCategoryIn || [],
        manufacturerIn: query.manufacturerIn || [],
        priceGteq: query.priceGteq,
        priceLteq: query.priceLteq,
      },
      categoryOptions: [
        {
          name: "Ship",
          value: "Model",
        },
        {
          name: "Component",
          value: "Component",
        },
        {
          name: "Equipment",
          value: "Equipment",
        },
        {
          name: "Commodity",
          value: "Commodity",
        },
        {
          name: "Module",
          value: "ModelModule",
        },
      ],
    };
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {};
      this.form = {
        nameCont: query.nameCont,
        categoryIn: query.categoryIn || [],
        subCategoryIn: query.subCategoryIn || [],
        manufacturerIn: query.manufacturerIn || [],
        priceGteq: query.priceGteq,
        priceLteq: query.priceLteq,
      };
    },
  },

  methods: {
    fetchSubCategories() {
      return this.$api.get("filters/shop-commodities/sub-categories");
    },

    fetchCommodityManufacturers({ page, search, missingValue }) {
      const query = {
        q: {},
      };
      if (search) {
        query.q.nameCont = search;
      } else if (missingValue) {
        query.q.nameIn = missingValue;
      } else if (page) {
        query.page = page;
      }
      return this.$api.get("manufacturers", query);
    },
  },
};
</script>
