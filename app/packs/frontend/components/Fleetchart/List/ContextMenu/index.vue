<template>
  <BtnGroup
    v-show="visible && model"
    ref="contextMenu"
    class="fleetchart-item-context-menu"
    :style="{ top: `${topPosition}px`, left: `${leftPosition}px` }"
  >
    <Btn
      v-if="model"
      variant="dropdown"
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
      <VehicleContextMenu v-if="myShip" :vehicle="vehicle" :editable="myShip" />

      <Btn
        v-if="upgradable"
        :title="$t('labels.model.addons')"
        :aria-label="$t('labels.model.addons')"
        variant="dropdown"
        size="small"
        data-test="vehicle-addons"
        :inline="true"
        @click.native="openAddonsModal"
      >
        <span v-show="hasAddons">
          <i class="fa fa-plus-octagon" />
        </span>
        <span v-show="!hasAddons">
          <i class="far fa-plus-octagon" />
        </span>
      </Btn>
    </template>
  </BtnGroup>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import BtnGroup from 'frontend/core/components/BtnGroup/index.vue'
import Btn from 'frontend/core/components/Btn/index.vue'
import AddToHangar from 'frontend/components/Models/AddToHangar/index.vue'
import VehicleContextMenu from 'frontend/components/Vehicles/ContextMenu'

@Component({
  components: {
    BtnGroup,
    Btn,
    AddToHangar,
    VehicleContextMenu,
  },
})
export default class FleetchartItemContextMenu extends Vue {
  visible: boolean = false

  startEvent: MouseEvent | null = null

  topPosition: number = 0

  leftPosition: number = 0

  model: Model = null

  vehicle: Vehicle = null

  myShip: boolean = false

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

  async open(item: Vehicle | Model, myShip: boolean, ev: MouseEvent) {
    this.myShip = myShip

    if (item.model) {
      this.model = item.model
      this.vehicle = item
    } else {
      this.model = item
      this.vehicle = null
    }

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

  openEditModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/Modal'),
      props: {
        vehicle: this.vehicle,
      },
    })
  }

  openAddonsModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/AddonsModal'),
      props: {
        vehicle: this.vehicle,
        editable: this.editable,
      },
    })
  }

  close() {
    this.visible = false
    this.startEvent = null
    this.vehicle = null
    this.model = null
  }
}
</script>
