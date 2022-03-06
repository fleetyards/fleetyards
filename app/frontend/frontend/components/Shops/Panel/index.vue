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
                {{ shop.station.name }} {{ shop.location }}
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

<script>
import Panel from '@/frontend/core/components/Panel/index.vue'

export default {
  name: 'ShopPanel',

  components: {
    Panel,
  },

  props: {
    shop: {
      required: true,
      type: Object,
    },
  },
}
</script>
