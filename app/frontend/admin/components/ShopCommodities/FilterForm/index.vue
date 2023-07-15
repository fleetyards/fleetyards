<template>
  <form @submit.prevent="submit">
    <FormInput
      id="commodity-item-name"
      v-model="search"
      translation-key="filters.shopCommodities.name"
      :no-label="true"
      :clearable="true"
    />

    <CollectionFilterGroup
      key="component-item-type-filters-filter-group"
      v-model="form.componentItemType"
      :label="t('labels.filters.shopCommodities.componentItemTypeFilter')"
      :collection="componentItemTypeFiltersCollection"
      name="component-item-type-filter"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
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
    />

    <Btn :disabled="!filterSelected" :block="true" @click.native="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import { debounce } from "ts-debounce";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { useRoute, useRouter } from "vue-router/composables";
import componentItemTypeFiltersCollection from "@/admin/api/collections/ComponentItemTypeFilters";
import equipmentItemTypeFiltersCollection from "@/admin/api/collections/EquipmentItemTypeFilters";
import equipmentTypeFiltersCollection from "@/admin/api/collections/EquipmentTypeFilters";
import equipmentSlotFiltersCollection from "@/admin/api/collections/EquipmentSlotFilters";
import { getFilters, isFilterSelected } from "@/frontend/utils/Filters";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import CollectionFilterGroup from "@/frontend/core/components/Form/CollectionFilterGroup/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

type ShopCommodityFilterForm = {
  componentItemType: string[];
  equipmentItemType: string[];
  equipmentType: string[];
  equipmentSlot: string[];
};

const search = ref("");

const form = ref<ShopCommodityFilterForm>({
  componentItemType: [],
  equipmentItemType: [],
  equipmentType: [],
  equipmentSlot: [],
});

const route = useRoute();

const queryFilters = computed(
  () => (route.query.filters || {}) as ShopCommodityFilterForm
);

const filterSelected = computed(() => isFilterSelected(queryFilters.value));

watch(
  () => form,
  () => {
    filter();
  },
  {
    deep: true,
  }
);

watch(
  () => search.value,
  () => {
    filter();
  }
);

const router = useRouter();

const resetFilter = () => {
  router
    .replace({
      name: route.name || undefined,
      query: {},
    })
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    .catch((_err) => {});
};

const debouncedFilter = () => {
  router
    .replace({
      name: route.name || undefined,
      query: {
        ...route.query,
        search: search.value || undefined,
        filters: getFilters(form.value),
      },
    })
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    .catch((_err) => {});
};

const filter = debounce(debouncedFilter, 500);

const submit = () => {
  filter();
};

onMounted(() => {
  setupForm();
});

watch(
  () => route.query,
  () => {
    setupForm();
  }
);

const setupForm = () => {
  form.value = {
    componentItemType: queryFilters.value.componentItemType || [],
    equipmentItemType: queryFilters.value.equipmentItemType || [],
    equipmentType: queryFilters.value.equipmentType || [],
    equipmentSlot: queryFilters.value.equipmentSlot || [],
  };
};
</script>

<script lang="ts">
export default {
  name: "ShopCommoditiesFilterForm",
};
</script>
