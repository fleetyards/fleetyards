<template>
  <Modal :title="$t('headlines.vehicle.bulkGroupEdit')">
    <p class="hint">
      <i class="fal fa-info-circle" />
      {{ $t('labels.vehicle.bulkGroupEdit.hint') }}
    </p>

    <form id="vehicle-bulk" @submit.prevent="save">
      <div class="row">
        <div v-if="hangarGroups.length" class="col-12">
          <h3>Groups:</h3>
          <div class="row">
            <div
              v-for="group in hangarGroups"
              :key="group.id"
              class="col-12 col-md-6"
            >
              <Checkbox
                :label="group.name"
                :value="selected(group.id)"
                @input="changeGroup(group)"
              />
            </div>
          </div>
        </div>
      </div>
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          form="vehicle-bulk"
          :loading="submitting"
          type="submit"
          size="large"
          data-test="vehicle-save"
          :inline="true"
        >
          {{ $t('actions.save') }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Modal from 'frontend/core/components/AppModal/Modal'
import FormInput from 'frontend/core/components/Form/FormInput'
import Checkbox from 'frontend/core/components/Form/Checkbox'
import Btn from 'frontend/core/components/Btn'
import vehiclesCollection from 'frontend/api/collections/Vehicles'
import hangarGroupsCollection from 'frontend/api/collections/HangarGroups'

@Component<VehicleModal>({
  components: {
    Modal,
    Checkbox,
    FormInput,
    Btn,
  },
})
export default class VehicleModal extends Vue {
  get hangarGroups() {
    return hangarGroupsCollection.records
  }

  @Prop({ required: true }) vehicleIds: string[]

  submitting: boolean = false

  hangarGroupIds: string[] = []

  selected(groupId) {
    return this.hangarGroupIds.includes(groupId)
  }

  changeGroup(group) {
    if (this.hangarGroupIds.includes(group.id)) {
      const index = this.hangarGroupIds.findIndex(
        groupId => groupId === group.id,
      )
      if (index > -1) {
        this.hangarGroupIds.splice(index, 1)
      }
    } else {
      this.hangarGroupIds.push(group.id)
    }
  }

  async save() {
    this.submitting = true

    if (
      await vehiclesCollection.updateHangarGroupsBulk(
        this.vehicleIds,
        this.hangarGroupIds,
      )
    ) {
      this.$comlink.$emit('close-modal')
    }

    this.submitting = false
  }
}
</script>
