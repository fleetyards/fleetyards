<template>
  <Panel :id="item.slug" class="station-list">
    <div
      :key="item.storeImage"
      v-lazy:background-image="item.storeImage"
      class="panel-bg lazy"
    />
    <div class="row">
      <div class="col-xs-12">
        <div class="panel-heading">
          <h2 class="panel-title">
            <router-link :to="route" :aria-label="item.name">
              {{ item.name }}
            </router-link>
          </h2>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 col-sm-6 col-lg-4" />
      <div class="col-xs-12 col-sm-6 col-lg-8 items">
        <slot />
      </div>
    </div>
  </Panel>
</template>

<script>
import Panel from 'frontend/components/Panel'

export default {
  components: {
    Panel,
  },

  props: {
    route: {
      type: Object,
      required: true,
    },

    item: {
      type: Object,
      required: true,
    },
  },
}
</script>

<style lang="scss">
@import 'index';
</style>
