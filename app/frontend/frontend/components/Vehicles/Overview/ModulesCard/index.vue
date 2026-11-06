<script lang="ts">
export default {
  name: "VehicleOverviewModulesCard",
};
</script>

<script lang="ts" setup>
import { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import Addons from "@/frontend/components/Vehicles/EditModal/Addons/index.vue";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { useVehicleModuleCatalogue } from "@/frontend/composables/useVehicleModuleCatalogue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

const hasModules = computed(() => !!props.vehicle.model.hasModules);

// The modal offers its modules tab under the same conditions.
const editable = computed(() => !props.vehicle.loaner && !props.vehicle.wanted);

const visible = computed(
  () =>
    hasModules.value &&
    (editable.value || props.vehicle.modelModuleIds.length > 0),
);

const {
  data: modules,
  isLoading,
  isError,
  isPlaceholderData,
} = useVehicleModuleCatalogue(() => props.vehicle, visible);

// A placeholder is the previous ship's catalogue, which this ship's modules
// would not be found in.
const pending = computed(() => isLoading.value || isPlaceholderData.value);

// A failed refetch keeps the list it already has.
const failed = computed(() => isError.value && !modules.value);

const { openEditModal } = useVehicleModals();

const openEditor = () =>
  openEditModal(props.vehicle, { tab: VehicleEditTabsEnum.MODULES });
</script>

<template>
  <!-- Hidden on a failed request: an empty list would claim the ship has no
       modules. -->
  <MetricsCard
    v-if="visible && !failed"
    :title="t('labels.vehicleOverview.ownedModules')"
    :loading="pending"
    variant="slim"
    data-test="vehicle-overview-modules"
  >
    <template #head>
      <Btn
        v-if="editable"
        :size="BtnSizesEnum.SM"
        data-test="vehicle-overview-modules-edit"
        @click="openEditor"
      >
        {{ t("actions.vehicleOverview.editModules") }}
      </Btn>
    </template>
    <Addons
      v-if="!pending"
      :model-value="vehicle.modelModuleIds"
      :addons="modules?.items ?? []"
      :empty-label="t('labels.vehicleOverview.noModules')"
    />
  </MetricsCard>
</template>
