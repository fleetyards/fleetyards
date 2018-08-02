<template>
  <div>
    <Panel
      v-if="model"
      :id="model.slug"
    >
      <div class="panel-heading">
        <h2 class="panel-title">
          <router-link :to="{ name: 'model', params: { slug: model.slug }}">
            <span v-if="customName">{{ customName }}</span>
            <span v-else>{{ countLabel }}{{ model.name }}</span>
          </router-link>
          <small
            v-tooltip.right="flagshipTooltip"
            v-if="vehicle && vehicle.flagship"
          >
            <i class="fa fa-certificate" />
          </small>
          <br >
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
        <router-link :to="{ name: 'model', params: { slug: model.slug }}">
          <img
            v-lazy="model.storeImage"
            alt="model Image"
          >
          <div
            v-tooltip="t('labels.model.purchased')"
            v-if="isMyShip"
            v-show="vehicle.purchased"
            class="purchased"
          >
            <i class="fal fa-check" />
          </div>
          <div
            v-tooltip="t('labels.model.onSale')"
            v-show="model.onSale"
            class="on-sale"
          >
            <i class="fal fa-dollar-sign" />
          </div>
        </router-link>
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
        <li class="list-group-item main-metrics">
          <div class="row metrics-block">
            <div
              v-if="model.focus"
              class="col-xs-6 col-sm-4"
            >
              <div class="metrics-label">{{ t('model.focus') }}:</div>
              <div
                v-tooltip="model.focus"
                class="metrics-value"
              >
                {{ model.focus }}
              </div>
            </div>
            <div
              v-if="model.minCrew || model.maxCrew"
              class="col-xs-6 col-sm-4"
            >
              <div class="metrics-label">{{ t('model.crew') }}:</div>
              <div class="metrics-value">
                <template v-if="model.minCrew === model.maxCrew">
                  {{ toNumber(model.minCrew, 'people') }}
                </template>
                <template v-else>
                  {{ toNumber(crew, 'people') }}
                </template>
              </div>
            </div>
            <div class="col-xs-12 col-sm-4">
              <div class="metrics-label">{{ t('model.speed') }}:</div>
              <div class="metrics-value">
                <template v-if="groundSpeeds || isGroundVehicle">
                  {{ toNumber(groundSpeeds, 'speed') }}
                  <br>
                </template>
                <template v-if="!isGroundVehicle">
                  {{ toNumber(speeds, 'speed') }}
                </template>
              </div>
            </div>
          </div>
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
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Panel from 'frontend/components/Panel'
import AddToHangar from 'frontend/components/AddToHangar'
import VehicleModal from 'frontend/partials/Vehicles/Modal'
import ModelBaseMetrics from 'frontend/partials/Models/BaseMetrics'

export default {
  components: {
    Panel,
    VehicleModal,
    AddToHangar,
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
    isGroundVehicle() {
      return this.model.classification === 'ground'
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
    crew() {
      let { minCrew, maxCrew } = this.model

      if (minCrew && minCrew <= 0) {
        minCrew = null
      }

      if (maxCrew && maxCrew <= 0) {
        maxCrew = null
      }

      return [minCrew, maxCrew].filter(item => item).join(' - ')
    },
    speeds() {
      let { scmSpeed, afterburnerSpeed } = this.model

      if (scmSpeed && scmSpeed <= 0) {
        scmSpeed = null
      }

      if (afterburnerSpeed && afterburnerSpeed <= 0) {
        afterburnerSpeed = null
      }

      return [scmSpeed, afterburnerSpeed].filter(item => item).join(' - ')
    },
    groundSpeeds() {
      let { groundSpeed, afterburnerGroundSpeed } = this.model

      if (groundSpeed && groundSpeed <= 0) {
        groundSpeed = null
      }

      if (afterburnerGroundSpeed && afterburnerGroundSpeed <= 0) {
        afterburnerGroundSpeed = null
      }

      return [groundSpeed, afterburnerGroundSpeed].filter(item => item).join(' - ')
    },
  },
  methods: {
    filterManufacturerQuery(manufacturer) {
      if (this.$route.name === 'models') {
        return { manufacturerSlugIn: [manufacturer] }
      }
      return { modelManufacturerSlugIn: [manufacturer] }
    },
    showEditModal() {
      this.$refs.vehicleModal.open()
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
