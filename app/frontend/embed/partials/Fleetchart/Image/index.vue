<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      height: `${length * lengthMultiplicator}px`,
    }"
    :alt="label"
    class="fleetchart-item-image"
  />
  <span v-else>
    <i class="fal fa-question-circle" />
    <p>{{ label }}</p>
  </span>
</template>

<script>
export default {
  name: 'FleetchartListItemImage',

  props: {
    label: {
      type: String,
      default: null,
    },

    length: {
      type: Number,
      default: null,
    },

    scale: {
      type: Number,
      default: null,
    },

    src: {
      type: String,
      default: null,
    },
  },

  computed: {
    lengthMultiplicator() {
      return (this.scale / 100) * 4
    },
  },
}
</script>
