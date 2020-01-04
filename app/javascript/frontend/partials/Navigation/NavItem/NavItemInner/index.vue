<template>
  <div
    v-if="item"
    class="nav-item-inner"
    :class="{
      'nav-item-inner-slim': slim
    }"
  >
    <img
      v-if="item.image"
      :src="item.image"
      :alt="`${item.label} image`"
      class="nav-item-image"
    >
    <i
      v-else-if="item.icon"
      :class="{
        [item.icon]: true,
      }"
    />
    <span
      v-else
      class="nav-item-image-empty"
    >
      {{ firstLetter }}
    </span>
    <transition name="fade-nav">
      <span
        v-if="!slim"
        :class="{
          'nav-item-text': !item.icon && !item.image,
        }"
      >
        {{ item.label }}
      </span>
    </transition>
  </div>
</template>

<script>
export default {
  props: {
    item: {
      type: Object,
      required: true,
    },

    slim: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    firstLetter() {
      return this.item.label.charAt(0)
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
