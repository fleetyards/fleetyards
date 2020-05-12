<template>
  <div class="row">
    <div class="col-xs-12 fleetchart-wrapper">
      <transition-group
        id="fleetchart"
        name="fade-list"
        class="flex-row fleetchart"
        tag="div"
        appear
      >
        <FleetchartItem
          v-for="item in items"
          :key="item.id"
          :model="modelFrom(item)"
          :scale="scale"
          @click.native="openContextMenu($event, item)"
        />
      </transition-group>
    </div>
    <FleetchartItemContextMenu
      ref="contextMenu"
      :on-edit="onEdit"
      :on-addons="onAddons"
      :vehicle="selectedVehicle"
      :model="selectedModel"
    />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import FleetchartItem from 'frontend/partials/Fleetchart/List/Item/index.vue'
import FleetchartItemContextMenu from 'frontend/partials/Fleetchart/List/Item/ContextMenu/index.vue'

@Component({
  components: {
    FleetchartItem,
    FleetchartItemContextMenu,
  },
})
export default class FleetchartList extends Vue {
  @Prop() items!: Vehicle | Model

  @Prop() onEdit!: Function

  @Prop() onAddons!: Function

  @Prop() scale!: number

  selectedModel: Model | null = null

  selectedVehicle: Vehicle | null = null

  modelFrom(item: Vehicle | Model): Model {
    if ((item as Vehicle).model) {
      return (item as Vehicle).model
    }

    return item as Model
  }

  openContextMenu(event, item) {
    this.selectedModel = this.modelFrom(item)
    if (this.selectedModel !== item) {
      this.selectedVehicle = item
    }

    // @ts-ignore
    this.$refs.contextMenu.open(event)
  }
}
</script>
