<template>
  <div
    v-tooltip.bottom="label"
    class="fleetchart-item fade-list-item"
  >
    <router-link
      :to="{
        name: 'model',
        params: {
          slug: model.slug,
        },
      }"
    >
      <FleetchartItemImage
        v-if="model.fleetchartImage"
        :model="model"
        :scale="scale"
      />
      <FleetchartItemLabel :label="label" />
    </router-link>
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
