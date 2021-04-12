<template>
  <Modal
    v-if="vehicle && form"
    :title="$t('headlines.editMyVehicle', { vehicle: vehicle.model.name })"
  >
    <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
      <form :id="`vehicle-${vehicle.id}`" @submit.prevent="handleSubmit(save)">
        <div class="row">
          <div class="col-12 col-md-6">
            <Checkbox
              id="flagship"
              v-model="form.flagship"
              :label="$t('labels.vehicle.flagship')"
            />
            <Checkbox
              id="purchased"
              v-model="form.purchased"
              :label="$t('labels.vehicle.purchased')"
            />
            <Checkbox
              id="saleNotify"
              v-model="form.saleNotify"
              :disabled="form.purchased"
              :label="$t('labels.vehicle.saleNotify')"
            />
            <Checkbox
              id="public"
              v-model="form.public"
              :label="$t('labels.vehicle.public')"
            />
          </div>
          <div
            v-if="vehicle && vehicle.model.hasPaints"
            class="col-12 col-md-6"
          >
            <div class="form-group">
              <FilterGroup
                :key="`paints-${vehicle.model.id}`"
                v-model="form.modelPaintId"
                translation-key="vehicle.modelPaintSelect"
                :fetch-path="`models/${vehicle.model.slug}/paints`"
                name="modelPaintId"
                value-attr="id"
                icon-attr="storeImageSmall"
                :big-icon="true"
                :nullable="true"
                :no-label="true"
              />
            </div>
          </div>
        </div>
      </form>
    </ValidationObserver>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :form="`vehicle-${vehicle.id}`"
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
import { Component, Prop, Watch } from 'vue-property-decorator'
import Modal from 'frontend/core/components/AppModal/Modal'
import FormInput from 'frontend/core/components/Form/FormInput'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import Checkbox from 'frontend/core/components/Form/Checkbox'
import Btn from 'frontend/core/components/Btn'
import vehiclesCollection from 'frontend/api/collections/Vehicles'

@Component<VehicleModal>({
  components: {
    Modal,
    Checkbox,
    FormInput,
    FilterGroup,
    Btn,
  },
})
export default class VehicleModal extends Vue {
  @Prop({ required: true }) vehicle: Vehicle

  submitting: boolean = false

  form: Object | null = null

  mounted() {
    this.setupForm()
  }

  @Watch('vehicle')
  onVehicleChange() {
    this.setupForm()
  }

  setupForm() {
    this.form = {
      purchased: this.vehicle.purchased,
      flagship: this.vehicle.flagship,
      public: this.vehicle.public,
      saleNotify: this.vehicle.saleNotify,
      modelPaintId: this.vehicle.paint?.id || null,
    }
  }

  async save() {
    this.submitting = true

    const response = await vehiclesCollection.update(this.vehicle.id, this.form)

    this.submitting = false

    if (!response.error) {
      this.$comlink.$emit('close-modal')
    }
  }
}
</script>
