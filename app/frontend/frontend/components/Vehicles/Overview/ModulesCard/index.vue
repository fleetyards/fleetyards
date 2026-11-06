<script lang="ts">
export default {
  name: "VehicleOverviewModulesCard",
};
</script>

<script lang="ts" setup>
import { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import Addons from "@/frontend/components/Vehicles/EditModal/Addons/index.vue";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle, useModelModules } from "@/services/fyApi";

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

// An owned module beyond the first page of the catalogue would drop out of the
// list, so this asks for the largest page the endpoint serves.
const {
  data: modules,
  isLoading,
  isError,
} = useModelModules(
  () => props.vehicle.model.slug,
  { perPage: "100" },
  { query: { enabled: visible } },
);

const { openEditModal } = useVehicleModals();

const openEditor = () =>
  openEditModal(props.vehicle, { tab: VehicleEditTabsEnum.MODULES });
</script>

<template>
  <!-- Hidden on a failed request: an empty list would claim the ship has no
       modules. -->
  <MetricsCard
    v-if="visible && !isError"
    :title="t('labels.vehicleOverview.ownedModules')"
    :loading="isLoading"
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
      v-if="!isLoading"
      :model-value="vehicle.modelModuleIds"
      :addons="modules?.items ?? []"
      :empty-label="t('addon.empty.modules')"
    />
  </MetricsCard>
</template>
