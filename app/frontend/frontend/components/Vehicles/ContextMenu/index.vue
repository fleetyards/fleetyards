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

<script>
import Btn from '@/frontend/core/components/Btn/index.vue'
import BtnDropdown from '@/frontend/core/components/BtnDropdown/index.vue'
import { displayConfirm } from '@/frontend/lib/Noty'
import vehiclesCollection from '@/frontend/api/collections/Vehicles'

export default {
  name: 'ContextMenu',

  components: {
    Btn,
    BtnDropdown,
  },

  props: {
    editable: {
      type: Boolean,
      default: false,
    },

    size: {
      type: String,
      default: 'small',
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },

    variant: {
      type: String,
      default: 'link',
      validator(value) {
        return (
          ['default', 'transparent', 'link', 'danger', 'dropdown'].indexOf(
            value
          ) !== -1
        )
      },
    },

    vehicle: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      deleting: false,
    }
  },

  computed: {
    hasAddons() {
      return (
        this.vehicle.modelModuleIds.length ||
        this.vehicle.modelUpgradeIds.length
      )
    },

    upgradable() {
      return (
        (this.editable || this.hasAddons) &&
        (this.vehicle.model.hasModules || this.vehicle.model.hasUpgrades)
      )
    },
  },

  methods: {
    async destroy() {
      await vehiclesCollection.destroy(this.vehicle.id)

      this.deleting = false
    },

    openAddonsModal() {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/Vehicles/AddonsModal/index.vue'),
        props: {
          editable: this.editable,
          vehicle: this.vehicle,
        },
      })
    },

    openEditGroupsModal() {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/Vehicles/GroupsModal/index.vue'),
        props: {
          vehicle: this.vehicle,
        },
      })
    },

    openEditModal() {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/Vehicles/Modal/index.vue'),
        props: {
          vehicle: this.vehicle,
        },
      })
    },

    openNamingModal() {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/Vehicles/NamingModal/index.vue'),
        props: {
          vehicle: this.vehicle,
        },
      })
    },

    remove() {
      this.deleting = true
      displayConfirm({
        onClose: () => {
          this.deleting = false
        },
        onConfirm: () => {
          this.destroy()
        },
        text: this.$t('messages.confirm.vehicle.destroy'),
      })
    },
  },
}
</script>
