<template>
  <Modal
    ref="modal"
    :title="t('headlines.myVehicleAddons', { vehicle: vehicle.model.name })"
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
              <h3>{{ t('labels.model.modules') }}:</h3>
            </legend>
            <div class="row">
              <div
                v-for="module in modules"
                :key="module.id"
                class="col-xs-12 modules"
              >
                <Panel>
                  <div
                    class="model-panel"
                    @click.capture="changeModule(module)"
                  >
                    <div
                      :style="{
                        'background-image': `url(${module.storeImage})`
                      }"
                      class="model-panel-image"
                    />
                    <div class="model-panel-body">
                      <h3>{{ module.name }}</h3>
                    </div>
                    <div
                      v-if="selectedModule(module.id)"
                      v-tooltip="t('labels.selected')"
                      class="model-panel-selected"
                    >
                      <i class="fa fa-check" />
                    </div>
                  </div>
                </Panel>
              </div>
            </div>
          </fieldset>
          <Loader :loading="loadingModules" />
        </div>
      </div>
      <div class="row">
        <div
          class="col-xs-12"
        >
          <fieldset v-if="upgrades.length">
            <legend>
              <h3>{{ t('labels.model.upgrades') }}:</h3>
            </legend>
            <div class="row">
              <div
                v-for="upgrade in upgrades"
                :key="upgrade.id"
                class="col-xs-12 upgrades"
              >
                <Panel>
                  <div
                    class="model-panel"
                    @click.capture="changeUpgrade(upgrade)"
                  >
                    <div
                      :style="{
                        'background-image': `url(${upgrade.storeImage})`
                      }"
                      class="model-panel-image"
                    />
                    <div class="model-panel-body">
                      <h3>{{ upgrade.name }}</h3>
                    </div>
                    <div
                      v-if="selectedUpgrade(upgrade.id)"
                      v-tooltip="t('labels.selected')"
                      class="model-panel-selected"
                    >
                      <i class="fa fa-check" />
                    </div>
                  </div>
                </Panel>
              </div>
            </div>
          </fieldset>
        </div>
        <Loader :loading="loadingUpgrades" />
      </div>
    </form>
    <template slot="footer">
      <div class="pull-right">
        <SubmitButton
          :form="`vehicle-addons-${vehicle.id}`"
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
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'

export default {
  components: {
    SubmitButton,
    Modal,
    Loader,
    Panel,
  },
  mixins: [I18n],
  props: {
    vehicle: {
      type: Object,
      required: true,
    },
    visible: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      modules: [],
      loadingModules: false,
      upgrades: [],
      loadingUpgrades: false,
      submitting: false,
      form: {
        modelModuleIds: this.vehicle.modelModuleIds,
        modelUpgradeIds: this.vehicle.modelUpgradeIds,
      },
    }
  },
  watch: {
    vehicle() {
      this.form = {
        modelModuleIds: this.vehicle.modelModuleIds,
        modelUpgradeIds: this.vehicle.modelUpgradeIds,
      }
    },
  },
  methods: {
    selectedModule(moduleId) {
      return this.form.modelModuleIds.includes(moduleId)
    },
    selectedUpgrade(upgradeId) {
      return this.form.modelUpgradeIds.includes(upgradeId)
    },
    open() {
      this.$refs.modal.open()
    },
    changeModule(module) {
      if (this.form.modelModuleIds.includes(module.id)) {
        const index = this.form.modelModuleIds.findIndex(moduleId => moduleId === module.id)
        if (index > -1) {
          this.form.modelModuleIds.splice(index, 1)
        }
      } else {
        this.form.modelModuleIds.push(module.id)
      }
    },
    changeUpgrade(upgrade) {
      if (this.form.modelUpgradeIds.includes(upgrade.id)) {
        const index = this.form.modelUpgradeIds.findIndex(upgradeId => upgradeId === upgrade.id)
        if (index > -1) {
          this.form.modelUpgradeIds.splice(index, 1)
        }
      } else {
        this.form.modelUpgradeIds.push(upgrade.id)
      }
    },
    async save() {
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
  @import "./styles/index";
</style>
