<template>
  <form @submit.prevent="filter">
    <template v-if="mobile">
      <FilterGroup
        v-model="form.originStationIn"
        :label="t('labels.filters.tradeRoutes.origin')"
        fetch-path="stations?origin"
        name="origin"
        value-attr="slug"
        :paginated="true"
        :searchable="true"
        :multiple="true"
        :no-label="true"
      />

      <FilterGroup
        v-model="form.destinationStationIn"
        :label="t('labels.filters.tradeRoutes.destination')"
        fetch-path="stations?destination"
        name="destination"
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

      <hr />
    </template>

    <FilterGroup
      v-model="form.cargoShip"
      fetch-path="models/cargo-options"
      :label="t('labels.filters.tradeRoutes.cargoShip')"
      name="models"
      :paginated="true"
      :searchable="true"
    />

    <FilterGroup
      v-model="form.commodityTypeNotIn"
      :label="t('labels.filters.tradeRoutes.excludeCommodityType')"
      fetch-path="commodities/types"
      name="exclude-commodity-types"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      v-model="form.originCelestialObjectIn"
      :label="t('labels.filters.tradeRoutes.originCelestialObject')"
      :collection="celestialObjectCollection"
      name="origin-celestial-objects"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      v-model="form.destinationCelestialObjectIn"
      :label="t('labels.filters.tradeRoutes.destinationCelestialObject')"
      :collection="celestialObjectCollection"
      name="destination-celestial-objects"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      v-model="form.originStarsystemIn"
      :collection="starsystemCollection"
      :label="t('labels.filters.tradeRoutes.originStarsystem')"
      name="origin-starsystems"
      value-attr="slug"
      :paginated="true"
      :searchable="true"
      :multiple="true"
      :no-label="true"
    />

    <CollectionFilterGroup
      v-model="form.destinationStarsystemIn"
      :collection="starsystemCollection"
      :label="t('labels.filters.tradeRoutes.destinationStarsystem')"
      name="destination-starsystems"
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
import Btn from "@/shared/components/BaseBtn/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { TradeRouteQuery } from "@/services/fyApi";
import { useI18n } from "@/frontend/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
// import celestialObjectCollection from "@/frontend/api/collections/CelestialObjects";
// import starsystemCollection from "@/frontend/api/collections/Starsystems";

// celestialObjectCollection: CelestialObjectCollection =
//   celestialObjectCollection;

// starsystemCollection: StarsystemCollection = starsystemCollection;

const { t } = useI18n();

const { filter, isFilterSelected, resetFilter } = useFilters();

const form = ref<TradeRouteQuery>({});

const mobile = useMobile();

const route = useRoute();

const query = computed(() => {
  return (route.query.q || {}) as TradeRouteQuery;
});

const setupForm = () => {
  form.value = {
    cargoShip: query.value.cargoShip,
    commodityIn: query.value.commodityIn || [],
    commodityTypeNotIn: query.value.commodityTypeNotIn || [],
    originStationIn: query.value.originStationIn || [],
    destinationStationIn: query.value.destinationStationIn || [],
    originCelestialObjectIn: query.value.originCelestialObjectIn || [],
    destinationCelestialObjectIn:
      query.value.destinationCelestialObjectIn || [],
    originStarsystemIn: query.value.originStarsystemIn || [],
    destinationStarsystemIn: query.value.destinationStarsystemIn || [],
    sorts: query.value.sorts || [],
  };
};

onMounted(() => {
  setupForm();
});

watch(
  () => route.query,
  () => {
    setupForm();
  },
  { deep: true },
);
</script>

<script lang="ts">
export default {
  name: "TradeRoutesFilterForm",
};
</script>
