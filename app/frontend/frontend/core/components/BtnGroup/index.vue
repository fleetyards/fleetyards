<template>
  <div :class="cssClasses">
    <slot />
  </div>
</template>

<script>
export default {
  name: 'BtnGroup',

  props: {
    inline: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    cssClasses() {
      return {
        'panel-btn-group': true,
        'panel-btn-group-inline': this.inline,
      }
    },
  },
}
</script>
