<template>
  <Modal
    v-if="vehicle"
    ref="modal"
    :title="$t('headlines.myVehicleAddons', { vehicle: vehicle.model.name })"
    :visible="visible"
    @open="fetch"
  >
    <form
      :id="`vehicle-addons-${vehicle.id}`"
      class="addons"
      @submit.prevent="save"
    >
      <div class="row">
        <div class="col-xs-12">
          <fieldset v-if="modules.length">
            <legend>
              <h3>{{ $t('labels.model.modules') }}:</h3>
            </legend>
            <Addons
              v-model="form.modelModuleIds"
              :addons="modules"
              :label="$t('actions.addModule')"
              :initial-addons="vehicle.modelModuleIds"
              :modifiable="modifiable"
            />
          </fieldset>
          <Loader :loading="loadingModules" />
        </div>
      </div>
      <div class="flex-row">
        <div
          class="col-xs-12"
        >
          <fieldset v-if="upgrades.length">
            <legend>
              <h3>{{ $t('labels.model.upgrades') }}:</h3>
            </legend>
            <Addons
              v-model="form.modelUpgradeIds"
              :addons="upgrades"
              :label="$t('actions.addUpgrade')"
              :initial-addons="vehicle.modelModuleIds"
              :modifiable="modifiable"
            />
          </fieldset>
        </div>
        <Loader :loading="loadingUpgrades" />
      </div>
    </form>
    <template
      v-if="modifiable"
      #footer
    >
      <div class="pull-right">
        <Btn
          :form="`vehicle-addons-${vehicle.id}`"
          :loading="submitting"
          type="submit"
          size="large"
          inline
        >
          {{ $t('actions.save') }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script>
import Btn from 'frontend/components/Btn'
import Modal from 'frontend/components/Modal'
import Loader from 'frontend/components/Loader'
import Addons from './Addons'

export default {
  components: {
    Btn,
    Modal,
    Loader,
    Addons,
  },

  props: {
    visible: {
      type: Boolean,
      default: false,
    },

    modifiable: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      modules: [],
      vehicle: null,
      loadingModules: false,
      upgrades: [],
      loadingUpgrades: false,
      submitting: false,
      form: {},
    }
  },

  watch: {
    vehicle() {
      this.form = {
        modelModuleIds: [...this.vehicle.modelModuleIds],
        modelUpgradeIds: [...this.vehicle.modelUpgradeIds],
      }
    },
  },

  methods: {
    selectedUpgrade(upgradeId) {
      return this.form.modelUpgradeIds.includes(upgradeId)
    },

    open(vehicle) {
      this.vehicle = vehicle
      this.form = {
        modelModuleIds: [...this.vehicle.modelModuleIds],
        modelUpgradeIds: [...this.vehicle.modelUpgradeIds],
      }
      this.$nextTick(() => {
        this.$refs.modal.open()
      })
    },

    changeUpgrade(upgrade) {
      if (!this.modifiable) {
        return
      }

      if (this.form.modelUpgradeIds.includes(upgrade.id)) {
        const index = this.form.modelUpgradeIds.findIndex((upgradeId) => upgradeId === upgrade.id)
        if (index > -1) {
          this.form.modelUpgradeIds.splice(index, 1)
        }
      } else {
        this.form.modelUpgradeIds.push(upgrade.id)
      }
    },

    async save() {
      if (!this.modifiable) {
        return
      }

      this.submitting = true
      const response = await this.$api.put(`vehicles/${this.vehicle.id}`, this.form)
      this.submitting = false
      if (!response.error) {
        this.$refs.modal.close()
        this.$comlink.$emit('vehicleSave', response.data)
      }
    },

    async fetch() {
      await this.fetchModules()
      await this.fetchUpgrades()
    },

    async fetchModules() {
      this.loadingModules = true
      const response = await this.$api.get(`models/${this.vehicle.model.slug}/modules`)
      this.loadingModules = false
      if (!response.error) {
        this.modules = response.data
      }
    },

    async fetchUpgrades() {
      this.loadingUpgrades = true
      const response = await this.$api.get(`models/${this.vehicle.model.slug}/upgrades`)
      this.loadingUpgrades = false
      if (!response.error) {
        this.upgrades = response.data
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
