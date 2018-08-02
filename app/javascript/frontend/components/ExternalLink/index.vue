<template>
  <a
    :class="{
      'panel-btn-clear': clear,
      'panel-btn-clean': clean,
      'panel-btn-small': small,
      'panel-btn-large': large,
      'panel-btn-block': block,
      'panel-btn-mobile-block': mobileBlock,
    }"
    :href="url"
    target="_blank"
    class="panel-btn"
  >
    <div class="panel-btn-border panel-btn-border-top">
      <div class="panel-btn-border-bg" />
    </div>
    <div class="panel-btn-inner">
      <slot />
    </div>
    <div class="panel-btn-border panel-btn-border-bottom">
      <div class="panel-btn-border-bg" />
    </div>
  </a>
</template>

<script>
export default {
  props: {
    url: {
      type: String,
      required: true,
    },
    clear: {
      type: Boolean,
      default: false,
    },
    clean: {
      type: Boolean,
      default: false,
    },
    large: {
      type: Boolean,
      default: false,
    },
    small: {
      type: Boolean,
      default: false,
    },
    block: {
      type: Boolean,
      default: false,
    },
    mobileBlock: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
