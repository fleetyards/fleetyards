<template>
  <div ref="wrapper" class="panel-btn-dropdown">
    <Btn
      :size="size"
      :active="visible"
      :mobile-block="mobileBlock"
      @click.native="toggle"
    >
      <slot name="label">
        <i class="fas fa-ellipsis-v" />
      </slot>
    </Btn>
    <div
      class="panel-btn-dropdown-list"
      :class="{ visible, 'expand-left': expandLeft, 'expand-top': expandTop }"
    >
      <slot />
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/components/Btn/index.vue'

@Component({
  components: {
    Btn,
  },
})
export default class BtnDropdown extends Vue {
  visible: boolean = false

  expandLeft: boolean = false

  expandTop: boolean = false

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'small', 'large'].indexOf(value) !== -1
    },
  })
  size!: string

  @Prop({ default: false }) mobileBlock!: boolean

  created() {
    document.addEventListener('click', this.documentClick)
  }

  destroyed() {
    document.removeEventListener('click', this.documentClick)
  }

  toggle(event: MouseEvent) {
    const { target } = event
    // @ts-ignore
    const bounding = target.getBoundingClientRect()

    this.expandLeft = window.innerWidth - bounding.left < 200
    this.expandTop = window.innerHeight - bounding.top < 200

    this.visible = !this.visible
  }

  documentClick(event: MouseEvent) {
    if (!this.visible) return

    const { wrapper } = this.$refs
    const { target } = event

    // @ts-ignore
    if (target !== wrapper && !wrapper.contains(target)) {
      this.visible = false
    }
  }
}
</script>
