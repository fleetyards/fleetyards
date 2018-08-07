<template>
  <div
    v-tooltip.bottom="label"
    class="fleetchart-item fade-list-item"
  >
    <a
      :href="`${$root.frontendHost}/ships/${model.slug}`"
      target="_blank"
      rel="noopener"
    >
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
import FleetchartItemImage from 'frontend/partials/Models/FleetchartItem/Image'
import FleetchartItemLabel from 'frontend/partials/Models/FleetchartItem/Label'

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
    label() {
      return `${this.model.manufacturer.code} ${this.model.name}`
    },
  },
}
</script>
