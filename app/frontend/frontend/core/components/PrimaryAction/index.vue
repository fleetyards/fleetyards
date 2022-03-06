<template>
  <transition name="back-to-top-fade">
    <div
      v-tooltip="label"
      :aria-label="label"
      class="primary-action"
      @click="action"
    >
      <div class="primary-action-inner">
        <i :class="icon" />
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  name: 'PanelComponent',

  props: {
    action: {
      type: Function,
      required: true,
    },

    icon: {
      type: String,
      default: 'fal fa-plus',
    },

    label: {
      type: String,
      default: null,
    },
  },
}
</script>
