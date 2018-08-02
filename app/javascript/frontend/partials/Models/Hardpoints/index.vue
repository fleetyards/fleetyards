<template>
  <div class="row flex-row">
    <div class="col-xs-12 col-sm-6 col-md-4">
      <HardpointCategory
        v-for="category in ['RSIAvionic', 'RSIModular']"
        v-if="hardpointsForCategory(category).length > 0"
        :category="category"
        :key="category"
        :hardpoints="hardpointsForCategory(category)"
      />
    </div>
    <div class="col-xs-12 col-sm-6 col-md-4">
      <HardpointCategory
        v-for="category in ['RSIPropulsion', 'RSIThruster']"
        v-if="hardpointsForCategory(category).length > 0"
        :category="category"
        :key="category"
        :hardpoints="hardpointsForCategory(category)"
      />
    </div>
    <div class="col-xs-12 col-sm-6 col-md-4">
      <HardpointCategory
        v-for="category in ['RSIWeapon']"
        v-if="hardpointsForCategory(category).length > 0"
        :category="category"
        :key="category"
        :hardpoints="hardpointsForCategory(category)"
      />
      <div class="row">
        <div class="col-xs-12">
          <h2 class="hardpoint-category-label">Legend</h2>
          <Panel>
            <div class="hardpoint-category text-center hardpoint-legend">
              <img src="~images/hardpoints/legend.png" >
            </div>
          </Panel>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Panel from 'frontend/components/Panel'
import HardpointCategory from './Category'

export default {
  components: {
    HardpointCategory,
    Panel,
  },
  mixins: [I18n],
  props: {
    hardpoints: {
      type: Array,
      required: true,
    },
  },
  methods: {
    hardpointsForCategory(category) {
      return this.hardpoints.filter(hardpoint => hardpoint.class === category)
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
