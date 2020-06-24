<template>
  <Modal ref="modal" :title="$t('headlines.newVehicles')">
    <form id="new-vehicles" class="new-vehicles" @submit.prevent="save">
      <div v-for="(item, index) in form.vehicles" :key="index" class="row">
        <div class="col-8 col-md-10">
          <TeaserPanel
            :item="item.model"
            variant="text"
            :with-description="false"
          />
        </div>
        <div class="col-4 col-md-2">
          <Btn
            v-tooltip="$t('actions.remove')"
            :aria-label="$t('actions.remove')"
            @click.native="removeItem(index)"
          >
            <i class="fa fa-trash" />
          </Btn>
        </div>
      </div>

      <FilterGroup
        v-if="visible()"
        name="model"
        :search-label="$t('actions.findModel')"
        fetch-path="models"
        value-attr="id"
        translation-key="newVehicle"
        :paginated="true"
        :searchable="true"
        :return-object="true"
        :no-label="true"
        @input="add"
      />
    </form>
    <template #footer>
      <div class="float-sm-right">
        <Btn
          type="submit"
          form="new-vehicles"
          :loading="submitting"
          size="large"
          :inline="true"
        >
          {{ $t('actions.add') }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import Modal from 'frontend/components/Modal'
import TeaserPanel from 'frontend/components/TeaserPanel'
import Btn from 'frontend/components/Btn'
import { VehiclesCollection } from 'frontend/collections/Vehicles'

@Component<NewVehiclesModal>({
  components: {
    Modal,
    FilterGroup,
    Btn,
    TeaserPanel,
  },
})
export default class NewVehiclesModal extends Vue {
  submitting: boolean = false

  form: Object = {
    vehicles: [],
  }

  @Prop({ required: true }) collection!: VehiclesCollection

  visible() {
    return this.$refs.modal && this.$refs.modal.isOpen
  }

  add(value) {
    this.form.vehicles.push({
      model: value,
    })
  }

  removeItem(index) {
    this.form.vehicles.splice(index, 1)
  }

  open() {
    this.form = {
      vehicles: [],
    }

    this.$nextTick(() => {
      this.$refs.modal.open()
    })
  }

  async save() {
    this.submitting = true

    await this.form.vehicles.forEach(async item => {
      await this.collection.create({ modelId: item.model.id })
    })

    this.collection.refresh()

    this.submitting = false

    this.$refs.modal.close()
  }
}
</script>
