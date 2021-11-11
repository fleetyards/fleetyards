<template>
  <div class="row">
    <div class="col-12 fleetchart-wrapper">
      <div class="fleetchart-scroll-wrapper">
        <transition-group
          id="fleetchart"
          ref="fleetchart"
          name="fade-list"
          class="fleetchart"
          tag="div"
          :appear="true"
        >
          <FleetchartItem
            v-for="item in items"
            :key="item.id"
            :item="item"
            :scale="scale"
            :viewpoint="viewpoint"
            :show-label="labels"
            :show-status="showStatus"
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
    </div>

    <FleetchartItemContextMenu ref="contextMenu" data-test="context-menu" />
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
  @Prop({
    default() {
      return []
    },
  })
  items!: Vehicle[] | Model[]

  @Prop({ default: false }) myShip!: boolean

  @Prop({ default: 'side' }) viewpoint!: string

  @Prop({ default: false }) labels!: boolean

  @Prop({ default: 100 }) scale!: number

  showStatus: boolean = false

  selectedModel: Model | null = null

  selectedVehicle: Vehicle | null = null

  openContextMenu(event, item) {
    // @ts-ignore
    this.$refs.contextMenu?.open(item, this.myShip, event)
  }

  mounted() {
    this.showStatus = !!this.$route.query?.showStatus

    this.$comlink.$on('fleetchart-toggle-status', this.toggleStatus)
  }

  beforeDestroy() {
    this.$comlink.$off('fleetchart-toggle-status')
  }

  toggleStatus() {
    this.showStatus = !this.showStatus
  }
}
</script>
