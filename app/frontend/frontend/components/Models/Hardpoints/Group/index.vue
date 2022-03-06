<template>
  <div v-if="hardpoints.length" class="hardpoint-group">
    <h2 v-if="!withoutTitle" class="hardpoint-group-label">
      {{ $t(`labels.hardpoint.groups.${group.toLowerCase()}`) }}
    </h2>
    <Panel>
      <div class="hardpoint-group-inner">
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
            <HardpointItems
              v-for="(groupedItems, key) in groupByKey(items)"
              :key="`${type}-${key}`"
              :hardpoints="groupedItems"
            />
          </div>
        </div>
      </div>
    </Panel>
  </div>
</template>

<script>
import { groupBy, sortBy } from '@/frontend/lib/Helpers'
import Panel from '@/frontend/core/components/Panel/index.vue'
import HardpointItems from '../Items/index.vue'
import computersIcon from '@/images/hardpoints/computers.svg'
import coolersIcon from '@/images/hardpoints/coolers.svg'
import fuelIntakesIcon from '@/images/hardpoints/fuel_intakes.svg'
import fuelTanksIcon from '@/images/hardpoints/fuel_tanks.svg'
import jumpModulesIcon from '@/images/hardpoints/jump_modules.svg'
import mainThrustersIcon from '@/images/hardpoints/main_thrusters.svg'
import maneuveringThrustersIcon from '@/images/hardpoints/maneuvering_thrusters.svg'
import missilesIcon from '@/images/hardpoints/missiles.svg'
import powerPlantsIcon from '@/images/hardpoints/power_plants.svg'
import quantumDrivesIcon from '@/images/hardpoints/quantum_drives.svg'
import quantumFuelTanksIcon from '@/images/hardpoints/quantum_fuel_tanks.svg'
import radarIcon from '@/images/hardpoints/radar.svg'
import shieldGeneratorsIcon from '@/images/hardpoints/shield_generators.svg'
import turretsIcon from '@/images/hardpoints/turrets.svg'
import utilityItemsIcon from '@/images/hardpoints/utility_items.svg'
import weaponsIcon from '@/images/hardpoints/weapons.svg'

export default {
  name: 'HardpointGroup',

  components: {
    HardpointItems,
    Panel,
  },

  props: {
    group: {
      type: String,
      required: true,
    },

    hardpoints: {
      type: Array,
      required: true,
    },

    withoutTitle: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      icons: {
        computers: computersIcon,
        coolers: coolersIcon,
        fuel_intakes: fuelIntakesIcon,
        fuel_tanks: fuelTanksIcon,
        jump_modules: jumpModulesIcon,
        main_thrusters: mainThrustersIcon,
        maneuvering_thrusters: maneuveringThrustersIcon,
        missiles: missilesIcon,
        power_plants: powerPlantsIcon,
        quantum_drives: quantumDrivesIcon,
        quantum_fuel_tanks: quantumFuelTanksIcon,
        radar: radarIcon,
        shield_generators: shieldGeneratorsIcon,
        turrets: turretsIcon,
        utility_items: utilityItemsIcon,
        weapons: weaponsIcon,
      },
    }
  },

  methods: {
    groupByKey(hardpoints) {
      return groupBy(sortBy(hardpoints, 'category'), 'key')
    },

    groupByType(hardpoints) {
      return groupBy(sortBy(hardpoints, 'type'), 'type')
    },

    grouped(type) {
      return ['main_thrusters', 'maneuvering_thrusters'].includes(type)
    },

    openComponentModal(hardpoint) {
      if (!hardpoint.component) {
        return
      }

      this.$comlink.$emit('open-modal', {
        component: () =>
          import(
            '@/frontend/components/Models/Hardpoints/ComponentModal/index.vue'
          ),
        props: {
          hardpoint,
        },
      })
    },
  },
}
</script>
