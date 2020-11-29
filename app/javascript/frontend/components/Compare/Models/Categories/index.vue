<template>
  <div>
    <div v-for="category in categories" :key="category">
      <div class="row compare-row compare-section">
        <div class="col-12 compare-row-label sticky-left">
          <div
            :class="{
              active: isVisible(category.toLowerCase()),
            }"
            class="text-right metrics-title"
            @click="toggle(category.toLowerCase())"
          >
            {{ $t(`labels.hardpoint.categories.${category.toLowerCase()}`) }}
            <i class="fa fa-chevron-right" />
          </div>
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-placeholder`"
          class="col-12 compare-row-item"
        />
      </div>
      <BCollapse :id="category" :visible="isVisible(category.toLowerCase())">
        <div class="row compare-row">
          <div
            class="col-12 compare-row-label text-right metrics-label sticky-left"
          />
          <div
            v-for="model in models"
            :key="`${model.slug}-${category}`"
            class="col-6 compare-row-item"
          >
            <div class="well">
              <HardpointCategory
                v-if="
                  hardpointsForCategory(category, model.hardpoints).length > 0
                "
                :category="category"
                :hardpoints="hardpointsForCategory(category, model.hardpoints)"
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
import HardpointCategory from 'frontend/components/Models/Hardpoints/Category'

@Component<ModelsCompareCategories>({
  components: {
    BCollapse,
    HardpointCategory,
  },
})
export default class ModelsCompareCategories extends Vue {
  @Prop({ required: true }) models!: Model[]

  categories = [
    'RSIAvionic',
    'RSIModular',
    'RSIPropulsion',
    'RSIThruster',
    'RSIWeapon',
  ]

  rsiavionicVisible: boolean = false

  rsimodularVisible: boolean = false

  rsipropulsionVisible: boolean = false

  rsithrusterVisible: boolean = false

  rsiweaponVisible: boolean = false

  @Watch('models')
  onModelsChange() {
    this.setupVisibles()
  }

  mounted() {
    this.setupVisibles()
  }

  setupVisibles() {
    this.rsiavionicVisible = this.models.length > 0
    this.rsimodularVisible = this.models.length > 0
    this.rsipropulsionVisible = this.models.length > 0
    this.rsithrusterVisible = this.models.length > 0
    this.rsiweaponVisible = this.models.length > 0
  }

  isVisible(category) {
    return this[`${category}Visible`]
  }

  toggle(category) {
    this[`${category}Visible`] = !this[`${category}Visible`]
  }

  modularHardpoints(model) {
    return model.hardpoints.filter(item => item.categorySlug === 'modular')
  }

  ordnanceHardpoints(model) {
    return model.hardpoints.filter(item => item.categorySlug === 'ordnance')
  }

  propulsionHardpoints(model) {
    return model.hardpoints.filter(item => item.categorySlug === 'propulsion')
  }

  hardpointsForCategory(category, hardpoints) {
    return hardpoints.filter(hardpoint => hardpoint.class === category)
  }
}
</script>
