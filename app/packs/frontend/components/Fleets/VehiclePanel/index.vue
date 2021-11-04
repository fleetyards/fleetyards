<template>
  <div>
    <Panel
      v-if="model"
      :id="id"
      class="model-panel"
      :class="`model-panel-${model.slug}`"
    >
      <div class="panel-heading">
        <h2 class="panel-title">
          <router-link
            :to="{
              name: 'model',
              params: {
                slug: model.slug,
              },
            }"
          >
            <span v-if="customName">{{ customName }}</span>
            <span v-else>{{ countLabel }}{{ modelName }}</span>
          </router-link>

          <transition name="fade" appear>
            <small v-if="fleetVehicle.serial">
              <span v-if="fleetVehicle.serial" class="serial">
                {{ fleetVehicle.serial }}
              </span>
            </small>
          </transition>

          <br />

          <small>
            <router-link
              :to="{
                query: {
                  q: filterManufacturerQuery(model.manufacturer.slug),
                },
              }"
              v-html="model.manufacturer.name"
            />
            <template v-if="customName">
              {{ modelName }}
            </template>
          </small>
        </h2>
      </div>
      <div
        :class="{
          'no-details': !details,
        }"
        class="panel-image text-center"
      >
        <LazyImage
          :to="{ name: 'model', params: { slug: model.slug } }"
          :aria-label="model.name"
          :src="storeImage"
          :alt="model.name"
          class="image"
        >
          <div
            v-if="fleetVehicle.loaner"
            v-tooltip="$t('labels.vehicle.loaner')"
            class="loaner-label"
          >
            <i class="fal fa-exchange" />
          </div>
          <div
            v-show="model.onSale"
            v-tooltip="$t('labels.model.onSale')"
            class="on-sale"
          >
            <i class="fal fa-dollar-sign" />
          </div>
        </LazyImage>
        <VehicleOwner
          v-if="(fleetVehicle.username || vehicles.length) && showOwner"
          :owner="fleetVehicle.username"
          :vehicles="vehicles"
        />
      </div>
      <PanelDetails
        :key="`details-${model.slug}-${uuid}-wrapper`"
        :visible="details"
      >
        <div class="production-status">
          <strong class="text-uppercase">
            <template v-if="model.productionStatus">
              {{
                $t(`labels.model.productionStatus.${model.productionStatus}`)
              }}
            </template>
            <template v-else>
              {{ $t(`labels.not-available`) }}
            </template>
          </strong>
        </div>
        <ModelPanelMetrics :model="model" />
      </PanelDetails>
    </Panel>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Panel from 'frontend/core/components/Panel'
import PanelDetails from 'frontend/core/components/Panel/PanelDetails'
import LazyImage from 'frontend/core/components/LazyImage'
import AddToHangar from 'frontend/components/Models/AddToHangar'
import VehicleOwner from 'frontend/components/Vehicles/OwnerLabel'
import ModelPanelMetrics from 'frontend/components/Models/PanelMetrics'

@Component<FleetVehiclePanel>({
  components: {
    Panel,
    PanelDetails,
    LazyImage,
    AddToHangar,
    VehicleOwner,
    ModelPanelMetrics,
  },
})
export default class FleetVehiclePanel extends Vue {
  get uuid() {
    return this._uid
  }

  get storeImage() {
    if (this.fleetVehicle.paint) {
      return this.fleetVehicle.paint.storeImageMedium
    }

    if (this.fleetVehicle.upgrade) {
      return this.fleetVehicle.upgrade.storeImageMedium
    }

    return this.model.storeImageMedium
  }

  get modelName() {
    if (!this.fleetVehicle.model) {
      return this.fleetVehicle.name
    }

    return this.fleetVehicle.model.name
  }

  get model() {
    if (this.fleetVehicle.model) {
      return this.fleetVehicle.model
    }

    return this.fleetVehicle
  }

  get id() {
    if (this.fleetVehicle) {
      return this.fleetVehicle.id
    }

    return this.model.slug
  }

  get customName() {
    if (this.fleetVehicle.model && this.fleetVehicle.name) {
      return this.fleetVehicle.name
    }

    return null
  }

  get vehicles() {
    if (!this.fleetVehicle.vehicles) {
      return []
    }

    return this.fleetVehicle.vehicles
  }

  get countLabel() {
    if (!this.vehicles.length) {
      return ''
    }
    return `${this.vehicles.length}x `
  }

  @Prop({ required: true }) fleetVehicle: Vehicle | Model | null

  @Prop({ default: false }) details: boolean

  @Prop({ default: true }) showOwner: boolean

  filterManufacturerQuery(manufacturer) {
    return { manufacturerIn: [manufacturer] }
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
