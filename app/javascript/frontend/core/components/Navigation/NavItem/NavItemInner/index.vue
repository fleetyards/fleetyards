<template>
  <div
    class="nav-item-inner"
    :class="{
      'nav-item-inner-slim': slim,
    }"
  >
    <img
      v-if="image"
      :src="image"
      :alt="`${label} image`"
      class="nav-item-image"
    />
    <i
      v-else-if="icon"
      :class="{
        [icon]: true,
      }"
    />
    <span v-else class="nav-item-image-empty">
      {{ firstLetter }}
    </span>
    <transition name="fade-nav">
      <span
        v-if="!slim"
        :class="{
          'nav-item-text': !icon && !image,
        }"
      >
        {{ label }}
      </span>
    </transition>
  </div>
</template>

<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },

    icon: {
      type: String,
      default: null,
    },

    image: {
      type: String,
      default: null,
    },

    slim: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    firstLetter() {
      return this.label.charAt(0)
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
