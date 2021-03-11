<template>
  <div>
    <Panel
      v-if="model"
      :id="id"
      class="model-panel"
      :class="`model-panel-${model.slug}`"
      :highlight="(vehicle && vehicle.flagship) || highlight"
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
            <small v-if="vehicle && vehicle.serial">
              <span v-if="vehicle.serial" class="serial">
                {{ vehicle.serial }}
              </span>
            </small>
          </transition>

          <transition name="fade" appear>
            <small
              v-if="vehicle && vehicle.flagship"
              v-tooltip.right="flagshipTooltip"
            >
              <i class="fad fa-certificate flagship-icon" />
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
        <BtnDropdown
          v-if="vehicle && editable && !vehicle.loaner"
          size="small"
          variant="link"
          class="panel-edit-menu"
          data-test="vehicle-menu"
          :expand-left="true"
        >
          <Btn
            :aria-label="$t('actions.edit')"
            variant="link"
            size="small"
            data-test="vehicle-edit"
            @click.native="openEditModal"
          >
            <i class="fa fa-pencil" />
            {{ $t('actions.edit') }}
          </Btn>
          <Btn
            :aria-label="$t('actions.hangar.editName')"
            variant="link"
            size="small"
            data-test="vehicle-edit-name"
            @click.native="openNamingModal"
          >
            <i class="fa fa-signature" />
            {{ $t('actions.hangar.editName') }}
          </Btn>
          <Btn
            :aria-label="$t('actions.edit')"
            variant="link"
            size="small"
            data-test="vehicle-edit-groups"
            @click.native="openEditGroupsModal"
          >
            <i class="fad fa-object-group" />
            {{ $t('actions.hangar.editGroups') }}
          </Btn>
          <Btn
            :aria-label="$t('actions.remove')"
            variant="link"
            size="small"
            :disabled="deleting"
            data-test="vehicle-remove"
            @click.native="remove"
          >
            <i class="fal fa-trash" />
            {{ $t('actions.remove') }}
          </Btn>
        </BtnDropdown>

        <AddToHangar
          v-else-if="!editable"
          :model="model"
          class="panel-add-to-hangar-button"
          variant="panel"
        />
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
            v-if="editable"
            v-tooltip="purchasedLabel"
            class="purchased-label"
            :class="{ purchased: vehicle.purchased, loaner: vehicle.loaner }"
            @click.prevent="togglePurchased"
          >
            <i v-if="vehicle.loaner" class="fal fa-exchange" />
            <i v-else class="fal fa-check" />
          </div>
          <div
            v-show="model.onSale"
            v-tooltip="$t('labels.model.onSale')"
            class="on-sale"
          >
            <i class="fal fa-dollar-sign" />
          </div>
        </LazyImage>
        <div
          v-if="upgradable && vehicle"
          v-tooltip="$t('labels.model.addons')"
          class="addons"
          :class="{
            selected: hasAddons,
          }"
          @click="openAddonsModal"
        >
          <span v-show="hasAddons">
            <i class="fa fa-plus-octagon" />
          </span>
          <span v-show="!hasAddons">
            <i class="far fa-plus-octagon" />
          </span>
        </div>
        <VehicleOwner
          v-if="(vehicle || vehicles.length) && showOwner"
          :vehicle="vehicle"
          :vehicles="vehicles"
        />
      </div>
      <BCollapse
        :id="`details-${model.slug}-${uuid}-wrapper`"
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
      </BCollapse>
    </Panel>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { BCollapse } from 'bootstrap-vue'
import Panel from 'frontend/core/components/Panel'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import LazyImage from 'frontend/core/components/LazyImage'
import AddToHangar from 'frontend/components/Models/AddToHangar'
import VehicleOwner from 'frontend/components/Vehicles/OwnerLabel'
import ModelPanelMetrics from 'frontend/components/Models/PanelMetrics'
import { displayConfirm } from 'frontend/lib/Noty'
import vehiclesCollection from 'frontend/api/collections/Vehicles'

@Component<ModelPanel>({
  components: {
    BCollapse,
    Panel,
    Btn,
    BtnDropdown,
    LazyImage,
    AddToHangar,
    VehicleOwner,
    ModelPanelMetrics,
  },
})
export default class ModelPanel extends Vue {
  deleting: boolean = false

  @Prop({ required: true }) model: Model

  @Prop({ default: null }) vehicle: Vehicle | null

  @Prop({ default: false }) details: boolean

  @Prop({ default: false }) editable: boolean

  @Prop({ default: false }) highlight: boolean

  @Prop({ default: false }) showOwner: boolean

  @Prop({
    default() {
      return []
    },
  })
  vehicles: Vehicle[]

  get uuid() {
    return this._uid
  }

  get storeImage() {
    if (this.vehicle && this.vehicle.paint) {
      return this.vehicle.paint.storeImageMedium
    }

    if (this.vehicle && this.vehicle.upgrade) {
      return this.vehicle.upgrade.storeImageMedium
    }

    return this.model.storeImageMedium
  }

  get modelName() {
    return this.model.name
  }

  get id() {
    if (this.vehicle) {
      return this.vehicle.id
    }

    return this.model.slug
  }

  get customName() {
    if (this.vehicle && this.vehicle.name) {
      return this.vehicle.name
    }

    return null
  }

  get countLabel() {
    if (!this.vehicles.length) {
      return ''
    }
    return `${this.vehicles.length}x `
  }

  get flagshipTooltip() {
    if (!this.vehicle) {
      return ''
    }
    if (this.$route.name === 'hangar') {
      return this.$t('labels.yourFlagship')
    }
    return this.$t('labels.flagship')
  }

  get hasAddons() {
    return (
      this.vehicle &&
      (this.vehicle.modelModuleIds.length ||
        this.vehicle.modelUpgradeIds.length)
    )
  }

  get upgradable() {
    return (
      (this.editable || this.hasAddons) &&
      (this.model.hasModules || this.model.hasUpgrades)
    )
  }

  get purchasedLabel() {
    if (this.vehicle.loaner) {
      return this.$t('labels.vehicle.loaner')
    }

    if (this.vehicle.purchased) {
      return this.$t('labels.vehicle.purchased')
    }

    return this.$t('actions.markAsPurchased')
  }

  filterManufacturerQuery(manufacturer) {
    return { manufacturerIn: [manufacturer] }
  }

  async togglePurchased() {
    await vehiclesCollection.update(this.vehicle.id, {
      purchased: !this.vehicle.purchased,
    })
  }

  remove() {
    this.deleting = true
    displayConfirm({
      text: this.$t('messages.confirm.vehicle.destroy'),
      onConfirm: () => {
        this.destroy()
      },
      onClose: () => {
        this.deleting = false
      },
    })
  }

  async destroy() {
    await vehiclesCollection.destroy(this.vehicle.id)

    this.deleting = false
  }

  openEditModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/Modal'),
      props: {
        vehicle: this.vehicle,
      },
    })
  }

  openNamingModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/NamingModal'),
      props: {
        vehicle: this.vehicle,
      },
    })
  }

  openEditGroupsModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/GroupsModal'),
      props: {
        vehicle: this.vehicle,
      },
    })
  }

  openAddonsModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/AddonsModal'),
      props: {
        vehicle: this.vehicle,
        editable: this.editable,
      },
    })
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
