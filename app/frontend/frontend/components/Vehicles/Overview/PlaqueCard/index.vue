<script lang="ts">
export default {
  name: "VehicleOverviewPlaqueCard",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import PlaqueDownloadBtn from "@/frontend/components/Vehicles/PlaqueDownloadBtn/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { plaqueShareUrl } from "@/frontend/components/Vehicles/Plaque/shareUrl";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
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

// Shared only where anyone could see it anyway: a public ship in a public
// hangar.
const shareUrl = computed(() =>
  props.vehicle.public && currentUser?.value?.publicHangar
    ? plaqueShareUrl(currentUser.value.username, {
        id: props.vehicle.id,
        name: props.vehicle.nameVisible ? props.vehicle.name : undefined,
        serial: props.vehicle.nameVisible ? props.vehicle.serial : undefined,
      })
    : undefined,
);

const openEditModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/PlaqueEditModal/index.vue"),
    props: { vehicle: props.vehicle },
    wide: true,
  });
};
</script>

<template>
  <div
    v-if="vehicle.dedication"
    class="overview-plaque"
    data-test="vehicle-overview-plaque"
  >
    <VehiclePlaque :vehicle="vehicle" :captain="currentUser?.username" />
    <div class="overview-plaque__actions">
      <Btn
        v-tooltip="t('actions.vehiclePlaque.edit')"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        :aria-label="t('actions.vehiclePlaque.edit')"
        data-test="vehicle-plaque-edit"
        @click="openEditModal"
      >
        <i class="fa-light fa-pen" />
      </Btn>
      <PlaqueDownloadBtn
        :element="`vehicle-plaque-${vehicle.id}`"
        :filename="`plaque-${vehicle.serial || vehicle.model.slug}`"
        :with-label="false"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        data-test="vehicle-plaque-download"
      />
      <ShareBtn
        v-if="shareUrl"
        :url="shareUrl"
        :title="t('headlines.vehiclePlaque.title')"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        no-label
        data-test="vehicle-plaque-share"
      />
    </div>
  </div>
  <div
    v-else
    class="overview-plaque-invite"
    data-test="vehicle-overview-plaque"
  >
    <p class="text-muted" data-test="vehicle-plaque-empty">
      {{ t("texts.vehiclePlaque.empty") }}
    </p>
    <Btn
      :size="BtnSizesEnum.SM"
      :variant="BtnVariantsEnum.BARE"
      data-test="vehicle-plaque-edit"
      @click="openEditModal"
    >
      <i class="fa-light fa-pen" />
      {{ t("actions.vehiclePlaque.edit") }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
.overview-plaque {
  position: relative;

  &__actions {
    position: absolute;
    top: 14px;
    right: 14px;
    display: flex;
    gap: 2px;
    border-radius: 6px;
    background: rgb(0 0 0 / 0.55);
    opacity: 0;
    transition: opacity 150ms ease;
  }

  &:hover &__actions,
  &:focus-within &__actions {
    opacity: 1;
  }

  // Nothing hovers on a touch screen, so the buttons stay put there.
  @media (hover: none) {
    &__actions {
      opacity: 1;
    }
  }
}

.overview-plaque-invite {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 8px;
  padding: 16px;
  border: 1px dashed var(--color-edge-soft);
  border-radius: 6px;

  p {
    margin: 0;
  }
}
</style>
