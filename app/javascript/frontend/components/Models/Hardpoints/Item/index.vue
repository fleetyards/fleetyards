<template>
  <div>
    <template v-if="isWeapon">
      <div
        v-for="index of hardpoint.mounts"
        :key="`${uuid}-${index}`"
        v-tooltip.left="hardpoint.details"
        class="hardpoint-item"
      >
        <div class="hardpoint-item-quantity">
          {{ hardpoint.quantity }}
          <span class="text-darken">x</span>
        </div>
        <div
          class="hardpoint-item-inner"
          :class="{ 'has-component': hardpoint.component }"
        >
          <div class="hardpoint-item-size">Size {{ rackSize || size }}</div>
          <div v-if="hardpoint.component" class="hardpoint-item-component">
            {{ hardpoint.component.name }}
          </div>
          <div
            v-if="hardpoint.component"
            class="hardpoint-item-component-manufacturer"
            v-html="hardpoint.component.manufacturer.name"
          />
        </div>
      </div>
    </template>
    <div v-else v-tooltip.left="hardpoint.details" class="hardpoint-item">
      <div class="hardpoint-item-quantity">
        {{ hardpoint.mounts }}
        <span class="text-darken">x</span>
      </div>
      <div
        class="hardpoint-item-inner"
        :class="{ 'has-component': hardpoint.component }"
      >
        <div class="hardpoint-item-size">Size {{ size }}</div>
        <div v-if="hardpoint.component" class="hardpoint-item-component">
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
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component<HardpointItem>({})
export default class HardpointItem extends Vue {
  @Prop({ required: true }) hardpoint: Hardpoint

  get isWeapon() {
    return this.hardpoint.class === 'RSIWeapon'
  }

  get uuid() {
    return this._uid
  }

  get rackSize() {
    if (
      this.hardpoint.type === 'missiles' &&
      this.hardpoint.size !== '' &&
      this.hardpoint.size !== '-'
    ) {
      return this.hardpoint.size
    }
    return null
  }

  get size() {
    if (this.hardpoint.size === '' || this.hardpoint.size === '-') {
      return 'TBD'
    }
    if (this.hardpoint.type === 'missiles') {
      if (this.hardpoint.component) {
        return this.hardpoint.component.size
      }
      return null
    }
    return this.hardpoint.size
  }
}
</script>
