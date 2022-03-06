<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      'width': `${width}px`,
      'max-height': height ? `${height}px` : null,
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
    height: {
      type: Number,
      default: null,
    },

    label: {
      type: String,
      required: true,
    },

    src: {
      type: String,
      required: true,
    },

    width: {
      type: Number,
      required: true,
    },
  },
}
</script>
