<template>
  <Modal
    ref="modal"
    :title="t('headlines.newVehicles')"
    :visible="visible"
  >
    <form
      id="new-vehicles"
      class="new-vehicles"
      @submit.prevent="save"
    >
      <div
        v-for="(item, index) in form.vehicles"
        :key="index"
        class="row"
      >
        <div class="col-xs-8 col-sm-10">
          <FilterGroup
            v-model="item.modelId"
            :label="t('labels.compare.selectModel')"
            :name="`model`"
            :search-label="t('actions.findModel')"
            :fetch="fetchModels"
            value-attr="id"
            paginated
            searchable
          />
        </div>
        <div class="col-xs-4 col-sm-2">
          <Btn
            v-tooltip="t('actions.delete')"
            :aria-label="t('actions.delete')"
            :disabled="form.vehicles.length <= 1"
            @click.native="removeItem(index)"
          >
            <i class="fa fa-trash" />
          </Btn>
        </div>
      </div>
      <Btn
        v-tooltip="t('actions.addAnother')"
        :aria-label="t('actions.addAnother')"
        @click.native="addItem"
      >
        <i class="fa fa-plus" />
      </Btn>
    </form>
    <template #footer>
      <div class="pull-right">
        <SubmitButton
          form="new-vehicles"
          :loading="submitting"
        >
          {{ t('actions.add') }}
        </SubmitButton>
      </div>
    </template>
  </Modal>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import SubmitButton from 'frontend/components/SubmitButton'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import Modal from 'frontend/components/Modal'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    SubmitButton,
    Modal,
    FilterGroup,
    Btn,
  },
  mixins: [I18n],
  props: {
    visible: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      submitting: false,
      form: {
        vehicles: [{
          modelId: null,
        }],
      },
    }
  },
  methods: {
    addItem() {
      this.form.vehicles.push({
        modelId: null,
      })
    },
    removeItem(index) {
      this.form.vehicles.splice(index, 1)
    },
    open() {
      this.form = {
        vehicles: [{
          modelId: null,
        }],
      }
      this.$nextTick(() => {
        this.$refs.modal.open()
      })
    },
    async save() {
      this.submitting = true
      await this.form.vehicles.forEach(async (item) => {
        const response = await this.$api.post('vehicles', item)
        if (response.error) {
          console.error(response.error)
        }
      })
      this.submitting = false
      this.$refs.modal.close()
      this.$comlink.$emit('vehiclesAdded')
    },
    fetchModels({ page, search, missingValue }) {
      const query = {
        q: {},
      }
      if (search) {
        query.q.nameCont = search
      } else if (missingValue) {
        query.q.nameCont = missingValue
      } else if (page) {
        query.page = page
      }
      return this.$api.get('models', query)
    },
  },
}
</script>
