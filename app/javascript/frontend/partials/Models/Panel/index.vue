<template>
  <div>
    <Panel
      v-if="model"
      :id="model.slug"
    >
      <div class="panel-heading">
        <h2 class="panel-title">
          <router-link :to="{ name: 'model', params: { slug: model.slug }}">
            <span v-if="customName">
              {{ customName }}
            </span>
            <span v-else>
              {{ countLabel }}{{ model.name }}
            </span>
          </router-link>
          <small
            v-if="vehicle && vehicle.flagship"
            v-tooltip.right="flagshipTooltip"
          >
            <i class="fa fa-certificate" />
          </small>
          <br>
          <small v-if="customName">
            <router-link
              :to="{ query: { q: filterManufacturerQuery(model.manufacturer.slug) }}"
              v-html="model.manufacturer.name"
            />
            {{ model.name }}
          </small>
          <small v-else>
            <router-link
              :to="{ query: { q: filterManufacturerQuery(model.manufacturer.slug) }}"
              v-html="model.manufacturer.name"
            />
          </small>
          <a
            v-if="isMyShip"
            :title="t('actions.edit')"
            :aria-label="t('actions.edit')"
            class="btn btn-link panel-edit-button"
            @click="showEditModal"
          >
            <i class="fa fa-pencil" />
          </a>
          <AddToHangar
            v-else
            :model="model"
            class="panel-add-to-hangar-button"
            clean
            small
          />
        </h2>
      </div>
      <div class="panel-image text-center">
        <router-link
          :key="model.storeImageMedium"
          v-lazy:background-image="model.storeImageMedium"
          :to="{ name: 'model', params: { slug: model.slug }}"
          :aria-label="model.name"
        >
          <div
            v-if="isMyShip"
            v-show="vehicle.purchased"
            v-tooltip="t('labels.model.purchased')"
            class="purchased"
          >
            <i class="fal fa-check" />
          </div>
          <div
            v-show="model.onSale"
            v-tooltip="t('labels.model.onSale')"
            class="on-sale"
          >
            <i class="fal fa-dollar-sign" />
          </div>
        </router-link>
        <div
          v-if="upgradable"
          v-tooltip="t('labels.model.addons')"
          class="addons"
          :class="{
            selected: (vehicle.modelModuleIds.length || vehicle.modelUpgradeIds.length)
          }"
          @click="showAddonsModal"
        >
          <i
            class="fa-plus-octagon"
            :class="{
              far: !(vehicle.modelModuleIds.length || vehicle.modelUpgradeIds.length),
              fa: (vehicle.modelModuleIds.length || vehicle.modelUpgradeIds.length),
            }"
          />
        </div>
      </div>
      <div
        v-if="details"
        class="production-status"
      >
        <strong class="text-uppercase">
          <template v-if="model.productionStatus">
            {{ t(`labels.model.productionStatus.${model.productionStatus}`) }}
          </template>
          <template v-else>
            {{ t(`labels.not-available`) }}
          </template>
        </strong>
      </div>
      <ul
        v-if="details"
        class="list-group"
      >
        <li class="list-group-item">
          <ModelTopMetrics :model="model" />
        </li>
        <li class="list-group-item">
          <ModelBaseMetrics :model="model" />
        </li>
      </ul>
    </Panel>
    <VehicleModal
      v-if="isMyShip"
      ref="vehicleModal"
      :vehicle="vehicle"
      :hangar-groups="hangarGroups"
    />
    <AddonsModal
      v-if="upgradable"
      ref="addonsModal"
      :vehicle="vehicle"
    />
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Panel from 'frontend/components/Panel'
import AddToHangar from 'frontend/components/AddToHangar'
import VehicleModal from 'frontend/partials/Vehicles/Modal'
import AddonsModal from 'frontend/partials/Vehicles/AddonsModal'
import ModelTopMetrics from 'frontend/partials/Models/TopMetrics'
import ModelBaseMetrics from 'frontend/partials/Models/BaseMetrics'

export default {
  components: {
    Panel,
    VehicleModal,
    AddonsModal,
    AddToHangar,
    ModelTopMetrics,
    ModelBaseMetrics,
  },
  mixins: [I18n],
  props: {
    model: {
      type: Object,
      required: true,
    },
    vehicle: {
      type: Object,
      default() {
        return {}
      },
    },
    details: {
      type: Boolean,
      default: false,
    },
    count: {
      type: Number,
      default: null,
    },
    hangarGroups: {
      type: Array,
      default() {
        return []
      },
    },
  },
  computed: {
    customName() {
      if (this.vehicle && this.vehicle.name && (this.$route.name !== 'hangar-public' || this.vehicle.nameVisible)) {
        return this.vehicle.name
      }
      return null
    },
    countLabel() {
      if (!this.count) {
        return ''
      }
      return `${this.count}x `
    },
    flagshipTooltip() {
      if (!this.vehicle) {
        return ''
      }
      if (this.$route.name === 'hangar') {
        return this.t('labels.yourFlagship')
      }
      return this.t('labels.flagship')
    },
    isMyShip() {
      return this.vehicle && this.$route.name === 'hangar'
    },
    upgradable() {
      return this.isMyShip && (this.model.hasModules || this.model.hasUpgrades)
    },
  },
  methods: {
    filterManufacturerQuery(manufacturer) {
      return { manufacturerIn: [manufacturer] }
    },
    showEditModal() {
      this.$refs.vehicleModal.open()
    },
    showAddonsModal(ev) {
      ev.preventDefault()
      this.$refs.addonsModal.open()
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
