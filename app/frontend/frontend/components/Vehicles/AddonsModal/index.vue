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

const currentAddons = (): VehicleUpdateInput => ({
  modelModuleIds: [...props.vehicle.modelModuleIds],
  modelUpgradeIds: [...props.vehicle.modelUpgradeIds],
});

const { defineField, handleSubmit, resetForm, meta } =
  useForm<VehicleUpdateInput>({
    initialValues: currentAddons(),
  });

/**
 * Re-seeds the fields rather than the initial values, which vee-validate has
 * already copied by this point: reassigning those did nothing at all, so the
 * modal kept answering for whichever ship it was first opened for.
 *
 * A pending choice wins over the refresh, or a background refetch of the hangar
 * would discard what you had just picked and not yet saved.
 */
watch(
  () => props.vehicle,
  () => {
    if (meta.value.dirty) {
      return;
    }

    resetForm({ values: currentAddons() });
  },
);

const [modelModuleIds] = defineField("modelModuleIds");
const [modelUpgradeIds] = defineField("modelUpgradeIds");

const modelSlug = computed(() => props.vehicle?.model?.slug ?? "");

const { data: modulePackages, ...modulePackagesAsyncStatus } =
  useModelModulePackagesQuery(modelSlug);

const { data: modulesData, ...modulesAsyncStatus } =
  useModelModulesQuery(modelSlug);

const { data: upgradesData, ...upgradesAsyncStatus } =
  useModelUpgradesQuery(modelSlug);

// Three endpoints, three shapes: modules and packages come back paginated under
// `items`, upgrades as a bare array.
const packages = computed(() => modulePackages.value?.items ?? []);
const modules = computed(() => modulesData.value?.items ?? []);
const upgrades = computed(() => upgradesData.value ?? []);

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
    :title="t('headlines.myVehicleAddons', { vehicle: vehicle?.model?.name })"
  >
    <form
      :id="`vehicle-addons-${vehicle.id}`"
      class="addons"
      @submit.prevent="onSubmit"
    >
      <AsyncData :fullscreen="false" :async-status="modulePackagesAsyncStatus">
        <template #resolved>
          <fieldset v-if="packages.length">
            <legend>
              <h3>{{ t("labels.model.modulePackages") }}</h3>
              <span v-if="editable" class="addons__hint">
                {{ t("addon.packages.hint") }}
              </span>
            </legend>
            <Packages
              v-model="modelModuleIds"
              :packages="packages"
              :editable="editable"
            />
          </fieldset>
        </template>
      </AsyncData>

      <AsyncData :fullscreen="false" :async-status="modulesAsyncStatus">
        <template #resolved>
          <fieldset v-if="modules.length">
            <legend>
              <h3>{{ t("labels.model.modules") }}</h3>
            </legend>
            <Addons
              v-model="modelModuleIds"
              :addons="modules"
              :editable="editable"
              :empty-label="t('addon.empty.modules')"
            />
          </fieldset>
        </template>
      </AsyncData>

      <AsyncData :fullscreen="false" :async-status="upgradesAsyncStatus">
        <template #resolved>
          <fieldset v-if="upgrades.length">
            <legend>
              <h3>{{ t("labels.model.upgrades") }}</h3>
            </legend>
            <Addons
              v-model="modelUpgradeIds"
              :addons="upgrades"
              :editable="editable"
              :empty-label="t('addon.empty.upgrades')"
            />
          </fieldset>
        </template>
      </AsyncData>
    </form>
    <template v-if="editable" #footer>
      <div class="modal-actions">
        <Btn :loading="mutation.isPending.value" @click="onSubmit">
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
