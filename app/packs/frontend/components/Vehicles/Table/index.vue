<template>
  <FilteredTable
    :records="vehicles"
    :primary-key="primaryKey"
    :columns="tableColumns"
    :selectable="editable"
    :selected="selected"
    @selected-change="onSelectedChange"
  >
    <template #selected-actions>
      <div class="d-flex">
        <BtnGroup :inline="true">
          <span>{{ $t('labels.public') }}</span>
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
      <div
        :key="record.model.storeImageSmall"
        v-lazy:background-image="record.model.storeImageSmall"
        class="image lazy"
        alt="storeImage"
      />
    </template>
    <template #col-name="{ record }">
      <div class="name">
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
        </router-link>
        <br />
        <small>
          <span v-html="record.model.manufacturer.name" />
          <template v-if="record.name">
            {{ record.model.name }}
          </template>
        </small>
      </div>
    </template>
    <template #col-states="{ record }">
      <div class="vehicle-states">
        <i
          v-if="record.flagship"
          v-tooltip="$t('labels.vehicle.flagship')"
          class="fad fa-certificate flagship-icon"
        />
        <i
          v-if="record.model.onSale"
          v-tooltip="$t('labels.model.onSale')"
          class="fad fa-dollar-sign on-sale"
        />
        <i
          v-if="record.purchased"
          v-tooltip="$t('labels.vehicle.purchased')"
          class="fas fa-check"
        />
        <i
          v-if="record.purchased && record.public && record.nameVisible"
          v-tooltip="$t('labels.vehicle.fullPublic')"
          class="fad fa-eye-evil full-public-icon"
        />
        <i
          v-else-if="record.purchased && record.public"
          v-tooltip="$t('labels.vehicle.public')"
          class="fad fa-eye"
        />
        <i
          v-if="record.saleNotify && !record.purchased"
          v-tooltip="$t('labels.vehicle.saleNotify')"
          class="fad fa-bell"
        />
      </div>
    </template>
    <template #col-groups="{ record }">
      <div class="hangar-groups">
        <div
          v-for="(hangarGroup, index) in record.hangarGroups"
          :key="`hangar-group-${record.id}-${index}`"
          v-tooltip="hangarGroup.name"
          class="hangar-group"
          :style="`background-color: ${hangarGroup.color};`"
        />
      </div>
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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import FilteredTable from 'frontend/core/components/FilteredTable'
import Btn from 'frontend/core/components/Btn'
import BtnGroup from 'frontend/core/components/BtnGroup'
import vehiclesCollection from 'frontend/api/collections/Vehicles'
import { displayConfirm } from 'frontend/lib/Noty'
import VehicleContextMenu from 'frontend/components/Vehicles/ContextMenu'

@Component<FilteredGrid>({
  components: {
    FilteredTable,
    VehicleContextMenu,
    Btn,
    BtnGroup,
  },
})
export default class FilteredGrid extends Vue {
  @Prop({ required: true }) vehicles!: Vehicle[]

  @Prop({ required: true }) primaryKey!: string

  @Prop({ default: false }) editable!: boolean

  selected: string[] = []

  deleting: boolean = false

  updating: boolean = false

  tableColumns: FilteredTableColumn[] = [
    {
      name: 'store_image',
      class: 'store-image wide',
      type: 'store-image',
    },
    {
      name: 'name',
      width: '40%',
    },
    {
      name: 'states',
      width: '10%',
    },
    {
      name: 'groups',
      label: this.$t('labels.vehicle.hangarGroups'),
      width: '10%',
    },
    { name: 'actions', label: this.$t('labels.actions'), width: '10%' },
  ]

  mounted() {
    this.$comlink.$on('vehicles-delete-all', this.resetSelected)
  }

  beforeDestroy() {
    this.$comlink.$off('vehicles-delete-all')
  }

  hasAddons(vehicle) {
    return vehicle.modelModuleIds.length || vehicle.modelUpgradeIds.length
  }

  upgradable(vehicle) {
    return (
      (this.editable || this.hasAddons(vehicle)) &&
      (vehicle.model.hasModules || vehicle.model.hasUpgrades)
    )
  }

  openBulkGroupEditModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/BulkGroupModal'),
      props: {
        vehicleIds: this.selected,
      },
    })
  }

  openEditModal(vehicle) {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/Modal'),
      props: {
        vehicle,
      },
    })
  }

  async markAsPurchasedBulk() {
    this.updating = true

    await vehiclesCollection.markAsPurchasedBulk(this.selected)

    this.updating = false
  }

  async hideFromPublicHangar() {
    this.updating = true

    await vehiclesCollection.hideFromPublicHangar(this.selected)

    this.updating = false
  }

  async showOnPublicHangar() {
    this.updating = true

    await vehiclesCollection.showOnPublicHangar(this.selected)

    this.updating = false
  }

  onSelectedChange(value) {
    this.selected = value
  }

  async destroyBulk() {
    this.deleting = true

    displayConfirm({
      text: this.$t('messages.confirm.hangar.destroySelected'),
      onConfirm: async () => {
        await vehiclesCollection.destroyBulk(this.selected)

        this.resetSelected()

        this.deleting = false
      },
      onClose: () => {
        this.deleting = false
      },
    })
  }

  resetSelected() {
    this.selected = []
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
