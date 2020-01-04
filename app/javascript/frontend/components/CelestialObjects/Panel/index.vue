<template>
  <Panel
    v-if="item"
    :id="`${item.resultType}-${item.id}`"
    class="celestial-object-panel"
  >
    <div class="panel-image text-center">
      <LazyImage
        :to="route"
        :aria-label="item.name"
        :src="item.storeImageMedium"
        :alt="item.name"
        class="image"
      />
    </div>
    <div class="panel-heading">
      <h2 class="panel-title">
        <router-link :to="route">
          {{ item.name }}
        </router-link>

        <br>

        <small>
          {{ item.locationLabel }}
        </small>
      </h2>
    </div>
  </Panel>
</template>

<script>
import Panel from 'frontend/components/Panel'
import LazyImage from 'frontend/components/LazyImage'

export default {
  components: {
    Panel,
    LazyImage,
  },

  props: {
    item: {
      type: Object,
      required: true,
    },
  },

  computed: {
    route() {
      switch (this.item.resultType) {
        case 'celestial_object':
          return { name: 'celestial-object', params: { starsystem: this.item.starsystem.slug, slug: this.item.slug } }
        case 'starsystem':
          return { name: 'starsystem', params: { slug: this.item.slug } }
        default:
          return ''
      }
    },
  },
}
</script>

<style lang="scss">
  @import 'index';
</style>
