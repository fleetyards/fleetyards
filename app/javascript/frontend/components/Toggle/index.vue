<template>
  <div class="panel-btn-toggle">
    <Btn
      :size="size"
      :active="activeLeft"
      @click.native="toggle"
    >
      <slot name="left" />
    </Btn>
    <Btn
      :size="size"
      :active="activeRight"
      @click.native="toggle"
    >
      <slot name="right" />
    </Btn>
  </div>
</template>

<script>
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Btn,
  },

  props: {
    activeLeft: {
      type: Boolean,
      default: true,
    },

    activeRight: {
      type: Boolean,
      default: false,
    },

    size: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },
  },

  methods: {
    toggle() {
      if (this.activeRight) {
        this.$emit('toggle:left')
      } else {
        this.$emit('toggle:right')
      }
    },
  },
}
</script>
