<template>
  <Panel
    :id="station.slug"
    class="station-panel"
  >
    <div
      :key="station.storeImage"
      v-lazy:background-image="station.storeImage"
      class="panel-bg lazy"
    />
    <div class="row">
      <div class="col-xs-12">
        <div class="panel-heading">
          <h2 class="panel-title">
            <router-link
              :to="{
                name: 'station',
                params: {
                  slug: station.slug,
                }
              }"
              :aria-label="station.name"
            >
              {{ station.name }}
            </router-link>
          </h2>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 col-sm-6 col-lg-4">
        <div class="panel-stats">
          <Stats :station="station" />
        </div>
      </div>
      <div class="col-xs-12 col-sm-6 col-lg-8 items">
        <slot />
      </div>
    </div>
  </Panel>
</template>

<script>
import Panel from 'frontend/components/Panel'
import Stats from 'frontend/partials/Stations/ListStats'

export default {
  components: {
    Panel,
    Stats,
  },

  props: {
    station: {
      type: Object,
      required: true,
    },
  },
}
</script>

<style lang="scss">
  @import 'index';
</style>
