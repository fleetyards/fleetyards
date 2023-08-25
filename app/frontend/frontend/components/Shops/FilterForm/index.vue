<template>
  <form @submit.prevent="filter">
    <FormInput
      id="shop-name"
      v-model="form.nameCont"
      translation-key="filters.shops.name"
      :no-label="true"
      :clearable="true"
    />

    // TODO: migrate to new FilterGroup props
    <FilterGroup
      v-model="form.modelIn"
      :label="t('labels.filters.shops.model')"
      fetch-path="models"
      name="model"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.commodityIn"
      :label="t('labels.filters.shops.commodity')"
      fetch-path="commodities"
      name="commodity"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.equipmentIn"
      :label="t('labels.filters.shops.equipment')"
      fetch-path="equipment"
      name="equipment"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.componentIn"
      :label="t('labels.filters.shops.component')"
      fetch-path="components"
      name="component"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.shopTypeIn"
      :label="t('labels.filters.shops.type')"
      :fetch="fetchShopTypes"
      name="type"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.stationIn"
      :label="t('labels.filters.shops.station')"
      fetch-path="stations"
      name="station"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.celestialObjectIn"
      :label="t('labels.filters.shops.celestialObject')"
      fetch-path="celestial-objects"
      name="celestial-object"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.starsystemIn"
      :label="t('labels.filters.shops.starsystem')"
      fetch-path="starsystems"
      name="starsystem"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/Form/FilterGroup/index.vue";
import FormInput from "@/shared/components/Form/FormInput/index.vue";
import Btn from "@/shared/components/BaseBtn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import type { ShopQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";
const { t } = useI18n();

const setupForm = () => {
  form.value = {
    nameCont: routeQuery.value.nameCont,
    modelIn: routeQuery.value.modelIn || [],
    commodityIn: routeQuery.value.commodityIn || [],
    equipmentIn: routeQuery.value.equipmentIn || [],
    componentIn: routeQuery.value.componentIn || [],
    stationIn: routeQuery.value.stationIn || [],
    celestialObjectIn: routeQuery.value.celestialObjectIn || [],
    starsystemIn: routeQuery.value.starsystemIn || [],
    shopTypeIn: routeQuery.value.shopTypeIn || [],
  };
};

const { filter, resetFilter, isFilterSelected, routeQuery } =
  useFilters<ShopQuery>(setupForm);

const form = ref<ShopQuery>({});
</script>

<script lang="ts">
export default {
  name: "ShopsFilterForm",
};
</script>
