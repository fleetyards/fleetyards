<template>
  <div
    class="nav-item-inner"
    :class="{
      'nav-item-inner-slim': slim,
    }"
  >
    <span class="nav-item-icon">
      <img
        v-if="image"
        :src="image"
        :alt="`${label} image`"
        class="nav-item-image"
        :class="{ 'nav-item-image-avatar': avatar }"
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
    </span>
    <span
      v-if="!slim"
      :class="{
        'nav-item-text': !icon && !image,
      }"
    >
      {{ label }}
    </span>
  </div>
</template>

<script>
export default {
  name: 'NavItemInner',

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
    avatar: {
      type: Boolean,
      default: false,
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
@import 'index.scss';
</style>
