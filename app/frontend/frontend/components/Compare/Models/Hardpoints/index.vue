<template>
  <div>
    <div v-for="group in groups" :key="group">
      <div class="row compare-row compare-section">
        <div class="col-12 compare-row-label sticky-left">
          <div
            :class="{
              active: isVisible(group.toLowerCase()),
            }"
            class="text-right metrics-title"
            @click="toggle(group.toLowerCase())"
          >
            {{ $t(`labels.hardpoint.groups.${group.toLowerCase()}`) }}
            <i class="fa fa-chevron-right" />
          </div>
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-placeholder`"
          class="col-12 compare-row-item"
        />
      </div>
      <BCollapse :id="group" :visible="isVisible(group.toLowerCase())">
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          />
          <div
            v-for="model in models"
            :key="`${model.slug}-${group}`"
            class="col-6 compare-row-item"
          >
            <div class="well">
              <HardpointGroup
                v-if="hardpointsForGroup(group, model.hardpoints).length > 0"
                :group="group"
                :hardpoints="hardpointsForGroup(group, model.hardpoints)"
                without-title
              />
            </div>
          </div>
        </div>
      </BCollapse>
    </div>
  </div>
</template>

<script>
import { BCollapse } from 'bootstrap-vue'
import HardpointGroup from '@/frontend/components/Models/Hardpoints/Group/index.vue'

export default {
  name: 'ModelsCompareCategories',

  components: {
    BCollapse,
    HardpointGroup,
  },

  props: {
    models: {
      type: Array,
      required: true,
    },
  },

  data() {
    return {
      avionicVisible: false,
      groups: ['avionic', 'system', 'propulsion', 'thruster', 'weapon'],
      propulsionVisible: false,
      systemVisible: false,
      thrusterVisible: false,
      weaponVisible: false,
    }
  },

  watch: {
    models() {
      this.setupVisibles()
    },
  },

  mounted() {
    this.setupVisibles()
  },

  methods: {
    hardpointsForGroup(group, hardpoints) {
      return (hardpoints || []).filter((hardpoint) => hardpoint.group === group)
    },

    isVisible(group) {
      return this[`${group}Visible`]
    },

    setupVisibles() {
      this.avionicVisible = this.models.length > 0
      this.systemVisible = this.models.length > 0
      this.propulsionVisible = this.models.length > 0
      this.thrusterVisible = this.models.length > 0
      this.weaponVisible = this.models.length > 0
    },

    toggle(group) {
      this[`${group}Visible`] = !this[`${group}Visible`]
    },
  },
}
</script>
