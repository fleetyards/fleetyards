<template>
  <div class="row">
    <div class="col-xs-12">
      <h2 class="hardpoint-category-label">
        {{ t(`labels.hardpoint.categories.${category.toLowerCase()}`) }}
      </h2>
      <Panel>
        <div class="hardpoint-category">
          <div
            v-for="(hardpoints, type) in groupByType(hardpoints)"
            :key="type"
            class="hardpoint-type"
          >
            <div class="hardpoint-type-label">
              <img
                :src="icons[type]"
                class="hardpoint-type-icon"
              >
              {{ t(`labels.hardpoint.types.${type}`) }}
            </div>
            <HardpointIcon
              v-for="hardpoint in hardpoints"
              :key="hardpoint.id"
              :hardpoint="hardpoint"
              @click.native="openComponentModal(hardpoint)"
            />
          </div>
        </div>
      </Panel>
    </div>
    <Modal
      ref="componentModal"
      :title="(component && component.name) || ''"
    >
      <div
        v-if="component"
        class="col-xs-12 metrics-block"
      >
        <div class="row">
          <div class="col-xs-6">
            <div class="metrics-label">{{ t('component.size') }}:</div>
            <div class="metrics-value">{{ component.size }}</div>
            <div class="metrics-label">{{ t('component.manufacturer') }}:</div>
            <div
              class="metrics-value"
              v-html="component.manufacturer.name"
            />
          </div>
          <div
            v-if="selectedHardpoint.type === 'missiles'"
            class="col-xs-6"
          >
            <div class="metrics-label">{{ t('labels.metrics.missileOptions') }}:</div>
            <template v-for="n in parseInt(selectedHardpoint.size, 10)">
              <div
                :key="n"
                class="metrics-value"
              >
                {{ quantity(n) }} x {{ t('component.size') }} {{ n }}
              </div>
            </template>
          </div>
        </div>
      </div>
    </Modal>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Panel from 'frontend/components/Panel'
import Modal from 'frontend/components/Modal'
import HardpointIcon from '../Icon'

export default {
  components: {
    HardpointIcon,
    Panel,
    Modal,
  },
  mixins: [I18n],
  props: {
    hardpoints: {
      type: Array,
      required: true,
    },
    category: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedHardpoint: null,
      icons: {
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
      },
    }
  },
  computed: {
    component() {
      return this.selectedHardpoint && this.selectedHardpoint.component
    },
  },
  methods: {
    quantity(size) {
      if (!this.selectedHardpoint || !this.selectedHardpoint.component) {
        return null
      }

      let baseQuantity = this.selectedHardpoint.quantity
      if (this.selectedHardpoint.size !== this.selectedHardpoint.component.size) {
        baseQuantity = this.selectedHardpoint.quantity
          / ((this.selectedHardpoint.size - this.selectedHardpoint.component.size) * 2)
      }

      if (parseInt(this.selectedHardpoint.size, 10) === size) {
        return Math.floor(baseQuantity * this.selectedHardpoint.mounts)
      }

      return Math.floor(baseQuantity * ((this.selectedHardpoint.size - size) * 2)
        * this.selectedHardpoint.mounts)
    },
    groupByType(hardpoints) {
      return hardpoints.reduce((rv, x) => {
        const value = JSON.parse(JSON.stringify(rv))

        value[x.type] = rv[x.type] || []
        value[x.type].push(x)

        return value
      }, {})
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
  @import "./styles/index";
</style>
