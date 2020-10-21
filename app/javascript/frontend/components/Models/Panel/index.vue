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
            <span v-if="customName">
              {{ customName }}
            </span>

            <span v-else>{{ countLabel }}{{ modelName }}</span>
          </router-link>

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

          <Btn
            v-if="vehicle && isMyShip && !vehicle.loaner"
            :title="$t('actions.edit')"
            :aria-label="$t('actions.edit')"
            class="panel-edit-button"
            variant="link"
            size="small"
            data-test="vehicle-edit"
            @click.native="openEditModal"
          >
            <i class="fa fa-pencil" />
          </Btn>

          <AddToHangar
            v-else-if="!isMyShip && !username"
            :model="model"
            class="panel-add-to-hangar-button"
            variant="panel"
          />
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
            v-if="isMyShip"
            v-show="vehicle.purchased || vehicle.loaner"
            v-tooltip="
              vehicle.loaner
                ? $t('labels.vehicle.loaner')
                : $t('labels.vehicle.purchased')
            "
            class="purchased"
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
        <div v-if="username" class="owner">
          {{ $t('labels.vehicle.owner') }}
          <Btn :href="`/hangar/${username}`" variant="link" :text-inline="true">
            {{ username }}
          </Btn>
        </div>
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
import LazyImage from 'frontend/core/components/LazyImage'
import AddToHangar from 'frontend/components/Models/AddToHangar'
import ModelPanelMetrics from 'frontend/components/Models/PanelMetrics'

@Component<ModelPanel>({
  components: {
    BCollapse,
    Panel,
    Btn,
    LazyImage,
    AddToHangar,
    ModelPanelMetrics,
  },
})
export default class ModelPanel extends Vue {
  @Prop({ required: true }) model: Model

  @Prop({ default: null }) vehicle: Vehicle | null

  @Prop({ default: false }) details: boolean

  @Prop({ default: null }) count: number

  @Prop({ default: false }) isMyShip: boolean

  @Prop({ default: false }) highlight: boolean

  @Prop({ default: null }) username: string

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
    if (!this.count) {
      return ''
    }
    return `${this.count}x `
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
      (this.isMyShip || this.hasAddons) &&
      (this.model.hasModules || this.model.hasUpgrades)
    )
  }

  filterManufacturerQuery(manufacturer) {
    return { manufacturerIn: [manufacturer] }
  }

  openEditModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/Modal'),
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
        modifiable: this.isMyShip,
      },
    })
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
