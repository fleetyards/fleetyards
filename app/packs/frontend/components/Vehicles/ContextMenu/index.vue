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
      v-if="vehicle.model"
      :to="{
        name: 'model',
        params: {
          slug: vehicle.model.slug,
        },
      }"
      size="small"
      variant="dropdown"
    >
      <i class="fad fa-starship" />
      <span>{{ $t('actions.showDetailPage') }}</span>
    </Btn>
    <Btn
      v-if="editable"
      :aria-label="$t('actions.edit')"
      size="small"
      variant="dropdown"
      data-test="vehicle-edit"
      @click.native="openEditModal"
    >
      <i class="fa fa-pencil" />
      <span>{{ $t('actions.edit') }}</span>
    </Btn>
    <Btn
      v-if="editable"
      :aria-label="$t('actions.hangar.editName')"
      size="small"
      variant="dropdown"
      data-test="vehicle-edit-name"
      @click.native="openNamingModal"
    >
      <i class="fa fa-signature" />
      <span>{{ $t('actions.hangar.editName') }}</span>
    </Btn>
    <Btn
      v-if="editable"
      :aria-label="$t('actions.hangar.editGroups')"
      size="small"
      variant="dropdown"
      data-test="vehicle-edit-groups"
      @click.native="openEditGroupsModal"
    >
      <i class="fad fa-object-group" />
      <span>{{ $t('actions.hangar.editGroups') }}</span>
    </Btn>
    <Btn
      v-if="upgradable"
      :aria-label="$t('labels.model.addons')"
      size="small"
      variant="dropdown"
      @click.native="openAddonsModal"
    >
      <i class="fa fa-plus-octagon" />
      <span>{{ $t('labels.model.addons') }}</span>
    </Btn>
    <Btn
      v-if="editable"
      :aria-label="$t('actions.remove')"
      size="small"
      variant="dropdown"
      :disabled="deleting"
      data-test="vehicle-remove"
      @click.native="remove"
    >
      <i class="fal fa-trash" />
      <span>{{ $t('actions.remove') }}</span>
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
          value
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
