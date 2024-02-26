<template>
  <div class="col-12 fade-list-item quick-filter">
    <form @submit.prevent="filter">
      <div class="row">
        <div class="col-12 col-md-4">
          <FilterGroup
            v-model="form.originStationIn"
            :label="$t('labels.filters.tradeRoutes.origin')"
            fetch-path="stations?quickfilter-origin"
            name="origin"
            value-attr="slug"
            :paginated="true"
            :searchable="true"
            :multiple="true"
            :no-label="true"
          />
        </div>
        <div class="col-12 col-md-4">
          <FilterGroup
            v-model="form.commodityIn"
            :label="$t('labels.filters.shops.commodity')"
            fetch-path="commodities?quickfilter"
            name="commodity"
            value-attr="slug"
            :paginated="true"
            :searchable="true"
            :multiple="true"
            :no-label="true"
          />
        </div>
        <div class="col-12 col-md-4">
          <FilterGroup
            v-model="form.destinationStationIn"
            :label="$t('labels.filters.tradeRoutes.destination')"
            fetch-path="stations?quickfilter-destination"
            name="destination"
            value-attr="slug"
            :paginated="true"
            :searchable="true"
            :multiple="true"
            :no-label="true"
          />
        </div>
      </div>
    </form>
  </div>
</template>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";

const form = ref({});

const setupForm = () => {
  const query = queryParams();

  query.originStationIn = query.originStationIn || [];
  query.commodityIn = query.commodityIn || [];
  query.destinationStationIn = query.destinationStationIn || [];

  form.value = query;
};

const route = useRoute();

watch(
  () => route.query,
  () => {
    setupForm();
  },
  { deep: true },
);

const queryParams = () => {
  return JSON.parse(JSON.stringify(route.query.q || {}));
};
</script>

<script lang="ts">
export default {
  name: "TradeRoutesQuickFilter",
};
</script>

<style lang="scss" scoped>
.quick-filter {
  margin-bottom: 20px;
}
</style>
