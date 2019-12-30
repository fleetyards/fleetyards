<template>
  <div v-if="item">
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
    <transition name="fade-nav">
      <span v-if="!slim">{{ item.label }}</span>
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
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
