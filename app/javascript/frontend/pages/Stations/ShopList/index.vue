<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1 class="sr-only">
          {{ $t('headlines.shops') }}
        </h1>
      </div>
    </div>
    <FilteredList
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
      :paginated="true"
    >
      <FilterForm slot="filter" />

      <template v-slot:default="{ records }">
        <transition-group
          name="fade-list"
          class="flex-row"
          tag="div"
          :appear="true"
        >
          <div
            v-for="(shop, index) in records"
            :key="`shops-${index}`"
            class="col-xs-12 col-md-6 fade-list-item"
          >
            <Panel :id="`${shop.station.slug}-${shop.slug}`" class="shop-list">
              <div
                :key="shop.storeImageMedium"
                v-lazy:background-image="shop.storeImageMedium"
                class="panel-bg lazy"
              />
              <div class="row">
                <div class="col-xs-12">
                  <div class="panel-heading">
                    <h2 class="panel-title">
                      <router-link
                        :to="{
                          name: 'shop',
                          params: {
                            station: shop.station.slug,
                            slug: shop.slug,
                          },
                        }"
                        :aria-label="shop.name"
                      >
                        <small>
                          {{ shop.station.name }}
                        </small>
                        {{ shop.name }}
                      </router-link>
                    </h2>
                  </div>
                </div>
              </div>
            </Panel>
          </div>
        </transition-group>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Panel from 'frontend/components/Panel'
import FilterForm from 'frontend/partials/Shops/FilterForm'
import FilteredList from 'frontend/components/FilteredList'
import shopsCollection from 'frontend/collections/Shops'

@Component<ShopList>({
  components: {
    Panel,
    FilterForm,
    FilteredList,
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
