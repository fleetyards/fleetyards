<template>
  <div
    v-tooltip.left="hardpoint.details"
    class="hardpoint-item-inner"
    :class="{ 'has-component': hardpoint.component }"
  >
    <div class="hardpoint-item-size">Size {{ size }}</div>
    <div v-if="hardpoint.component" class="hardpoint-item-component">
      <span v-if="hardpoint.quantity > 1" class="hardpoint-item-quantity">
        {{ hardpoint.quantity }}x
      </span>
      {{ hardpoint.component.name }}
    </div>
    <div v-if="hardpoint.categoryLabel" class="hardpoint-item-component">
      {{ hardpoint.categoryLabel }}
    </div>
    <div
      v-if="hardpoint.component"
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

  get size() {
    if (this.hardpoint.size) {
      return this.hardpoint.size
    }

    return 'TBD'
  }
}
</script>
