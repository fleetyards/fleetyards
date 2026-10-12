<script lang="ts">
export default {
  name: "VehicleOverviewVisibilityCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { type Vehicle, type VehicleUpdateInput } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();

const vehicle = computed(() => props.vehicle);

const { useUpdateMutation } = useVehicleMutations();
const updateMutation = useUpdateMutation(vehicle);

type Setting = {
  key: keyof VehicleUpdateInput & keyof Vehicle;
  label: string;
};

// Sale alerts only ever go out for a ship on the wishlist, and a wishlist ship
// is never in the public hangar, so each ship is offered the switches that do
// something for it.
const settings = computed<Setting[]>(() =>
  props.vehicle.wanted
    ? [
        { key: "saleNotify", label: t("labels.vehicle.saleNotify") },
        {
          key: "logEntriesPublicByDefault",
          label: t("labels.vehicleLog.publicByDefault"),
        },
      ]
    : [
        { key: "public", label: t("labels.vehicleOverview.showPublic") },
        { key: "nameVisible", label: t("labels.vehicleOverview.showName") },
        {
          key: "logEntriesPublicByDefault",
          label: t("labels.vehicleLog.publicByDefault"),
        },
      ],
);

const update = async (key: Setting["key"], value: boolean) => {
  await updateMutation
    .mutateAsync({ id: props.vehicle.id, data: { [key]: value } })
    .catch(() => {
      displayAlert({ text: t("messages.vehicleOverview.setting.failure") });
    });
};
</script>

<template>
  <MetricsCard
    :title="t('labels.vehicleOverview.visibility')"
    variant="slim"
    data-test="vehicle-overview-visibility"
  >
    <div class="overview-visibility">
      <FormToggle
        v-for="setting in settings"
        :key="setting.key"
        :model-value="!!vehicle[setting.key]"
        :name="setting.key"
        :label="setting.label"
        :disabled="updateMutation.isPending.value"
        :data-test="`vehicle-setting-${setting.key}`"
        @update:model-value="update(setting.key, $event)"
      />
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
.overview-visibility {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
</style>
