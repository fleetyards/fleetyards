<template>
  <div class="row">
    <div class="col-12 fleetchart-wrapper">
      <transition-group
        id="fleetchart"
        name="fade-list"
        class="row fleetchart"
        tag="div"
        appear
      >
        <FleetchartItem
          v-for="item in items"
          :key="item.id"
          :item="item"
          :scale="scale"
          @click.native="openContextMenu($event, item)"
        />

        <div key="made-by-the-community" class="fleetchart-download-image">
          <img
            :src="require('images/community-logo.png')"
            alt="made-by-the-community"
          />
        </div>
      </transition-group>
    </div>

    <FleetchartItemContextMenu
      ref="contextMenu"
      data-test="context-menu"
      :on-edit="onEdit"
      :on-addons="onAddons"
    />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import FleetchartItem from 'frontend/components/Fleetchart/List/Item/index.vue'
import FleetchartItemContextMenu from 'frontend/components/Fleetchart/List/ContextMenu/index.vue'

@Component({
  components: {
    FleetchartItem,
    FleetchartItemContextMenu,
  },
})
export default class FleetchartList extends Vue {
  @Prop() items!: Vehicle[] | Model[]

  @Prop() onEdit!: Function

  @Prop() onAddons!: Function

  @Prop() scale!: number

  selectedModel: Model | null = null

  selectedVehicle: Vehicle | null = null

  openContextMenu(event, item) {
    // @ts-ignore
    this.$refs.contextMenu.open(item, event)
  }
}
</script>
