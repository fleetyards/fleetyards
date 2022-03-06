<template>
  <div ref="wrapper" class="panel-btn-dropdown" :class="cssClasses">
    <Btn
      :size="size"
      :variant="variant"
      :active="visible"
      :inline="true"
      :mobile-block="mobileBlock"
      @click.native="toggle"
    >
      <slot name="label">
        <i class="fas fa-ellipsis-v" />
      </slot>
    </Btn>
    <div
      ref="btnList"
      class="panel-btn-dropdown-list"
      :class="{
        visible,
        'expand-left': innerExpandLeft,
        'expand-top': innerExpandTop,
      }"
    >
      <slot />
    </div>
  </div>
</template>

<script>
import Btn from '@/frontend/core/components/Btn/index.vue'

export default {
  name: 'BtnDropdown',

  components: {
    Btn,
  },

  props: {
    expandLeft: {
      type: Boolean,
      default: false,
    },

    expandTop: {
      type: Boolean,
      default: false,
    },

    inline: {
      type: Boolean,
      default: false,
    },

    mobileBlock: {
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

    variant: {
      type: String,
      default: 'default',
      validator(value) {
        return (
          ['default', 'transparent', 'link', 'danger', 'dropdown'].indexOf(
            value
          ) !== -1
        )
      },
    },
  },

  data() {
    return {
      innerExpandLeft: false,
      innerExpandTop: false,
      visible: false,
    }
  },

  computed: {
    cssClasses() {
      return {
        'panel-btn-dropdown-inline': this.inline,
      }
    },
  },

  created() {
    document.addEventListener('click', this.documentClick)
  },

  destroyed() {
    document.removeEventListener('click', this.documentClick)
  },

  mounted() {
    this.innerExpandLeft = this.expandLeft
    this.innerExpandTop = this.expandTop
  },

  methods: {
    documentClick(event) {
      if (!this.visible) return

      const { wrapper, btnList } = this.$refs
      const { target } = event

      // @ts-ignore
      if (
        target !== wrapper &&
        (!wrapper.contains(target) || btnList.contains(target))
      ) {
        this.visible = false
      }
    },

    toggle(event) {
      const { target } = event
      // @ts-ignore
      const bounding = target.getBoundingClientRect()

      this.innerExpandLeft =
        this.expandLeft || window.innerWidth - bounding.left < 200
      this.innerExpandTop = window.innerHeight - bounding.top < 200

      this.visible = !this.visible
    },
  },
}
</script>
