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

<script>
import { mapActions } from 'vuex'
import Modal from '@/frontend/core/components/AppModal/Modal/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import { displaySuccess } from '@/frontend/lib/Noty'
import vehiclesCollection from '@/frontend/api/collections/Vehicles'

export default {
  name: 'AddToHangarModal',

  components: {
    Btn,
    Modal,
  },

  props: {
    model: {
      required: true,
      type: Object,
    },
  },

  methods: {
    ...mapActions('hangar', {
      addToHangar: 'add',
    }),

    async saveVehicle(params = {}) {
      const success = await vehiclesCollection.create({
        ...params,
        modelId: this.model.id,
      })

      if (success) {
        await this.addToHangar(this.model.slug)

        displaySuccess({
          icon: this.model.storeImageSmall,
          text: this.$t('messages.vehicle.add.success', {
            model: this.model.name,
          }),
        })

        this.$comlink.$emit('close-modal')
      }
    },

    saveVehicleAsPurchase() {
      this.saveVehicle({ purchased: true })
    },
  },
}
</script>
