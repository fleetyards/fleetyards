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
      <template v-else-if="hardpoint.itemSlots > 1">TBD</template>
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

<script>
import turretIcon from '@/images/hardpoints/turrets-dark.svg'

export default {
  name: 'HardpointItem',

  props: {
    hardpoint: {
      required: true,
      type: Object,
    },
  },

  data() {
    return {
      turretIcon: turretIcon,
    }
  },

  computed: {
    isMissileTurret() {
      return this.hardpoint.category === 'missile_turret'
    },

    showCategory() {
      return this.hardpoint.type !== 'turrets'
    },

    showComponent() {
      return (
        this.hardpoint.component &&
        !['main_thrusters', 'maneuvering_thrusters'].includes(
          this.hardpoint.type
        )
      )
    },

    tooltip() {
      if (
        !this.showCategory &&
        this.hardpoint.categoryLabel !== this.hardpoint?.component?.name
      ) {
        return this.hardpoint.categoryLabel
      }

      return this.hardpoint.details
    },
  },
}
</script>
