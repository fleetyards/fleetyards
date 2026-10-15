<script lang="ts">
export default {
  name: "VehicleEditModalModules",
};
</script>

<script lang="ts" setup>
import { useField } from "vee-validate";
import AsyncData from "@/shared/components/AsyncData.vue";
import Addons from "../Addons/index.vue";
import Packages from "../Packages/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Vehicle,
  useModelModules as useModelModulesQuery,
  useModelModulePackages as useModelModulePackagesQuery,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

// What the ship owns. Which of these is fitted is a loadout's business.
const { value: modelModuleIds } = useField<string[]>("modelModuleIds");

const modelSlug = computed(() => props.vehicle.model?.slug ?? "");

const { data: modulePackages, ...modulePackagesAsyncStatus } =
  useModelModulePackagesQuery(modelSlug);

const { data: modulesData, ...modulesAsyncStatus } =
  useModelModulesQuery(modelSlug);

const packages = computed(() => modulePackages.value?.items ?? []);
const modules = computed(() => modulesData.value?.items ?? []);
</script>

<template>
  <div class="vehicle-edit-modules">
    <AsyncData :async-status="modulePackagesAsyncStatus">
      <template #resolved>
        <fieldset v-if="packages.length">
          <legend>
            <h3>{{ t("labels.model.modulePackages") }}</h3>
            <span class="vehicle-edit-modules__hint">
              {{ t("addon.packages.hint") }}
            </span>
          </legend>
          <Packages v-model="modelModuleIds" :packages="packages" editable />
        </fieldset>
      </template>
    </AsyncData>

    <AsyncData :async-status="modulesAsyncStatus">
      <template #resolved>
        <fieldset>
          <legend>
            <h3>{{ t("labels.vehicleLoadout.ownedModules") }}</h3>
          </legend>
          <Addons
            v-model="modelModuleIds"
            :addons="modules"
            editable
            :empty-label="t('addon.empty.modules')"
          />
        </fieldset>
      </template>
    </AsyncData>
  </div>
</template>

<style lang="scss" scoped>
.vehicle-edit-modules {
  display: flex;
  flex-direction: column;
  gap: 24px;

  fieldset {
    min-width: 0;

    legend {
      display: flex;
      flex-wrap: wrap;
      align-items: baseline;
      gap: 4px 10px;
      width: 100%;
      margin-bottom: 10px;
      border: none;

      h3 {
        margin-bottom: 0;
      }
    }
  }

  /*
   * Says what pressing a package row does, because it replaces the module
   * selection rather than adding to it — which is not something a row of images
   * can show on its own.
   */
  &__hint {
    color: var(--color-text-dim);
    font-size: 13px;
  }
}
</style>
