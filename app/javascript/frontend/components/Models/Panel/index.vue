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
                query: { q: filterManufacturerQuery(model.manufacturer.slug) },
              }"
              v-html="model.manufacturer.name"
            />
            <template v-if="customName">
              {{ modelName }}
            </template>
          </small>

          <Btn
            v-if="vehicle && onEdit && !vehicle.loaner"
            :title="$t('actions.edit')"
            :aria-label="$t('actions.edit')"
            class="panel-edit-button"
            variant="link"
            size="small"
            data-test="vehicle-edit"
            @click.native="onEdit(vehicle)"
          >
            <i class="fa fa-pencil" />
          </Btn>

          <AddToHangar
            v-else-if="!isMyShip"
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
          v-if="upgradable && onAddons && vehicle"
          v-tooltip="$t('labels.model.addons')"
          class="addons"
          :class="{
            selected: hasAddons,
          }"
          @click="onAddons(vehicle)"
        >
          <span v-show="hasAddons">
            <i class="fa fa-plus-octagon" />
          </span>
          <span v-show="!hasAddons">
            <i class="far fa-plus-octagon" />
          </span>
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
        <ModelTopMetrics :model="model" padding />
        <hr class="dark slim-spacer" />
        <ModelBaseMetrics :model="model" padding />
      </BCollapse>
    </Panel>
  </div>
</template>

<script>
import { BCollapse } from 'bootstrap-vue'
import Panel from 'frontend/components/Panel'
import Btn from 'frontend/components/Btn'
import LazyImage from 'frontend/components/LazyImage'
import AddToHangar from 'frontend/partials/Models/AddToHangar'
import ModelTopMetrics from 'frontend/partials/Models/TopMetrics'
import ModelBaseMetrics from 'frontend/partials/Models/BaseMetrics'

export default {
  name: 'ModelPanel',

  components: {
    BCollapse,
    Panel,
    Btn,
    LazyImage,
    AddToHangar,
    ModelTopMetrics,
    ModelBaseMetrics,
  },

  props: {
    model: {
      type: Object,
      required: true,
    },

    vehicle: {
      type: Object,
      default: null,
    },

    onEdit: {
      type: Function,
      default: null,
    },

    onAddons: {
      type: Function,
      default: null,
    },

    details: {
      type: Boolean,
      default: false,
    },

    count: {
      type: Number,
      default: null,
    },

    isMyShip: {
      type: Boolean,
      default: false,
    },

    highlight: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    uuid() {
      return this._uid
    },

    storeImage() {
      if (this.vehicle && this.vehicle.paint) {
        return this.vehicle.paint.storeImageMedium
      }

      if (this.vehicle && this.vehicle.upgrade) {
        return this.vehicle.upgrade.storeImageMedium
      }

      return this.model.storeImageMedium
    },

    modelName() {
      return this.model.name
    },

    id() {
      if (this.vehicle) {
        return this.vehicle.id
      }

      return this.model.slug
    },

    customName() {
      if (this.vehicle && this.vehicle.name) {
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
        return this.$t('labels.yourFlagship')
      }
      return this.$t('labels.flagship')
    },

    hasAddons() {
      return (
        this.vehicle &&
        (this.vehicle.modelModuleIds.length ||
          this.vehicle.modelUpgradeIds.length)
      )
    },

    upgradable() {
      return (
        (this.isMyShip || this.hasAddons) &&
        (this.model.hasModules || this.model.hasUpgrades)
      )
    },
  },

  methods: {
    filterManufacturerQuery(manufacturer) {
      return { manufacturerIn: [manufacturer] }
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
