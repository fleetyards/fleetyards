<template>
  <Modal
    v-if="vehicle && form"
    :title="$t('headlines.myVehicleAddons', { vehicle: vehicle.model.name })"
  >
    <form
      :id="`vehicle-addons-${vehicle.id}`"
      class="addons"
      @submit.prevent="save"
    >
      <div v-if="modelModulePackagesCollection.records.length" class="row">
        <div class="col-12">
          <fieldset>
            <legend>
              <h3>{{ $t("labels.model.modulePackages") }}:</h3>
            </legend>
            <Packages
              v-model="form.modelModuleIds"
              :packages="modelModulePackagesCollection.records"
              :editable="editable"
            />
          </fieldset>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <fieldset v-if="modelModulesCollection.records.length">
            <legend>
              <h3>{{ $t("labels.model.modules") }}:</h3>
            </legend>
            <Addons
              v-model="form.modelModuleIds"
              :addons="modelModulesCollection.records"
              :label="$t('actions.addModule')"
              :initial-addons="vehicle.modelModuleIds"
              :editable="editable"
            />
          </fieldset>
          <Loader :loading="modelModulesCollection.loading" />
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <fieldset v-if="modelUpgradesCollection.records.length">
            <legend>
              <h3>{{ $t("labels.model.upgrades") }}:</h3>
            </legend>
            <Addons
              v-model="form.modelUpgradeIds"
              :addons="modelUpgradesCollection.records"
              :label="$t('actions.addUpgrade')"
              :initial-addons="vehicle.modelModuleIds"
              :editable="editable"
            />
          </fieldset>
        </div>
        <Loader :loading="modelUpgradesCollection.loading" />
      </div>
    </form>
    <template v-if="editable" #footer>
      <div class="float-sm-right">
        <Btn
          :form="`vehicle-addons-${vehicle.id}`"
          :loading="submitting"
          type="submit"
          size="large"
          :inline="true"
        >
          {{ $t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop, Watch } from "vue-property-decorator";
import Btn from "@/frontend/core/components/Btn/index.vue";
import Modal from "@/frontend/core/components/AppModal/Inner/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import modelModulesCollection from "@/frontend/api/collections/ModelModules";
import modelModulePackagesCollection from "@/frontend/api/collections/ModelModulePackages";
import modelUpgradesCollection from "@/frontend/api/collections/ModelUpgrades";
import Addons from "./Addons/index.vue";
import Packages from "./Packages/index.vue";

type AddonsForm = {
  modelModuleIds: string[];
  modelUpgradeIds: string[];
};

@Component<AddonsModal>({
  components: {
    Btn,
    Modal,
    Loader,
    Panel,
    Addons,
    Packages,
  },
})
export default class AddonsModal extends Vue {
  @Prop({ required: true }) vehicle: Vehicle;

  @Prop({ default: false }) editable: boolean;

  modelModulesCollection: ModelModulesCollection = modelModulesCollection;

  modelModulePackagesCollection: ModelModulePackagesCollection =
    modelModulePackagesCollection;

  modelUpgradesCollection: ModelUpgradesCollection = modelUpgradesCollection;

  submitting = false;

  form: AddonsForm | null = null;

  mounted() {
    this.fetch();

    this.setupForm();
  }

  @Watch("vehicle")
  onVehicleChange() {
    this.setupForm();
  }

  setupForm() {
    this.form = {
      modelModuleIds: [...this.vehicle.modelModuleIds],
      modelUpgradeIds: [...this.vehicle.modelUpgradeIds],
    };
  }

  selectedUpgrade(upgradeId) {
    return this.form.modelUpgradeIds.includes(upgradeId);
  }

  changeUpgrade(upgrade) {
    if (!this.editable) {
      return;
    }

    if (this.form.modelUpgradeIds.includes(upgrade.id)) {
      const index = this.form.modelUpgradeIds.findIndex(
        (upgradeId) => upgradeId === upgrade.id,
      );
      if (index > -1) {
        this.form.modelUpgradeIds.splice(index, 1);
      }
    } else {
      this.form.modelUpgradeIds.push(upgrade.id);
    }
  }

  async save() {
    if (!this.editable) {
      return;
    }

    this.submitting = true;
    const response = await this.$api.put(
      `vehicles/${this.vehicle.id}`,
      this.form,
    );
    this.submitting = false;
    if (!response.error) {
      this.$comlink.$emit("vehicle-save", response.data);
      this.$comlink.$emit("close-modal");
    }
  }

  async fetch() {
    await modelModulesCollection.findAll(this.vehicle.model.slug);
    await modelModulePackagesCollection.findAll(this.vehicle.model.slug);
    await modelUpgradesCollection.findAll(this.vehicle.model.slug);
  }

  activatePackage(addonPackage) {
    if (!this.editable) {
      return;
    }

    addonPackage.modules.forEach((module) => {
      const additionalPackageModules = addonPackage.modules.filter(
        (packageModule) => packageModule.id === module.id,
      );
      const foundModules = this.form.modelModuleIds.filter(
        (id) => id === module.id,
      );

      if (
        !foundModules.length ||
        foundModules.length < additionalPackageModules.length
      ) {
        this.form.modelModuleIds.push(module.id);
      }
    });
  }
}
</script>

<style lang="scss" scoped>
@import "index";
</style>
