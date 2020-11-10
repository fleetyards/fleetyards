<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ $t('headlines.shops') }}
        </h1>
      </div>
    </div>
    <FilteredList
      key="shops"
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
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

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FilterForm from 'frontend/components/Shops/FilterForm'
import FilteredList from 'frontend/core/components/FilteredList'
import FilteredGrid from 'frontend/core/components/FilteredGrid'
import ShopPanel from 'frontend/components/Shops/Panel'
import shopsCollection from 'frontend/api/collections/Shops'

@Component<ShopList>({
  components: {
    FilterForm,
    FilteredList,
    FilteredGrid,
    ShopPanel,
  },
  mixins: [MetaInfo],
})
export default class ShopList extends Vue {
  collection: ShopsCollection = shopsCollection
}
</script>

<style lang="scss">
@import 'index';
</style>
