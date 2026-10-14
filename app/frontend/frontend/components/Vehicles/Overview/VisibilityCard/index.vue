<script lang="ts">
export default {
  name: "VehicleOverviewVisibilityCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle, type VehicleUpdateInput } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

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

const { openEditModal } = useVehicleModals();

const openVisibility = () =>
  openEditModal(props.vehicle, { tab: VehicleEditTabsEnum.VISIBILITY });
</script>

<template>
  <MetricsCard
    :title="t('labels.vehicleOverview.visibility')"
    variant="slim"
    data-test="vehicle-overview-visibility"
  >
    <template #head>
      <Btn
        :size="BtnSizesEnum.SM"
        :aria-label="t('actions.edit')"
        data-test="vehicle-visibility-edit"
        @click="openVisibility"
      >
        <i class="fa-duotone fa-pencil" />
        {{ t("actions.edit") }}
      </Btn>
    </template>
    <dl class="overview-visibility">
      <div
        v-for="setting in settings"
        :key="setting.key"
        class="overview-visibility__setting"
      >
        <dt>{{ setting.label }}</dt>
        <dd :data-test="`vehicle-setting-${setting.key}`">
          {{
            vehicle[setting.key] ? t("labels.enabled") : t("labels.disabled")
          }}
        </dd>
      </div>
    </dl>
  </MetricsCard>
</template>

<style lang="scss" scoped>
.overview-visibility {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin: 0;

  &__setting {
    display: flex;
    justify-content: space-between;
    gap: 16px;
  }

  dt,
  dd {
    margin: 0;
  }
}
</style>
