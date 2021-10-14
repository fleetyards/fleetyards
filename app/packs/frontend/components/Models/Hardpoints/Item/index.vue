<template>
  <div
    v-tooltip.left="tooltip"
    class="hardpoint-item-inner"
    :class="{ 'has-component': hardpoint.component }"
  >
    <div class="hardpoint-item-size">
      {{ $t('labels.hardpoint.size') }} {{ hardpoint.sizeLabel }}
    </div>
    <div
      v-if="hardpoint.itemSlots > 1 || showComponent"
      class="hardpoint-item-component"
    >
      <span v-if="hardpoint.itemSlots > 1" class="hardpoint-item-quantity">
        {{ hardpoint.itemSlots }}x
      </span>
      <template v-if="showComponent">
        {{ hardpoint.component.name }}
      </template>
      <template v-else-if="hardpoint.itemSlots > 1">
        TBD
      </template>
    </div>
    <div
      v-if="hardpoint.categoryLabel && showCategory"
      class="hardpoint-item-component"
    >
      <span v-if="hardpoint.itemSlots > 1" class="hardpoint-item-quantity">
        {{ hardpoint.itemSlots }}x
      </span>

      <img
        v-if="isMissileTurret"
        v-tooltip="hardpoint.categoryLabel"
        :src="turretIcon"
        class="hardpoint-type-icon-small"
        alt="icon-turrets"
      />
      <span v-else>
        {{ hardpoint.categoryLabel }}
      </span>
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
  /* eslint-enable global-require */
  get tooltip() {
    if (
      !this.showCategory &&
      this.hardpoint.categoryLabel !== this.hardpoint?.component?.name
    ) {
      return this.hardpoint.categoryLabel
    }

    return this.hardpoint.details
  }

  get isMissileTurret() {
    return this.hardpoint.category === 'missile_turret'
  }

  get showCategory() {
    return this.hardpoint.type !== 'turrets'
  }

  get showComponent() {
    return (
      this.hardpoint.component &&
      !['main_thrusters', 'maneuvering_thrusters'].includes(this.hardpoint.type)
    )
  }

  @Prop({ required: true }) hardpoint: Hardpoint

  /* eslint-disable global-require */
  turretIcon = require('images/hardpoints/turrets-dark.svg')
}
</script>
