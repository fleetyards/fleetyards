<template>
  <Panel>
    <div class="teaser-panel item-panel">
      <LazyImage :src="image" class="teaser-panel-image" />
      <div class="teaser-panel-body">
        <h2 v-tooltip="component.name">
          {{ component.name }}
          <small v-if="component.manufacturer">
            <br />
            <span v-html="component.manufacturer.name" />
          </small>
        </h2>
        <AddToCartBtn :item="component" type="Component" class="add-to-cart" />
        <div v-if="showMetrics" class="metrics-list">
          <div v-if="component.size" class="metrics-item">
            <div class="metrics-label">{{ $t('commodityItem.size') }}:</div>
            <div class="metrics-value">
              {{ component.size }}
            </div>
          </div>
          <div v-if="component.grade" class="metrics-item">
            <div class="metrics-label">{{ $t('commodityItem.grade') }}:</div>
            <div class="metrics-value">
              {{ component.grade }}
            </div>
          </div>
          <div v-if="component.typeLabel" class="metrics-item">
            <div class="metrics-label">{{ $t('commodityItem.type') }}:</div>
            <div class="metrics-value">
              {{ component.typeLabel }}
            </div>
          </div>
          <div v-if="component.itemTypeLabel" class="metrics-item">
            <div class="metrics-label">{{ $t('commodityItem.itemType') }}:</div>
            <div class="metrics-value">
              {{ component.itemTypeLabel }}
            </div>
          </div>
          <div v-if="component.itemClassLabel" class="metrics-item">
            <div class="metrics-label">
              {{ $t('commodityItem.itemClass') }}:
            </div>
            <div class="metrics-value">
              {{ component.itemClassLabel }}
            </div>
          </div>
          <div v-if="component.extras" class="metrics-item">
            <div class="metrics-label">{{ $t('commodityItem.extras') }}:</div>
            <div class="metrics-value">
              {{ component.extras }}
            </div>
          </div>
        </div>
        <hr class="slim" />
        <ShopCommodityLocations :item="component" />
      </div>
    </div>
  </Panel>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Panel from 'frontend/core/components/Panel'
import LazyImage from 'frontend/core/components/LazyImage'
import Btn from 'frontend/core/components/Btn'
import AddToCartBtn from 'frontend/core/components/AppShoppingCart/AddToCartBtn'
import ShopCommodityLocations from 'frontend/components/ShopCommodities/Locations'

@Component<ComponentPanel>({
  components: {
    Panel,
    LazyImage,
    Btn,
    AddToCartBtn,
    ShopCommodityLocations,
  },
})
export default class ComponentPanel extends Vue {
  get image() {
    if (this.component.storeImageIsFallback) {
      return (
        this.component.manufacturer?.logo || this.component.storeImageMedium
      )
    }

    return this.component.storeImageMedium
  }

  @Prop({ required: true }) component!: Component

  @Prop({ default: true }) showMetrics!: boolean
}
</script>
