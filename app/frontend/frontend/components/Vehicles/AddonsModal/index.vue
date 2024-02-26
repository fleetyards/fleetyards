<template>
  <Modal
    v-if="vehicle && form"
    :title="t('headlines.myVehicleAddons', { vehicle: vehicle.model.name })"
  >
    <form
      :id="`vehicle-addons-${vehicle.id}`"
      class="addons"
      @submit.prevent="save"
    >
      <div class="row">
        <div class="col-12">
          <AsyncData
            :fullscreen="false"
            :async-status="modulePackagesAsyncStatus"
          >
            <template #resolved>
              <fieldset v-if="modulePackages?.items.length">
                <legend>
                  <h3>{{ t("labels.model.modulePackages") }}:</h3>
                </legend>
                <Packages
                  v-model="form.modelModuleIds"
                  :packages="modulePackages?.items"
                  :editable="editable"
                />
              </fieldset>
            </template>
          </AsyncData>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <AsyncData :fullscreen="false" :async-status="modulesAsyncStatus">
            <template #resolved>
              <fieldset v-if="modules?.items.length">
                <legend>
                  <h3>{{ t("labels.model.modules") }}:</h3>
                </legend>
                <Addons
                  v-model="form.modelModuleIds"
                  :addons="modules.items"
                  :label="t('actions.addModule')"
                  :initial-addons="vehicle.modelModuleIds"
                  :editable="editable"
                />
              </fieldset>
            </template>
          </AsyncData>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <AsyncData :fullscreen="false" :async-status="upgradesAsyncStatus">
            <template #resolved>
              <fieldset v-if="upgrades?.length">
                <legend>
                  <h3>{{ t("labels.model.upgrades") }}:</h3>
                </legend>
                <Addons
                  v-model="form.modelUpgradeIds"
                  :addons="upgrades"
                  :label="t('actions.addUpgrade')"
                  :initial-addons="vehicle.modelModuleIds"
                  :editable="editable"
                />
              </fieldset>
            </template>
          </AsyncData>
        </div>
      </div>
    </form>
    <template v-if="editable" #footer>
      <div class="float-sm-right">
        <Btn
          :form="`vehicle-addons-${vehicle.id}`"
          :loading="updateMutation.isPending.value"
          type="submit"
          size="large"
          :inline="true"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import Addons from "./Addons/index.vue";
import Packages from "./Packages/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { VehicleUpdateInput, type Vehicle } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useVehicleQueries } from "@/frontend/composables/useVehicleQueries";
import { useModelQueries } from "@/frontend/composables/useModelQueries";

type Props = {
  vehicle: Vehicle;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
});

const { t } = useI18n();

const form = ref<VehicleUpdateInput>({
  modelModuleIds: [],
  modelUpgradeIds: [],
});

onMounted(() => {
  setupForm();
});

watch(
  () => props.vehicle,
  () => {
    setupForm();
  },
);

const setupForm = () => {
  form.value = {
    modelModuleIds: [...props.vehicle.modelModuleIds],
    modelUpgradeIds: [...props.vehicle.modelUpgradeIds],
  };
};

const { modulePackagesQuery, modulesQuery, upgradesQuery } = useModelQueries(
  props.vehicle.model,
);

const { data: modulePackages, ...modulePackagesAsyncStatus } =
  modulePackagesQuery();

const { data: modules, ...modulesAsyncStatus } = modulesQuery();

const { data: upgrades, ...upgradesAsyncStatus } = upgradesQuery();

const comlink = useComlink();

const { updateMutation } = useVehicleQueries(props.vehicle);

const save = async () => {
  if (!props.editable || !form.value) {
    return;
  }

  updateMutation.mutate(form.value, {
    onSuccess: () => {
      comlink.emit("close-modal");
    },
  });
};
</script>

<script lang="ts">
export default {
  name: "AddonsModal",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
