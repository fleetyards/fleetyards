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
import FleetchartItemImage from 'embed/partials/Fleetchart/Image'

export default {
  components: {
    FleetchartItemImage,
  },
  props: {
    model: {
      type: Object,
      required: true,
    },
    scale: {
      type: Number,
      required: true,
    },
  },
  computed: {
    url() {
      return `${window.FRONTEND_ENDPOINT}/ships/${this.model.slug}`
    },
    label() {
      return `${this.model.manufacturer.code} ${this.model.name}`
    },
  },
}
</script>
