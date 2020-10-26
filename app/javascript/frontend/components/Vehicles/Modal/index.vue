<template>
  <Modal
    v-if="vehicle && form"
    :title="$t('headlines.myVehicle', { vehicle: vehicle.model.name })"
  >
    <form :id="`vehicle-${vehicle.id}`" @submit.prevent="save">
      <div class="row">
        <div class="col-12 col-md-6">
          <div class="form-group">
            <FormInput
              id="vehicle-name"
              v-model="form.name"
              :placeholder="vehicle.model.name"
              translation-key="name"
              :no-label="true"
            />
          </div>
        </div>
        <div v-if="vehicle && vehicle.model.hasPaints" class="col-12 col-md-6">
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
        <div class="col-12 col-md-6">
          <Checkbox
            id="flagship"
            v-model="form.flagship"
            :label="$t('labels.vehicle.flagship')"
          />
        </div>
        <div class="col-12 col-md-6">
          <Checkbox
            id="purchased"
            v-model="form.purchased"
            :label="$t('labels.vehicle.purchased')"
          />
        </div>
        <div v-if="!form.purchased" class="col-12 col-md-6">
          <Checkbox
            id="saleNotify"
            v-model="form.saleNotify"
            :label="$t('labels.vehicle.saleNotify')"
          />
        </div>
        <div v-else class="col-12 col-md-6">
          <Checkbox
            id="public"
            v-model="form.public"
            :label="$t('labels.vehicle.public')"
          />
        </div>
        <div v-if="form.public && form.purchased" class="col-12 col-md-6">
          <Checkbox
            id="nameVisible"
            v-model="form.nameVisible"
            :label="$t('labels.vehicle.nameVisible')"
          />
        </div>
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
          v-if="vehicle"
          :disabled="deleting"
          data-test="vehicle-delete"
          :inline="true"
          @click.native="remove"
        >
          <i class="fal fa-trash" />
        </Btn>
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
import { displayConfirm } from 'frontend/lib/Noty'
import vehiclesCollection from 'frontend/api/collections/Vehicles'
import hangarGroupsCollection from 'frontend/api/collections/HangarGroups'

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

  deleting: boolean = false

  form: Object | null = null

  get hangarGroups() {
    return hangarGroupsCollection.records
  }

  mounted() {
    this.setupForm()
  }

  @Watch('vehicle')
  onVehicleChange() {
    this.setupForm()
  }

  setupForm() {
    this.form = {
      name: this.vehicle.name,
      purchased: this.vehicle.purchased,
      flagship: this.vehicle.flagship,
      public: this.vehicle.public,
      saleNotify: this.vehicle.saleNotify,
      nameVisible: this.vehicle.nameVisible,
      hangarGroupIds: this.vehicle.hangarGroupIds,
      modelPaintId: this.vehicle.paint?.id || null,
    }
  }

  selected(groupId) {
    return (this.form.hangarGroupIds || []).includes(groupId)
  }

  remove() {
    this.deleting = true
    displayConfirm({
      text: this.$t('messages.confirm.vehicle.destroy'),
      onConfirm: () => {
        this.destroy()
      },
      onClose: () => {
        this.deleting = false
      },
    })
  }

  async destroy() {
    if (await vehiclesCollection.destroy(this.vehicle.id)) {
      this.$comlink.$emit('close-modal')
    }

    this.deleting = false
  }

  changeGroup(group) {
    if (this.form.hangarGroupIds.includes(group.id)) {
      const index = this.form.hangarGroupIds.findIndex(
        groupId => groupId === group.id,
      )
      if (index > -1) {
        this.form.hangarGroupIds.splice(index, 1)
      }
    } else {
      this.form.hangarGroupIds.push(group.id)
    }
  }

  async save() {
    this.submitting = true

    if (await vehiclesCollection.update(this.vehicle.id, this.form)) {
      this.$comlink.$emit('close-modal')
    }

    this.submitting = false
  }
}
</script>
