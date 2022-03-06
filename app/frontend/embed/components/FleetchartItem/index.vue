<template>
  <div v-tooltip.bottom="label" class="fleetchart-item fade-list-item">
    <a :href="url" target="_blank" rel="noopener">
      <FleetchartItemImage
        v-if="model.fleetchartImage"
        :src="model.fleetchartImage"
        :length="model.fleetchartLength"
        :label="model.name"
        :scale="scale"
      />
    </a>
  </div>
</template>

<script>
import FleetchartItemImage from '@/embed/partials/Fleetchart/Image/index.vue'

export default {
  name: 'FleetchartItemImage',

  components: {
    FleetchartItemImage,
  },

  props: {
    model: {
      required: true,
      type: Object,
    },

    scale: {
      required: true,
      type: Number,
    },
  },

  computed: {
    label() {
      return `${this.model.manufacturer.code} ${this.model.name}`
    },

    url() {
      return `${window.FRONTEND_ENDPOINT}/ships/${this.model.slug}`
    },
  },
}
</script>
