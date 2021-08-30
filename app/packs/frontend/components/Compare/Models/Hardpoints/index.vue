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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import { BCollapse } from 'bootstrap-vue'
import HardpointGroup from 'frontend/components/Models/Hardpoints/Group'

@Component<ModelsCompareCategories>({
  components: {
    BCollapse,
    HardpointGroup,
  },
})
export default class ModelsCompareCategories extends Vue {
  @Prop({ required: true }) models!: Model[]

  groups = ['avionic', 'system', 'propulsion', 'thruster', 'weapon']

  avionicVisible: boolean = false

  systemVisible: boolean = false

  propulsionVisible: boolean = false

  thrusterVisible: boolean = false

  weaponVisible: boolean = false

  @Watch('models')
  onModelsChange() {
    this.setupVisibles()
  }

  mounted() {
    this.setupVisibles()
  }

  setupVisibles() {
    this.avionicVisible = this.models.length > 0
    this.systemVisible = this.models.length > 0
    this.propulsionVisible = this.models.length > 0
    this.thrusterVisible = this.models.length > 0
    this.weaponVisible = this.models.length > 0
  }

  isVisible(group) {
    return this[`${group}Visible`]
  }

  toggle(group) {
    this[`${group}Visible`] = !this[`${group}Visible`]
  }

  hardpointsForGroup(group, hardpoints) {
    return (hardpoints || []).filter(hardpoint => hardpoint.group === group)
  }
}
</script>
