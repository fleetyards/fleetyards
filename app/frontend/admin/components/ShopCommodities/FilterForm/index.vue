<script lang="ts">
export default {
  name: "ShopCommoditiesFilterForm",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useRoute } from "vue-router";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import type { FilterGroupParams } from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
// import type { ShopCommodityQuery } from "@/services/fyAdminApi/models";
// import { useApiClient } from "@/admin/composables/useApiClient";

const { filter, isFilterSelected, resetFilter } =
  useFilters<ShopCommodityQuery>();

const { t } = useI18n();

const route = useRoute();

const query = computed(() => (route.query.q || {}) as ShopCommodityQuery);

const form = ref<ShopCommodityQuery>({
  search: query.value.search,
  componentItemType: query.value.componentItemType,
  equipmentItemType: query.value.equipmentItemType,
  equipmentType: query.value.equipmentType,
  equipmentSlot: query.value.equipmentSlot,
});

const setupForm = () => {
  form.value = {
    search: query.value.search,
    componentItemType: query.value.componentItemType,
    equipmentItemType: query.value.equipmentItemType,
    equipmentType: query.value.equipmentType,
    equipmentSlot: query.value.equipmentSlot,
  };
};

watch(
  () => form,
  () => {
    filter(form.value);
  },
  {
    deep: true,
  },
);

const submit = () => {
  filter(form.value);
};

onMounted(() => {
  setupForm();
});

watch(
  () => route.query,
  () => {
    setupForm();
  },
);

const { componentsFilters: componentFiltersService } = useApiClient();

const fetchComponentItemTypeFilters = async (_params: FilterGroupParams) => {
  return componentFiltersService.itemTypes();
};
</script>

<template>
  <form @submit.prevent="submit">
    <FormInput
      v-model="form.search"
      name="commodity-item-name"
      translation-key="filters.shopCommodities.name"
      :no-label="true"
      :clearable="true"
    />

    <FilterGroup
      v-model="form.componentItemType"
      name="component-item-type-filter"
      :query-fn="fetchComponentItemTypeFilters"
      :label="t('labels.filters.shopCommodities.componentItemTypeFilter')"
      searchable
      multiple
      no-label
    />

    <!-- <CollectionFilterGroup
      key="component-item-type-filters-filter-group"
      v-model="form.componentItemType"
      :label="t('labels.filters.shopCommodities.componentItemTypeFilter')"
      :collection="componentItemTypeFiltersCollection"
      name="component-item-type-filter"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    /> -->

    <!-- <CollectionFilterGroup
      key="equipment-item-type-filters-filter-group"
      v-model="form.equipmentItemType"
      :label="t('labels.filters.shopCommodities.equipmentItemTypeFilter')"
      :collection="equipmentItemTypeFiltersCollection"
      name="equipment-item-type-filter"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      key="equipment-type-filters-filter-group"
      v-model="form.equipmentType"
      :label="t('labels.filters.shopCommodities.equipmentTypeFilter')"
      :collection="equipmentTypeFiltersCollection"
      name="equipment-type-filter"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      key="equipment-slot-filters-filter-group"
      v-model="form.equipmentSlot"
      :label="t('labels.filters.shopCommodities.equipmentSlotFilter')"
      :collection="equipmentSlotFiltersCollection"
      name="equipment-slot-filter"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    /> -->

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
