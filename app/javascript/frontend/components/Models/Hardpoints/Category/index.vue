<template>
  <div v-if="hardpoints.length" class="row">
    <div class="col-12">
      <h2 v-if="!withoutTitle" class="hardpoint-category-label">
        {{ $t(`labels.hardpoint.categories.${category.toLowerCase()}`) }}
      </h2>
      <Panel>
        <div class="hardpoint-category">
          <div
            v-for="(items, type) in groupByType(hardpoints)"
            :key="type"
            class="hardpoint-type"
          >
            <div class="hardpoint-type-label">
              <img
                :src="icons[type]"
                class="hardpoint-type-icon"
                :alt="`icon-${type}`"
              />
              {{ $t(`labels.hardpoint.types.${type}`) }}
            </div>
            <div class="hardpoint-items">
              <HardpointItem
                v-for="hardpoint in items"
                :key="hardpoint.id"
                :hardpoint="hardpoint"
              />
            </div>
          </div>
        </div>
      </Panel>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { groupBy } from 'frontend/lib/Helpers'
import Panel from 'frontend/core/components/Panel'
import HardpointItem from '../Item'

@Component<HardpointCategory>({
  components: {
    HardpointItem,
    Panel,
  },
})
export default class HardpointCategory extends Vue {
  @Prop({ required: true }) category: HardpointCategory

  @Prop({ required: true }) hardpoints: Hardpoint[]

  @Prop({ default: false }) withoutTitle: boolean

  icons = {
    /* eslint-disable global-require */
    radar: require('images/hardpoints/radar.svg'),
    computers: require('images/hardpoints/computers.svg'),
    power_plants: require('images/hardpoints/power_plants.svg'),
    coolers: require('images/hardpoints/coolers.svg'),
    shield_generators: require('images/hardpoints/shield_generators.svg'),
    fuel_intakes: require('images/hardpoints/fuel_intakes.svg'),
    fuel_tanks: require('images/hardpoints/fuel_tanks.svg'),
    quantum_drives: require('images/hardpoints/quantum_drives.svg'),
    jump_modules: require('images/hardpoints/jump_modules.svg'),
    quantum_fuel_tanks: require('images/hardpoints/quantum_fuel_tanks.svg'),
    main_thrusters: require('images/hardpoints/main_thrusters.svg'),
    maneuvering_thrusters: require('images/hardpoints/maneuvering_thrusters.svg'),
    weapons: require('images/hardpoints/weapons.svg'),
    turrets: require('images/hardpoints/turrets.svg'),
    missiles: require('images/hardpoints/missiles.svg'),
    utility_items: require('images/hardpoints/utility_items.svg'),
    /* eslint-enable global-require */
  }

  groupByType(hardpoints) {
    return groupBy(hardpoints, 'type')
  }

  openComponentModal(hardpoint) {
    if (!hardpoint.component) {
      return
    }

    this.$comlink.$emit('open-modal', {
      component: () =>
        import('frontend/components/Models/Hardpoints/ComponentModal'),
      props: {
        hardpoint,
      },
    })
  }
}
</script>
