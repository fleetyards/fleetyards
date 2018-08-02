<template>
  <Modal
    ref="modal"
    :title="t('headlines.myVehicle', { vehicle: vehicle.model.name })"
    :visible="visible"
  >
    <form
      :id="`vehicle-${vehicle.id}`"
      @submit.prevent="save"
    >
      <div class="row">
        <div class="col-xs-12 col-sm-6">
          <div class="form-group">
            <input
              v-model="form.name"
              :placeholder="vehicle.model.name"
              type="text"
              class="form-control"
            >
          </div>
        </div>
        <div class="col-xs-12 col-sm-6">
          <Checkbox
            id="flagship"
            v-model="form.flagship"
            :label="t('labels.vehicle.flagship')"
          />
        </div>
        <div class="col-xs-12 col-sm-6">
          <Checkbox
            id="purchased"
            v-model="form.purchased"
            :label="t('labels.vehicle.purchased')"
          />
        </div>
        <div
          v-if="!form.purchased"
          class="col-xs-12 col-sm-6"
        >
          <Checkbox
            id="saleNotify"
            v-model="form.saleNotify"
            :label="t('labels.vehicle.saleNotify')"
          />
        </div>
        <div class="col-xs-12 col-sm-6">
          <Checkbox
            id="nameVisible"
            v-model="form.nameVisible"
            :label="t('labels.vehicle.nameVisible')"
          />
        </div>
        <div
          v-if="hangarGroups.length > 0"
          class="col-xs-12"
        >
          <h3>Groups:</h3>
          <div class="row">
            <div
              v-for="group in hangarGroups"
              :key="group.id"
              class="col-xs-12 col-sm-6"
            >
              <Checkbox
                :label="group.name"
                :value="form.hangarGroupIds.includes(group.id)"
                @input="changeGroup(group)"
              />
            </div>
          </div>
        </div>
      </div>
    </form>
    <template slot="footer">
      <div class="pull-right">
        <Btn
          v-if="vehicle"
          :disabled="deleting ? 'disabled' : null"
          @click.native="remove"
        >
          <i class="fal fa-trash" />
        </Btn>
        <SubmitButton
          :form="`vehicle-${vehicle.id}`"
          :loading="submitting"
        >
          {{ t('actions.save') }}
        </SubmitButton>
      </div>
    </template>
  </Modal>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import SubmitButton from 'frontend/components/SubmitButton'
import Modal from 'frontend/components/Modal'
import { confirm } from 'frontend/lib/Noty'
import Checkbox from 'frontend/components/Form/Checkbox'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    SubmitButton,
    Modal,
    Checkbox,
    Btn,
  },
  mixins: [I18n],
  props: {
    vehicle: {
      type: Object,
      required: true,
    },
    hangarGroups: {
      type: Array,
      default() {
        return []
      },
    },
    visible: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      submitting: false,
      deleting: false,
      form: {
        name: this.vehicle.name,
        purchased: this.vehicle.purchased,
        flagship: this.vehicle.flagship,
        saleNotify: this.vehicle.saleNotify,
        nameVisible: this.vehicle.nameVisible,
        hangarGroupIds: this.vehicle.hangarGroupIds,
      },
    }
  },
  watch: {
    vehicle() {
      this.form = {
        name: this.vehicle.name,
        purchased: this.vehicle.purchased,
        flagship: this.vehicle.flagship,
        saleNotify: this.vehicle.saleNotify,
        nameVisible: this.vehicle.nameVisible,
        hangarGroupIds: this.vehicle.hangarGroupIds,
      }
    },
  },
  methods: {
    open() {
      this.$refs.modal.open()
    },
    remove() {
      this.deleting = true
      confirm(this.t('confirm.vehicle.destroy'), () => {
        this.destroy()
      }, () => {
        this.deleting = false
      })
    },
    destroy() {
      this.$api.destroy(`vehicles/${this.vehicle.id}`, (args) => {
        if (!args.error) {
          this.$refs.modal.close()
          this.$comlink.$emit('vehicleDelete', args.data)
        } else {
          this.deleting = false
        }
      })
    },
    changeGroup(group) {
      if (this.form.hangarGroupIds.includes(group.id)) {
        const index = this.form.hangarGroupIds.findIndex(groupId => groupId === group.id)
        if (index > -1) {
          this.form.hangarGroupIds.splice(index, 1)
        }
      } else {
        this.form.hangarGroupIds.push(group.id)
      }
    },
    save() {
      this.submitting = true
      this.$api.put(`vehicles/${this.vehicle.id}`, this.form, (args) => {
        this.submitting = false
        if (!args.error) {
          this.$refs.modal.close()
          this.$comlink.$emit('vehicleSave', args.data)
        }
      })
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
