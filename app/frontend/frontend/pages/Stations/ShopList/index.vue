<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ t("headlines.shops") }}
        </h1>
      </div>
    </div>
    <FilteredList
      key="shops"
      :collection="collection"
      :name="route.name"
      :route-query="route.query"
      :hash="route.hash"
      :paginated="true"
    >
      <FilterForm slot="filter" />

      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :loading="loading"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <ShopPanel :shop="record" />
          </template>
        </FilteredGrid>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import FilterForm from "@/frontend/components/Shops/FilterForm/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import ShopPanel from "@/frontend/components/Shops/Panel/index.vue";
import shopsCollection from "@/frontend/api/collections/Shops";
import { useI18n } from "@/frontend/composables/useI18n";

const route = useRoute();

const { t } = useI18n();

const collection = shopsCollection;
</script>

<script lang="ts">
export default {
  name: "ShopListPage",
};
</script>

<style lang="scss">
@import "index";
</style>
