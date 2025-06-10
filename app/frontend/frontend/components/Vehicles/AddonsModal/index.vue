<script lang="ts">
export default {
  name: "AddonsModal",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useForm } from "vee-validate";
import Addons from "./Addons/index.vue";
import Packages from "./Packages/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { VehicleUpdateInput, type Vehicle } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";
import {
  useModelModules as useModelModulesQuery,
  useModelModulePackages as useModelModulePackagesQuery,
  useModelUpgrades as useModelUpgradesQuery,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
});

const { t } = useI18n();

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
  initialValues.value = {
    modelModuleIds: [...props.vehicle.modelModuleIds],
    modelUpgradeIds: [...props.vehicle.modelUpgradeIds],
  };
};

const initialValues = ref<VehicleUpdateInput>({
  modelModuleIds: [...props.vehicle.modelModuleIds],
  modelUpgradeIds: [...props.vehicle.modelUpgradeIds],
});

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [modelModuleIds] = defineField("modelModuleIds");
const [modelUpgradeIds] = defineField("modelUpgradeIds");

const { data: modulePackages, ...modulePackagesAsyncStatus } =
  useModelModulePackagesQuery(props.vehicle.model.slug);

const { data: modules, ...modulesAsyncStatus } = useModelModulesQuery(
  props.vehicle.model.slug,
);

const { data: upgrades, ...upgradesAsyncStatus } = useModelUpgradesQuery(
  props.vehicle.model.slug,
);

const comlink = useComlink();

const { useUpdateMutation } = useVehicleMutations();

const vehicle = computed(() => props.vehicle);

const mutation = useUpdateMutation(vehicle);

const onSubmit = handleSubmit(async (values) => {
  if (!props.editable || !values) {
    return;
  }

  await mutation
    .mutateAsync({
      id: props.vehicle.id,
      data: values,
    })
    .then(() => {
      comlink.emit("close-modal");
    });
});
</script>

<template>
  <Modal
    v-if="vehicle"
    :title="t('headlines.myVehicleAddons', { vehicle: vehicle.model.name })"
  >
    <form
      :id="`vehicle-addons-${vehicle.id}`"
      class="addons"
      @submit.prevent="onSubmit"
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
                  v-model="modelModuleIds"
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
                  v-model="modelModuleIds"
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
                  v-model="modelUpgradeIds"
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
          :loading="mutation.isPending.value"
          :type="BtnTypesEnum.SUBMIT"
          :size="BtnSizesEnum.SMALL"
          :inline="true"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
