<template>
  <div v-if="hardpoints.length" class="row">
    <div class="col-xs-12">
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
              <img :src="icons[type]" class="hardpoint-type-icon" />
              {{ $t(`labels.hardpoint.types.${type}`) }}
            </div>
            <HardpointIcon
              v-for="hardpoint in items"
              :key="hardpoint.id"
              :hardpoint="hardpoint"
              @click.native="openComponentModal(hardpoint)"
            />
          </div>
        </div>
      </Panel>
    </div>
    <Modal ref="componentModal" :title="(component && component.name) || ''">
      <div v-if="component" class="col-xs-12 metrics-block">
        <div class="row">
          <div class="col-xs-6">
            <div class="metrics-label">{{ $t('component.size') }}:</div>
            <div class="metrics-value">
              {{ component.size }}
            </div>
            <div class="metrics-label">{{ $t('component.manufacturer') }}:</div>
            <div class="metrics-value" v-html="component.manufacturer.name" />
          </div>
          <div v-if="selectedHardpoint.type === 'missiles'" class="col-xs-6">
            <div class="metrics-label">
              {{ $t('labels.hardpoint.rackSize') }}:
            </div>
            <div class="metrics-value">
              {{ selectedHardpoint.size }}
            </div>
          </div>
        </div>
      </div>
      <div class="clearfix" />
    </Modal>
  </div>
</template>

<script>
import Panel from 'frontend/components/Panel'
import Modal from 'frontend/components/Modal'
import HardpointIcon from '../Icon'

export default {
  components: {
    HardpointIcon,
    Panel,
    Modal,
  },
  props: {
    category: {
      type: String,
      required: true,
    },
    hardpoints: {
      type: Array,
      default: null,
    },
    withoutTitle: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      selectedHardpoint: null,
      icons: {
        /* eslint-disable global-require */
        radar: require('images/hardpoints/radar.svg').default,
        computers: require('images/hardpoints/computers.svg').default,
        power_plants: require('images/hardpoints/power_plants.svg').default,
        coolers: require('images/hardpoints/coolers.svg').default,
        shield_generators: require('images/hardpoints/shield_generators.svg')
          .default,
        fuel_intakes: require('images/hardpoints/fuel_intakes.svg').default,
        fuel_tanks: require('images/hardpoints/fuel_tanks.svg').default,
        quantum_drives: require('images/hardpoints/quantum_drives.svg').default,
        jump_modules: require('images/hardpoints/jump_modules.svg').default,
        quantum_fuel_tanks: require('images/hardpoints/quantum_fuel_tanks.svg')
          .default,
        main_thrusters: require('images/hardpoints/main_thrusters.svg').default,
        maneuvering_thrusters: require('images/hardpoints/maneuvering_thrusters.svg')
          .default,
        weapons: require('images/hardpoints/weapons.svg').default,
        turrets: require('images/hardpoints/turrets.svg').default,
        missiles: require('images/hardpoints/missiles.svg').default,
        utility_items: require('images/hardpoints/utility_items.svg').default,
        /* eslint-enable global-require */
      },
    }
  },
  computed: {
    component() {
      return this.selectedHardpoint && this.selectedHardpoint.component
    },
  },
  methods: {
    groupByType(hardpoints) {
      return this.groupBy(hardpoints, 'type')
    },
    openComponentModal(hardpoint) {
      if (!hardpoint.component) {
        return
      }
      this.selectedHardpoint = hardpoint
      this.$refs.componentModal.open()
    },
  },
}
</script>

<style lang="scss" scoped>
@import './styles/index';
</style>
