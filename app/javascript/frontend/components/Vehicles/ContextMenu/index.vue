<template>
  <BtnDropdown
    :size="size"
    :variant="variant"
    class="panel-edit-menu"
    data-test="vehicle-menu"
    :expand-left="true"
    :inline="true"
  >
    <Btn
      :to="{
        name: 'model',
        params: {
          slug: vehicle.model.slug,
        },
      }"
      variant="link"
      size="small"
    >
      <i class="fad fa-starship" />
      {{ $t('actions.showDetailPage') }}
    </Btn>
    <Btn
      v-if="editable"
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
      v-if="editable"
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
      v-if="editable"
      :aria-label="$t('actions.hangar.editGroups')"
      variant="link"
      size="small"
      data-test="vehicle-edit-groups"
      @click.native="openEditGroupsModal"
    >
      <i class="fad fa-object-group" />
      {{ $t('actions.hangar.editGroups') }}
    </Btn>
    <Btn
      v-if="editable"
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
    <Btn
      v-if="upgradable"
      :aria-label="$t('labels.model.addons')"
      variant="link"
      size="small"
      @click.native="openAddonsModal"
    >
      <i class="fa fa-plus-octagon" />
      {{ $t('labels.model.addons') }}
    </Btn>
  </BtnDropdown>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import { displayConfirm } from 'frontend/lib/Noty'
import vehiclesCollection from 'frontend/api/collections/Vehicles'

@Component<GroupModal>({
  components: {
    Btn,
    BtnDropdown,
  },
})
export default class ContextMenu extends Vue {
  deleting: boolean = false

  @Prop({ default: null }) vehicle: Vehicle | null

  @Prop({ default: false }) editable!: boolean

  @Prop({
    default: 'link',
    validator(value) {
      return (
        ['default', 'transparent', 'link', 'danger', 'dropdown'].indexOf(
          value,
        ) !== -1
      )
    },
  })
  variant!: string

  @Prop({
    default: 'small',
    validator(value) {
      return ['default', 'small', 'large'].indexOf(value) !== -1
    },
  })
  size!: string

  get hasAddons() {
    return (
      this.vehicle.modelModuleIds.length || this.vehicle.modelUpgradeIds.length
    )
  }

  get upgradable() {
    return (
      (this.editable || this.hasAddons) &&
      (this.vehicle.model.hasModules || this.vehicle.model.hasUpgrades)
    )
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
}
</script>
