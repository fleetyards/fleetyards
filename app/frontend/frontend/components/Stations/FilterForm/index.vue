<template>
  <form @submit.prevent="filter">
    <FormInput
      id="station-name"
      v-model="form.nameCont"
      translation-key="filters.stations.name"
      :no-label="true"
      :clearable="true"
    />

    // TODO: migrate to new FilterGroup props
    <FilterGroup
      v-model="form.celestialObjectIn"
      :label="t('labels.filters.stations.celestialObject')"
      :fetch="fetchCelestialObjects"
      name="celestial-object"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.starsystemIn"
      :label="t('labels.filters.stations.starsystem')"
      :fetch="fetchStarsystems"
      name="starsystem"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.stationTypeIn"
      :label="t('labels.filters.stations.type')"
      :fetch="fetchStationTypes"
      name="station-types"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.shopsShopTypeIn"
      :label="t('labels.filters.stations.shops')"
      :fetch="fetchShopTypes"
      name="shops"
      :multiple="true"
      :no-label="true"
    />

    <FilterGroup
      v-model="form.docksShipSizeIn"
      :label="t('labels.filters.stations.docks')"
      :fetch="fetchShipSizes"
      name="docks"
      :multiple="true"
      :no-label="true"
    />

    <RadioList
      v-model="form.habsNotNull"
      :label="tt('labels.filters.stations.habs')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="habs"
    />
    <RadioList
      v-model="form.refineryEq"
      :label="t('labels.filters.stations.refinery')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="refinery"
    />
    <RadioList
      v-model="form.cargoHubEq"
      :label="t('labels.filters.stations.cargoHub')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="cargoHub"
    />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import RadioList from "@/shared/components/base/RadioList/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { StationQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

const { t } = useI18n();

const setupForm = () => {
  form.value = {
    searchCont: routeQuery.value.searchCont,
    nameCont: routeQuery.value.nameCont,
    habsNotNull: routeQuery.value.habsNotNull,
    cargoHubEq: routeQuery.value.cargoHubEq,
    refineryEq: routeQuery.value.refineryEq,
    celestialObjectIn: routeQuery.value.celestialObjectIn || [],
    starsystemIn: routeQuery.value.starsystemIn || [],
    stationTypeIn: routeQuery.value.stationTypeIn || [],
    shopsShopTypeIn: routeQuery.value.shopsShopTypeIn || [],
    docksShipSizeIn: routeQuery.value.docksShipSizeIn || [],
  };
};

const { filter, resetFilter, isFilterSelected, routeQuery } =
  useFilters<StationQuery>(setupForm);

const form = ref<StationQuery>({});

const { booleanOptions } = useFilterOptions(t);

//   methods: {
//     fetchCelestialObjects({ page, search, missingValue }) {
//       const query = {
//         q: {},
//       };
//       if (search) {
//         query.q.nameCont = search;
//       } else if (missingValue) {
//         query.q.nameIn = missingValue;
//       } else if (page) {
//         query.page = page;
//       }
//       return this.$api.get("celestial-objects", query);
//     },
//     fetchStarsystems({ page, search, missingValue }) {
//       const query = {
//         q: {},
//       };
//       if (search) {
//         query.q.nameCont = search;
//       } else if (missingValue) {
//         query.q.nameIn = missingValue;
//       } else if (page) {
//         query.page = page;
//       }
//       return this.$api.get("starsystems", query);
//     },
//     fetchShipSizes() {
//       return this.$api.get("stations/ship-sizes");
//     },
//     fetchStationTypes() {
//       return this.$api.get("stations/station-types");
//     },
//     fetchShopTypes() {
//       return this.$api.get("shops/shop-types");
//     },
//   },
// };
</script>

<script lang="ts">
export default {
  name: "StationsFilterForm",
};
</script>
