<template>
  <Panel :id="`${shop.station.slug}-${shop.slug}`" class="shop-list">
    <div
      :key="shop.storeImageMedium"
      v-lazy:background-image="shop.storeImageMedium"
      class="panel-bg lazy"
    />
    <div class="row">
      <div class="col-12">
        <div class="panel-heading">
          <h2 class="panel-title">
            <router-link
              :to="{
                name: 'shop',
                params: {
                  stationSlug: shop.station.slug,
                  slug: shop.slug,
                },
              }"
              :aria-label="shop.name"
            >
              <small class="text-muted">
                {{ shop.station.name }}
              </small>
              <br />
              {{ shop.name }}
            </router-link>
          </h2>
        </div>
      </div>
    </div>
  </Panel>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Panel from 'frontend/core/components/Panel'

@Component<ShopPanel>({
  components: {
    Panel,
  },
})
export default class ShopPanel extends Vue {
  @Prop({ required: true }) shop!: Shop
}
</script>
