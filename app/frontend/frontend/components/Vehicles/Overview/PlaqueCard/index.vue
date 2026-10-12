<script lang="ts">
export default {
  name: "VehicleOverviewPlaqueCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import DownloadScreenshotBtn from "@/frontend/components/DownloadScreenshotBtn/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { storeToRefs } from "pinia";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { type Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { currentUser } = storeToRefs(useSessionStore());

const openEditModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/PlaqueEditModal/index.vue"),
    props: { vehicle: props.vehicle },
  });
};
</script>

<template>
  <MetricsCard
    :title="t('labels.vehiclePlaque.title')"
    variant="slim"
    data-test="vehicle-overview-plaque"
  >
    <div class="overview-plaque">
      <VehiclePlaque
        v-if="vehicle.dedication"
        :vehicle="vehicle"
        :captain="currentUser?.username"
      />
      <p v-else class="text-muted" data-test="vehicle-plaque-empty">
        {{ t("texts.vehiclePlaque.empty") }}
      </p>
      <div class="overview-plaque__actions">
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.GHOST"
          data-test="vehicle-plaque-edit"
          @click="openEditModal"
        >
          <i class="fa-light fa-pen" />
          {{ t("actions.vehiclePlaque.edit") }}
        </Btn>
        <DownloadScreenshotBtn
          v-if="vehicle.dedication"
          :element="`#vehicle-plaque-${vehicle.id}`"
          :filename="`plaque-${vehicle.serial || vehicle.model.slug}`"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.GHOST"
          data-test="vehicle-plaque-download"
        />
      </div>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
.overview-plaque {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 12px;

  > :first-child {
    align-self: stretch;
  }

  &__actions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }
}
</style>
