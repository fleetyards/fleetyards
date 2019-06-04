<template>
  <div>
    <div
      v-for="category in categories"
      :key="category"
    >
      <div class="row compare-row compare-section">
        <div class="col-xs-12 compare-row-label">
          <div
            :class="{
              active: isVisible(category.toLowerCase())
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
          class="col-xs-12 compare-row-item"
        />
      </div>
      <b-collapse
        :id="category"
        :visible="isVisible(category.toLowerCase())"
      >
        <div class="row compare-row">
          <div class="col-xs-12 compare-row-label text-right metrics-label" />
          <div
            v-for="model in models"
            :key="`${model.slug}-${category}`"
            class="col-xs-6 text-center compare-row-item"
          >
            <div class="well">
              <HardpointCategory
                v-if="hardpointsForCategory(category, model.hardpoints).length > 0"
                :category="category"
                :hardpoints="hardpointsForCategory(category, model.hardpoints)"
                without-title
              />
            </div>
          </div>
        </div>
      </b-collapse>
    </div>
  </div>
</template>

<script>
import HardpointCategory from 'frontend/partials/Models/Hardpoints/Category'

export default {
  components: {
    HardpointCategory,
  },
  props: {
    models: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      rsiavionicVisible: this.models.length > 0,
      rsimodularVisible: this.models.length > 0,
      rsipropulsionVisible: this.models.length > 0,
      rsithrusterVisible: this.models.length > 0,
      rsiweaponVisible: this.models.length > 0,
      categories: ['RSIAvionic', 'RSIModular', 'RSIPropulsion', 'RSIThruster', 'RSIWeapon'],
    }
  },
  watch: {
    models() {
      this.rsiavionicVisible = this.models.length > 0
      this.rsimodularVisible = this.models.length > 0
      this.rsipropulsionVisible = this.models.length > 0
      this.rsithrusterVisible = this.models.length > 0
      this.rsiweaponVisible = this.models.length > 0
    },
  },
  methods: {
    isVisible(category) {
      return this[`${category}Visible`]
    },
    toggle(category) {
      this[`${category}Visible`] = !this[`${category}Visible`]
    },
    modularHardpoints(model) {
      return model.hardpoints.filter(item => item.categorySlug === 'modular')
    },
    ordnanceHardpoints(model) {
      return model.hardpoints.filter(item => item.categorySlug === 'ordnance')
    },
    propulsionHardpoints(model) {
      return model.hardpoints.filter(item => item.categorySlug === 'propulsion')
    },
    hardpointsForCategory(category, hardpoints) {
      return hardpoints.filter(hardpoint => hardpoint.class === category)
    },
  },
}
</script>
