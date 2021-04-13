<template>
  <div
    v-tooltip.left="tooltip"
    class="hardpoint-item-inner"
    :class="{ 'has-component': hardpoint.component }"
  >
    <div class="hardpoint-item-size">
      {{ $t('labels.hardpoint.size') }} {{ hardpoint.sizeLabel }}
    </div>
    <div v-if="hardpoint.component" class="hardpoint-item-component">
      <span v-if="hardpoint.itemSlots > 1" class="hardpoint-item-quantity">
        {{ hardpoint.itemSlots }}x
      </span>
      {{ hardpoint.component.name }}
      <!-- <template v-if="hardpoint.type === 'missiles'">
        ({{ $t('labels.hardpoint.size') }} {{ hardpoint.component.size }})
      </template> -->
    </div>
    <div
      v-if="hardpoint.categoryLabel && showCategory"
      class="hardpoint-item-component"
    >
      <span v-if="hardpoint.itemSlots > 1" class="hardpoint-item-quantity">
        {{ hardpoint.itemSlots }}x
      </span>
      {{ hardpoint.categoryLabel }}
    </div>
    <div
      v-if="hardpoint.component && hardpoint.component.manufacturer"
      class="hardpoint-item-component-manufacturer"
      v-html="hardpoint.component.manufacturer.name"
    />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component<HardpointItem>({})
export default class HardpointItem extends Vue {
  @Prop({ required: true }) hardpoint: Hardpoint

  get uuid() {
    return this._uid
  }

  get tooltip() {
    if (!this.showCategory) {
      return this.hardpoint.categoryLabel
    }

    return this.hardpoint.details
  }

  get showCategory() {
    return this.hardpoint.type !== 'turrets'
  }
}
</script>
