<template>
  <Modal
    v-if="model"
    :title="$t('headlines.addToHangar', { model: model.name })"
  >
    <div class="page-actions page-actions-block">
      <Btn
        :inline="true"
        data-test="add-to-hangar-as-purchased"
        @click.native="saveVehicleAsPurchase"
      >
        {{ $t('actions.addAsPurchased') }}
      </Btn>
      <Btn
        :inline="true"
        data-test="add-to-hangar-as-normal"
        @click.native="saveVehicle"
      >
        {{ $t('actions.add') }}
      </Btn>
    </div>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { Action } from 'vuex-class'
import Modal from 'frontend/core/components/AppModal/Modal'
import Btn from 'frontend/core/components/Btn'
import { displaySuccess } from 'frontend/lib/Noty'
import vehiclesCollection from 'frontend/api/collections/Vehicles'

@Component<AddToHangarModal>({
  components: {
    Modal,
    Btn,
  },
})
export default class AddToHangarModal extends Vue {
  @Prop({ required: true }) model: Model

  @Action('add', { namespace: 'hangar' }) addToHangar

  saveVehicleAsPurchase() {
    this.saveVehicle({ purchased: true })
  }

  async saveVehicle(params = {}) {
    const success = await vehiclesCollection.create({
      ...params,
      modelId: this.model.id,
    })

    if (success) {
      await this.addToHangar(this.model.slug)

      displaySuccess({
        text: this.$t('messages.vehicle.add.success', {
          model: this.model.name,
        }),
        icon: this.model.storeImageSmall,
      })

      this.$comlink.$emit('close-modal')
    }
  }
}
</script>
