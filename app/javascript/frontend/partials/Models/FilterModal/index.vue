<template>
  <Modal
    ref="modal"
    :title="t('headlines.filterModels')"
    :visible="visible"
  >
    <ModelsFilterForm
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
import ModelsFilterForm from 'frontend/partials/Models/FilterForm'

export default {
  components: {
    Modal,
    Btn,
    ModelsFilterForm,
  },
  mixins: [I18n, Filters],
  props: {
    visible: {
      type: Boolean,
      default: false,
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
