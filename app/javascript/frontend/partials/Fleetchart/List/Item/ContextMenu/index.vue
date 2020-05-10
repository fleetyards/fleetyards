<template>
  <BtnGroup
    v-show="visible && model"
    ref="contextMenu"
    class="fleetchart-item-context-menu"
    :style="{ top: `${topPosition}px`, left: `${leftPosition}px` }"
  >
    <Btn
      v-if="model"
      variant="link"
      :to="{
        name: 'model',
        params: {
          slug: model.slug,
        },
      }"
      size="small"
      :inline="true"
    >
      {{ $t('actions.showMore') }}
    </Btn>

    <template v-if="vehicle && !vehicle.loaner">
      <Btn
        v-if="onEdit"
        :title="$t('actions.edit')"
        :aria-label="$t('actions.edit')"
        variant="link"
        size="small"
        data-test="vehicle-edit"
        :inline="true"
        @click.native="onEdit(vehicle)"
      >
        <i class="fa fa-pencil" />
      </Btn>

      <Btn
        v-if="upgradable && onAddons"
        :title="$t('labels.model.addons')"
        :aria-label="$t('labels.model.addons')"
        variant="link"
        size="small"
        data-test="vehicle-addons"
        :inline="true"
        @click.native="onAddons(vehicle)"
      >
        <span v-show="hasAddons">
          <i class="fa fa-plus-octagon" />
        </span>
        <span v-show="!hasAddons">
          <i class="far fa-plus-octagon" />
        </span>
      </Btn>
    </template>

    <AddToHangar
      v-else-if="model && !vehicle && !vehicle.loaner"
      :model="model"
      variant="menu"
    />
  </BtnGroup>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import BtnGroup from 'frontend/components/BtnGroup/index.vue'
import Btn from 'frontend/components/Btn/index.vue'
import AddToHangar from 'frontend/partials/Models/AddToHangar/index.vue'

@Component({
  components: {
    BtnGroup,
    Btn,
    AddToHangar,
  },
})
export default class FleetchartItemContextMenu extends Vue {
  visible: boolean = false

  @Prop() model!: Model

  @Prop() vehicle!: Vehicle

  @Prop() onEdit!: Function

  @Prop() onAddons!: Function

  startEvent: MouseEvent | null = null

  topPosition: number = 0

  leftPosition: number = 0

  get hasAddons() {
    return (
      this.vehicle &&
      (this.vehicle.modelModuleIds.length ||
        this.vehicle.modelUpgradeIds.length)
    )
  }

  get upgradable() {
    return this.hasAddons && (this.model.hasModules || this.model.hasUpgrades)
  }

  created() {
    document.addEventListener('click', this.documentClick)
  }

  destroyed() {
    document.removeEventListener('click', this.documentClick)
  }

  documentClick(event: MouseEvent) {
    if (!this.visible || !this.startEvent) return

    const { target: startElement } = this.startEvent
    const element = this.$refs.contextMenu
    const { target } = event

    if (
      target !== startElement &&
      target !== element &&
      // @ts-ignore
      !element.$el.contains(target)
    ) {
      this.close()
    }
  }

  async open(ev: MouseEvent) {
    if (
      this.visible &&
      this.startEvent &&
      this.startEvent.target === ev.target
    ) {
      this.visible = false
      return
    }

    this.startEvent = ev
    this.visible = true

    await this.$nextTick()

    this.repositionForOuterBounds(ev)
  }

  repositionForOuterBounds(ev) {
    const element = this.$refs.contextMenu
    // @ts-ignore
    if (window.innerWidth - ev.clientX < element.$el.offsetWidth) {
      // @ts-ignore
      this.leftPosition = ev.clientX - element.$el.offsetWidth
    } else {
      this.leftPosition = ev.clientX
    }

    // @ts-ignore
    if (window.innerHeight - ev.clientY < element.$el.offsetHeight) {
      // @ts-ignore
      this.topPosition = ev.clientY - element.$el.offsetHeight
    } else {
      this.topPosition = ev.clientY
    }
  }

  close() {
    this.visible = false
    this.startEvent = null
  }
}
</script>
