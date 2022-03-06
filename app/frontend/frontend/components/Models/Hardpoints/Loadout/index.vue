<template>
  <div v-if="loadout" class="hardpoint-item-loadout">
    <div class="hardpoint-item-loadout-quantity">
      <img
        :src="loadoutListIcon"
        class="hardpoint-item-loadout-quantity-icon"
        alt="hardpoint-list-icon"
      />
      {{ loadoutsCount }}
      <span class="text-muted">x</span>
    </div>
    <div
      class="hardpoint-item-inner"
      :class="{ 'has-component': loadout.component }"
    >
      <div v-if="showComponent" class="hardpoint-item-size">
        {{ $t('labels.hardpoint.size') }} {{ loadout.component.size }}
      </div>
      <div class="hardpoint-item-component">
        <template v-if="showComponent">
          {{ loadout.component.name }}
        </template>
        <template v-else>TBD</template>
      </div>
      <div
        v-if="loadout && loadout.component && loadout.component.manufacturer"
        class="hardpoint-item-component-manufacturer"
        v-html="loadout.component.manufacturer.name"
      />
    </div>
  </div>
</template>

<script>
import loadoutListIcon from '@/images/icons/loadout-list-icon.svg'

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
      loadoutListIcon: loadoutListIcon,
    }
  },

  computed: {
    loadout() {
      if (!this.hardpoint.loadouts.length) {
        return null
      }

      return this.hardpoint.loadouts[0]
    },

    loadoutsCount() {
      return this.hardpoint.loadouts.length
    },

    showComponent() {
      return this.loadout.component
    },
  },
}
</script>
