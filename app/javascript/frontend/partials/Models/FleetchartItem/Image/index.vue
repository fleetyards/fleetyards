<template>
  <img
    v-if="model.fleetchartImage"
    :style="{
      height: `${model.length * lengthMultiplicator}px`,
    }"
    :src="model.fleetchartImage"
    :alt="model.slug"
    class="fleetchart-item-image"
  >
  <span v-else>
    <i class="fal fa-question-circle" />
    <p>{{ model.name }}</p>
  </span>
</template>

<script>
export default {
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
    lengthMultiplicator() {
      return this.scale * 4
    },
  },
}
</script>
