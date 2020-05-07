<template>
  <div v-tooltip.bottom="label" class="fleetchart-item fade-list-item">
    <a :href="url" target="_blank" rel="noopener">
      <FleetchartItemImage
        v-if="model.fleetchartImage"
        :model="model"
        :scale="scale"
      />
      <FleetchartItemLabel :label="label" />
    </a>
  </div>
</template>

<script>
import FleetchartItemImage from 'frontend/partials/Fleetchart/List/Item/Image'
import FleetchartItemLabel from 'frontend/partials/Fleetchart/List/Item/Label'

export default {
  components: {
    FleetchartItemImage,
    FleetchartItemLabel,
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
