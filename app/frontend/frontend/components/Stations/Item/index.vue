<template>
  <Panel :id="id || item.slug" class="station-item">
    <div class="panel-image text-center">
      <router-link
        :key="item.storeImageMedium"
        v-lazy:background-image="item.storeImageMedium"
        :to="route"
        :aria-label="item.name"
        class="lazy"
      />
    </div>
    <h2 class="panel-title">
      <router-link :to="route" :aria-label="item.name">
        {{ item.name }}
      </router-link>
    </h2>
  </Panel>
</template>

<script>
import Panel from '@/frontend/core/components/Panel/index.vue'

export default {
  name: 'StationsItem',
  components: {
    Panel,
  },

  props: {
    id: {
      default: null,
      type: String,
    },

    item: {
      required: true,
      type: Object,
    },

    route: {
      required: true,
      type: Object,
    },
  },
}
</script>

<style lang="scss">
@import 'index';
</style>
