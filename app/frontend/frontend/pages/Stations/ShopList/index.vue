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
      :name="String(route.name)"
      :route-query="$route.query"
      :hash="route.hash"
      :paginated="true"
    >
      <template #filter>
        <FilterForm />
      </template>

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
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FilteredGrid from "@/shared/components/FilteredGrid/index.vue";
import FilterForm from "@/frontend/components/Shops/FilterForm/index.vue";
import ShopPanel from "@/frontend/components/Shops/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
// import shopsCollection from "@/frontend/api/collections/Shops";

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "ShopsPage",
};
</script>

<style lang="scss">
@import "index";
</style>
