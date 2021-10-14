<template>
  <Modal
    v-if="vehicle && form"
    :title="$t('headlines.nameMyVehicle', { vehicle: vehicle.model.name })"
  >
    <ValidationObserver ref="form" v-slot="{ handleSubmit }" :slim="true">
      <form :id="`vehicle-${vehicle.id}`" @submit.prevent="handleSubmit(save)">
        <div class="row">
          <div class="col-12 col-md-6">
            <div class="form-group">
              <ValidationProvider
                vid="name"
                :name="$t('labels.name')"
                :slim="true"
              >
                <FormInput
                  id="vehicle-name"
                  v-model="form.name"
                  :placeholder="vehicle.model.name"
                  translation-key="name"
                  :no-label="true"
                />
              </ValidationProvider>
            </div>
          </div>
          <div class="col-12 col-md-6">
            <div class="form-group">
              <ValidationProvider
                v-slot="{ errors }"
                vid="serial"
                :name="$t('labels.vehicle.serial')"
                :slim="true"
              >
                <FormInput
                  id="vehicle-serial"
                  v-model="form.serial"
                  :placeholder="vehicle.model.serial"
                  translation-key="vehicle.serial"
                  :error="errors[0]"
                  :no-label="true"
                />
              </ValidationProvider>
            </div>
          </div>
          <div class="col-12 col-md-6">
            <ValidationProvider
              vid="nameVisible"
              :name="$t('labels.vehicle.nameVisible')"
              :slim="true"
            >
              <Checkbox
                id="nameVisible"
                v-model="form.nameVisible"
                :label="$t('labels.vehicle.nameVisible')"
              />
            </ValidationProvider>
          </div>
        </div>
        <div class="row alternative-names">
          <div class="col-12">
            <hr />
            <h3>
              <span>
                {{ $t('headlines.hangar.alternativeNames') }}
              </span>
              <Btn
                data-test="vehicle-add-name"
                :inline="true"
                variant="link"
                @click.native="addName"
              >
                <i class="fal fa-plus" />
              </Btn>
            </h3>
          </div>
          <div
            v-for="(name, index) in form.alternativeNames"
            :key="`alternative-name-${index}`"
            class="col-12"
          >
            <div class="form-group">
              <div class="input-group-flex">
                <ValidationProvider
                  :vid="`alternativeNames-${index}`"
                  :name="$t('labels.vehicle.alternativeNames')"
                  :slim="true"
                >
                  <FormInput
                    :id="`vehicle-alternative-name-${index}`"
                    v-model="form.alternativeNames[index]"
                    translation-key="name"
                    :no-label="true"
                  />
                </ValidationProvider>
                <Btn
                  v-tooltip="$t('actions.hangar.useName')"
                  data-test="vehicle-switch-name"
                  :inline="true"
                  variant="link"
                  @click.native="useName(index)"
                >
                  <i class="fad fa-repeat" />
                </Btn>
                <Btn
                  v-tooltip="$t('actions.remove')"
                  data-test="vehicle-add-name"
                  :inline="true"
                  variant="link"
                  @click.native="removeName(index)"
                >
                  <i class="fal fa-times" />
                </Btn>
              </div>
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
import { transformErrors } from 'frontend/api/helpers'

@Component<VehicleModal>({
  components: {
    Modal,
    Checkbox,
    FormInput,
    FilterGroup,
    Btn,
  },
})
export default class VehicleNamingModal extends Vue {
  public get dirty() {
    return (
      !this.submitting &&
      Object.keys(this.$refs.form.fields).some(
        field => this.$refs.form.fields[field].dirty,
      )
    )
  }

  @Prop({ required: true }) vehicle: Vehicle

  submitting: boolean = false

  deleting: boolean = false

  form: Object | null = null

  mounted() {
    this.setupForm()
  }

  @Watch('vehicle')
  onVehicleChange() {
    this.setupForm()
  }

  addName() {
    this.form.alternativeNames.push('')
  }

  removeName(index) {
    this.form.alternativeNames.splice(index, 1)
  }

  useName(index) {
    const newName = this.form.alternativeNames[index]
    this.form.alternativeNames[index] = this.form.name
    this.form.name = newName
  }

  setupForm() {
    const initialData = JSON.parse(JSON.stringify(this.vehicle || {}))

    this.form = {
      name: initialData.name,
      serial: initialData.serial,
      nameVisible: initialData.nameVisible,
      alternativeNames: initialData.alternativeNames,
    }
  }

  async save() {
    this.submitting = true

    const response = await vehiclesCollection.update(this.vehicle.id, this.form)

    if (!response.error) {
      this.$comlink.$emit('close-modal')
    } else {
      const { error } = response
      if (error.response && error.response.data) {
        const { data: errorData } = error.response

        this.$refs.form.setErrors(transformErrors(errorData.errors))
      }
    }

    this.submitting = false
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
