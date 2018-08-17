<template>
  <Modal
    ref="modal"
    :title="t('headlines.filterVehicles')"
    :visible="visible"
  >
    <ModelClassLabels
      v-if="vehiclesCount"
      :label="t('labels.hangar')"
      :count-data="vehiclesCount"
      filter-key="modelClassificationIn"
    />
    <GroupLabels
      v-if="vehiclesCount"
      :hangar-groups="hangarGroupsOptions"
      :label="t('labels.groups')"
    />
    <VehiclesFilterForm
      ref="filterForm"
      :filters="filters"
      :hangar-groups-options="hangarGroupsOptions"
      prefix="filter-modal"
      hide-buttons
    />
    <div slot="footer">
      <Btn
        :disabled="!isFilterSelected"
        block
        @click.native="reset"
      >
        <i class="fal fa-times" />
        {{ t('actions.resetFilter') }}
      </Btn>
    </div>
  </Modal>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Filters from 'frontend/mixins/Filters'
import Modal from 'frontend/components/Modal'
import Btn from 'frontend/components/Btn'
import VehiclesFilterForm from 'frontend/partials/Vehicles/FilterForm'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import GroupLabels from 'frontend/partials/Vehicles/GroupLabels'

export default {
  components: {
    Modal,
    VehiclesFilterForm,
    Btn,
    ModelClassLabels,
    GroupLabels,
  },
  mixins: [I18n, Filters],
  props: {
    filters: {
      type: Array,
      default() {
        return []
      },
    },
    visible: {
      type: Boolean,
      default: false,
    },
    hangarGroupsOptions: {
      type: Array,
      default() {
        return []
      },
    },
    vehiclesCount: {
      type: Object,
      default() {
        return {}
      },
    },

  },
  methods: {
    reset() {
      this.$refs.filterForm.reset()
    },
    open() {
      this.$refs.modal.open()
    },
    close() {
      this.$refs.modal.close()
    },
  },
}
</script>
