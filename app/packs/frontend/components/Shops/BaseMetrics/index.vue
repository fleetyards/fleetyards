<template>
  <div
    class="row"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ $t('labels.metrics.info') }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div class="col-6">
          <div class="metrics-label">{{ $t('shop.type') }}:</div>
          <div v-tooltip="shop.typeLabel" class="metrics-value">
            {{ shop.typeLabel }}
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-6">
          <div class="metrics-label">{{ $t('shop.celestialObject') }}:</div>
          <div class="metrics-value">
            <router-link
              :to="{
                name: 'celestial-object',
                params: {
                  starsystem: shop.celestialObject.starsystem.slug,
                  slug: shop.celestialObject.slug,
                },
              }"
            >
              {{ shop.celestialObject.name }}
            </router-link>
          </div>
        </div>
        <div class="col-6">
          <div class="metrics-label">{{ $t('shop.station') }}:</div>
          <div class="metrics-value">
            <router-link
              :to="{
                name: 'station',
                params: {
                  slug: shop.station.slug,
                },
                hash: `#${shop.slug}`,
              }"
            >
              {{ shop.station.name }}
            </router-link>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-6">
          <div class="metrics-label">{{ $t('shop.refineryTerminal') }}:</div>
          <div class="metrics-value">
            {{ $t(`labels.${shop.refineryTerminal}`) }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ShopsBaseMetrics',

  props: {
    shop: {
      type: Object,
      required: true,
    },

    padding: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
