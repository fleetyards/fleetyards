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
            <div
              v-for="(groupedItemsByCategory, category) in groupByCategory(
                items,
              )"
              :key="`${type}-${category}`"
              class="hardpoint-item"
            >
              <div class="hardpoint-item-quantity">
                {{ groupedItemsByCategory.length }}
                <span class="text-muted">x</span>
              </div>
              <div class="hardpoint-item-slots">
                <HardpointItem
                  v-for="(groupedItems, key) in groupByKey(
                    groupedItemsByCategory,
                  )"
                  :key="`${type}-${category}-${key}`"
                  :hardpoint="groupedItems[0]"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </Panel>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { groupBy, sortBy } from 'frontend/lib/Helpers'
import Panel from 'frontend/core/components/Panel'
import HardpointItem from '../Item'

@Component<HardpointGroup>({
  components: {
    HardpointItem,
    Panel,
  },
})
export default class HardpointGroup extends Vue {
  @Prop({ required: true }) group: HardpointGroup

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

  expanded(type) {
    return ['main_thrusters', 'weapons', 'turrets', 'missiles'].includes(type)
  }

  groupByType(hardpoints) {
    return groupBy(sortBy(hardpoints, 'type'), 'type')
  }

  groupByKey(hardpoints) {
    return groupBy(hardpoints, 'key')
  }

  groupByCategory(hardpoints) {
    console.log(groupBy(sortBy(hardpoints, 'category'), 'category'))
    return groupBy(sortBy(hardpoints, 'category'), 'category')
  }

  groupBySize(hardpoints) {
    return groupBy(sortBy(hardpoints, 'size'), 'size')
  }

  sortByCategory(hardponts) {
    return sortBy(hardponts, 'category')
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
