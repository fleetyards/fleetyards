<template>
  <div ref="wrapper" class="panel-btn-dropdown">
    <Btn
      :size="size"
      :variant="variant"
      :active="visible"
      :inline="inline"
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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn/index.vue'

@Component<BtnDropdown>({
  components: {
    Btn,
  },
})
export default class BtnDropdown extends Vue {
  visible: boolean = false

  innerExpandLeft: boolean = false

  innerExpandTop: boolean = false

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'small', 'large'].indexOf(value) !== -1
    },
  })
  size!: string

  @Prop({
    default: 'default',
    validator(value) {
      return (
        ['default', 'transparent', 'link', 'danger', 'dropdown'].indexOf(
          value
        ) !== -1
      )
    },
  })
  variant!: string

  @Prop({ default: false }) expandLeft!: boolean

  @Prop({ default: false }) expandTop!: boolean

  @Prop({ default: false }) mobileBlock!: boolean

  @Prop({ default: false }) inline!: boolean

  created() {
    document.addEventListener('click', this.documentClick)
  }

  mounted() {
    this.innerExpandLeft = this.expandLeft
    this.innerExpandTop = this.expandTop
  }

  destroyed() {
    document.removeEventListener('click', this.documentClick)
  }

  toggle(event: MouseEvent) {
    const { target } = event
    // @ts-ignore
    const bounding = target.getBoundingClientRect()

    this.innerExpandLeft =
      this.expandLeft || window.innerWidth - bounding.left < 200
    this.innerExpandTop = window.innerHeight - bounding.top < 200

    this.visible = !this.visible
  }

  documentClick(event: MouseEvent) {
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
  }
}
</script>
