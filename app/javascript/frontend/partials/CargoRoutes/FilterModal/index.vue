<template>
  <Modal
    ref="modal"
    :title="title"
    :visible="visible"
  >
    <FilterForm
      ref="filterForm"
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
import FilterForm from 'frontend/partials/CargoRoutes/FilterForm'

export default {
  components: {
    Modal,
    FilterForm,
    Btn,
  },
  mixins: [I18n, Filters],
  props: {
    visible: {
      type: Boolean,
      default: false,
    },
    title: {
      type: String,
      default: '',
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
