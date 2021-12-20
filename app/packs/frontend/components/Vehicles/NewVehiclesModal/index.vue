<template>
  <Modal :title="$t('headlines.newVehicles')">
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

      <CollectionFilterGroup
        name="model"
        :search-label="$t('actions.findModel')"
        :collection="modelsCollection"
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
import { Component } from 'vue-property-decorator'
import CollectionFilterGroup from 'frontend/core/components/Form/CollectionFilterGroup'
import Modal from 'frontend/core/components/AppModal/Modal'
import TeaserPanel from 'frontend/core/components/TeaserPanel'
import Btn from 'frontend/core/components/Btn'
import vehiclesCollection from 'frontend/api/collections/Vehicles'
import modelsCollection from 'frontend/api/collections/Models'

@Component<NewVehiclesModal>({
  components: {
    Modal,
    CollectionFilterGroup,
    Btn,
    TeaserPanel,
  },
})
export default class NewVehiclesModal extends Vue {
  submitting: boolean = false

  modelsCollection: ModelsCollection = modelsCollection

  form: Object = {
    vehicles: [],
  }

  add(value) {
    this.form.vehicles.push({
      model: value,
    })
  }

  removeItem(index) {
    this.form.vehicles.splice(index, 1)
  }

  mounted() {
    this.form = {
      vehicles: [],
    }
  }

  async save() {
    this.submitting = true

    await this.form.vehicles.forEach(async (item) => {
      await vehiclesCollection.create({ modelId: item.model.id })
    })

    vehiclesCollection.refresh()

    this.submitting = false

    this.$comlink.$emit('close-modal')
  }
}
</script>
