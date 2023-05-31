<template>
  <form
    @submit.prevent="
      () => {
        filter(form);
      }
    "
  >
    <FormInput
      id="shop-name"
      v-model="form.name"
      translation-key="filters.shopItems.name"
      :no-label="true"
      :clearable="true"
    />

    <FilterGroup
      v-model="form.category"
      :options="categoryOptions"
      :label="t('labels.filters.shopItems.category')"
      name="category"
      :multiple="true"
      :no-label="true"
      :searchable="true"
    />

    <CollectionFilterGroup
      v-model="form.subCategory"
      :label="t('labels.filters.shopItems.subCategory')"
      :fetch="fetchSubCategories"
      name="sub-category"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      v-model="form.manufacturerSlug"
      :label="t('labels.filters.shopItems.manufacturer')"
      :fetch="fetchCommodityManufacturers"
      name="manufacturer"
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
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import Btn from "@/frontend/core/components/Btn/index.vue";
import CollectionFilterGroup from "@/frontend/core/components/Form/CollectionFilterGroup/index.vue";
import type { TFilterGroupFetchParams } from "@/frontend/core/components/Form/CollectionFilterGroup/index.vue";
import FilterGroup from "@/frontend/core/components/Form/FilterGroup/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import { useFilters } from "@/frontend/composables/useFilters";
import { useI18n } from "@/frontend/composables/useI18n";
import manufacturersCollection from "@/frontend/api/collections/Manufacturer";
import shopCommoditiesCollection from "@/frontend/api/collections/ShopCommodities";

type Props = {
  stationSlug: string;
  shopSlug: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();

const query = computed(() => {
  return (route.query.query || {}) as TShopCommodityFilters;
});

const form = ref<TShopCommodityFilters>({
  name: query.value.name,
  category: query.value.category || [],
  subCategory: query.value.subCategory || [],
  manufacturerSlug: query.value.manufacturerSlug || [],
  priceGteq: query.value.priceGteq,
  priceLteq: query.value.priceLteq,
});

const { resetFilter, filter, isFilterSelected } = useFilters();

const categoryOptions = [
  {
    label: "Ship",
    value: "Model",
  },
  {
    label: "Component",
    value: "Component",
  },
  {
    label: "Equipment",
    value: "Equipment",
  },
  {
    label: "Commodity",
    value: "Commodity",
  },
  {
    label: "Module",
    value: "ModelModule",
  },
];

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true }
);

watch(
  () => route,
  () => {
    form.value = {
      name: query.value.name,
      category: query.value.category || [],
      subCategory: query.value.subCategory || [],
      manufacturerSlug: query.value.manufacturerSlug || [],
      priceGteq: query.value.priceGteq,
      priceLteq: query.value.priceLteq,
    };
  },
  { deep: true }
);

const fetchSubCategories = async () => {
  const subCategories = await shopCommoditiesCollection.subCategories(
    props.stationSlug,
    props.shopSlug
  );

  return subCategories.map((item) => ({
    label: item.name,
    value: item.value,
  }));
};

const fetchCommodityManufacturers = async ({
  page,
  search,
  missing,
}: TFilterGroupFetchParams) => {
  const query = {} as TManufacturerParams;

  const filters = {} as TManufacturerFilters;
  if (search) {
    filters.nameCont = search;
  } else if (missing) {
    if (Array.isArray(missing)) {
      filters.nameIn = missing;
    } else {
      filters.nameCont = missing;
    }
  } else if (page) {
    query.page = page;
  }

  const response = await manufacturersCollection.findAll({
    filters,
    ...query,
  });

  if ((response as TCollectionErrorResponse).error) {
    return [];
  }

  return (response as TCollectionSuccessResponse<TManufacturer>).data.map(
    (item) => ({
      label: item.name,
      value: item.slug,
      icon: item.logo,
    })
  );
};
</script>

<script lang="ts">
export default {
  name: "ShopsItemFilterForm",
};
</script>
