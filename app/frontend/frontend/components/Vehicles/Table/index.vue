<template>
  <FilteredTable
    :records="vehicles"
    :primary-key="primaryKey"
    :columns="tableColumns"
    :selectable="editable"
    :selected="selected"
    list-classes="vehicles-table"
    list-item-classes="vehicles-table-row"
    @selected-change="onSelectedChange"
  >
    <template #selected-actions>
      <div class="d-flex">
        <BtnGroup :inline="true">
          <span>{{ $t('labels.visibility') }}</span>
          <Btn
            v-tooltip="$t('actions.hangar.showOnPublicHangar')"
            size="small"
            variant="dropdown"
            :disabled="updating"
            @click.native="showOnPublicHangar"
          >
            <i class="fad fa-eye" />
          </Btn>
          <Btn
            v-tooltip="$t('actions.hangar.hideFromPublicHangar')"
            size="small"
            variant="dropdown"
            :disabled="updating"
            @click.native="hideFromPublicHangar"
          >
            <i class="fad fa-eye-slash" />
          </Btn>
        </BtnGroup>
        <Btn
          size="small"
          :inline="true"
          :disabled="updating"
          @click.native="markAsPurchasedBulk"
        >
          {{ $t('actions.hangar.markAsPurchasedSelected') }}
        </Btn>
        <Btn size="small" :inline="true" @click.native="openBulkGroupEditModal">
          {{ $t('actions.hangar.editGroupsSelected') }}
        </Btn>
        <Btn
          v-tooltip="$t('actions.deleteSelected')"
          size="small"
          :inline="true"
          :disabled="deleting"
          @click.native="destroyBulk"
        >
          <i class="fal fa-trash" />
        </Btn>
      </div>
    </template>
    <template #col-store_image="{ record }">
      <router-link
        :to="{
          name: 'model',
          params: {
            slug: record.model.slug,
          },
        }"
      >
        <div
          :key="record.model.storeImageSmall"
          v-lazy:background-image="record.model.storeImageSmall"
          class="image lazy"
          alt="storeImage"
          :class="{
            'image-highlight-gold': record.flagship,
          }"
        />
      </router-link>
    </template>
    <template #col-name="{ record }">
      <router-link
        :to="{
          name: 'model',
          params: {
            slug: record.model.slug,
          },
        }"
      >
        <span v-if="record.name">
          {{ record.name }}
        </span>

        <span v-else>{{ record.model.name }}</span>

        <transition name="fade" appear>
          <small
            v-if="record && record.flagship"
            v-tooltip.right="$t('labels.yourFlagship')"
          >
            <i class="fad fa-certificate flagship-icon" />
          </small>
        </transition>
      </router-link>
      <br v-if="!slim" />
      <small>
        <span v-html="record.model.manufacturer.name" />
        <template v-if="record.name">
          {{ record.model.name }}
        </template>
      </small>
    </template>
    <template #col-metrics="{ record }">
      <div class="vehicle-focus">
        {{ record.model.focus }}
      </div>
      <div class="vehicle-length">
        {{ record.model.length }}
      </div>
      <template v-if="!slim">
        <div class="vehicle-beam">
          {{ record.model.beam }}
        </div>
        <div class="vehicle-height">
          {{ record.model.height }}
        </div>
      </template>
    </template>
    <template #col-states="{ record }">
      <span
        v-if="record.model.onSale"
        v-tooltip="$t('labels.model.onSale')"
        class="on-sale vehicle-states-item"
      >
        <i class="fad fa-dollar-sign" />
      </span>
      <span
        v-if="record.purchased"
        v-tooltip="$t('labels.vehicle.purchased')"
        class="vehicle-states-item"
      >
        <i class="fas fa-check" />
      </span>
      <span
        v-else-if="record.saleNotify"
        v-tooltip="$t('labels.vehicle.saleNotify')"
        class="vehicle-states-item"
      >
        <i class="fad fa-bell" />
      </span>
      <span
        v-else
        v-tooltip="$t('labels.vehicle.saleNotifyDisabled')"
        class="vehicle-states-item vehicle-states-item-disabled"
      >
        <i class="fad fa-bell-slash" />
      </span>
      <span
        v-if="record.purchased && record.public && record.nameVisible"
        v-tooltip="$t('labels.vehicle.fullPublic')"
        class="full-public-icon vehicle-states-item"
      >
        <i class="fad fa-eye-evil" />
      </span>
      <span
        v-else-if="record.purchased && record.public"
        v-tooltip="$t('labels.vehicle.public')"
        class="vehicle-states-item"
      >
        <i class="fad fa-eye" />
      </span>
      <span
        v-else
        v-tooltip="$t('labels.vehicle.hidden')"
        class="vehicle-states-item vehicle-states-item-disabled"
      >
        <i class="fad fa-eye-slash" />
      </span>
    </template>
    <template #col-groups="{ record }">
      <HangarGroups :groups="record.hangarGroups" size="large" />
    </template>
    <template #col-actions="{ record }">
      <BtnGroup :inline="true">
        <Btn
          v-if="record && editable && !record.loaner"
          :aria-label="$t('actions.edit')"
          size="small"
          data-test="vehicle-edit"
          :inline="true"
          variant="link"
          @click.native="openEditModal(record)"
        >
          {{ $t('actions.edit') }}
        </Btn>
        <VehicleContextMenu :vehicle="record" :editable="editable" />
      </BtnGroup>
    </template>
  </FilteredTable>
</template>

<script>
import FilteredTable from '@/frontend/core/components/FilteredTable/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import BtnGroup from '@/frontend/core/components/BtnGroup/index.vue'
import vehiclesCollection from '@/frontend/api/collections/Vehicles'
import { displayConfirm } from '@/frontend/lib/Noty'
import VehicleContextMenu from '@/frontend/components/Vehicles/ContextMenu/index.vue'
import HangarGroups from '@/frontend/components/Vehicles/HangarGroups/index.vue'

export default {
  name: 'FilteredGrid',
  components: {
    Btn,
    BtnGroup,
    FilteredTable,
    HangarGroups,
    VehicleContextMenu,
  },

  props: {
    editable: {
      type: Boolean,
      default: false,
    },

    primaryKey: {
      type: String,
      required: true,
    },

    slim: {
      type: Boolean,
      default: false,
    },

    vehicles: {
      type: Array,
      required: true,
    },
  },

  data() {
    return {
      deleting: false,
      selected: [],
      updating: false,
    }
  },

  computed: {
    tableColumns() {
      return [
        {
          class: `store-image wide ${this.slim ? 'small' : ''}`,
          name: 'store_image',
          type: 'store-image',
        },
        {
          class: 'vehicle-name name',
          flexGrow: 1,
          name: 'name',
        },
        {
          class: 'vehicle-metrics',
          name: 'metrics',
        },
        {
          class: 'vehicle-states',
          name: 'states',
        },
        {
          class: 'vehicle-groups',
          label: this.$t('labels.vehicle.hangarGroups'),
          name: 'groups',
        },
        {
          class: 'actions',
          label: this.$t('labels.actions'),
          name: 'actions',
        },
      ]
    },
  },

  beforeDestroy() {
    this.$comlink.$off('vehicles-delete-all')
  },

  mounted() {
    this.$comlink.$on('vehicles-delete-all', this.resetSelected)
  },

  methods: {
    async destroyBulk() {
      this.deleting = true

      displayConfirm({
        onClose: () => {
          this.deleting = false
        },
        onConfirm: async () => {
          await vehiclesCollection.destroyBulk(this.selected)

          this.resetSelected()

          this.deleting = false
        },
        text: this.$t('messages.confirm.hangar.destroySelected'),
      })
    },

    hasAddons(vehicle) {
      return vehicle.modelModuleIds.length || vehicle.modelUpgradeIds.length
    },

    async hideFromPublicHangar() {
      this.updating = true

      await vehiclesCollection.hideFromPublicHangar(this.selected)

      this.updating = false
    },

    async markAsPurchasedBulk() {
      this.updating = true

      await vehiclesCollection.markAsPurchasedBulk(this.selected)

      this.updating = false
    },

    onSelectedChange(value) {
      this.selected = value
    },

    openBulkGroupEditModal() {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/Vehicles/BulkGroupModal/index.vue'),
        props: {
          vehicleIds: this.selected,
        },
      })
    },

    openEditModal(vehicle) {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/Vehicles/Modal/index.vue'),
        props: {
          vehicle,
        },
      })
    },

    resetSelected() {
      this.selected = []
    },

    async showOnPublicHangar() {
      this.updating = true

      await vehiclesCollection.showOnPublicHangar(this.selected)

      this.updating = false
    },

    upgradable(vehicle) {
      return (
        (this.editable || this.hasAddons(vehicle)) &&
        (vehicle.model.hasModules || vehicle.model.hasUpgrades)
      )
    },
  },
}
</script>

<style lang="scss">
@import 'index';
</style>
