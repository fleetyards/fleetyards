<script lang="ts">
export default { name: "LocationSetLocation" };
</script>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useUpdateProfile, type Location } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const props = defineProps<{ location: Location }>();
const session = useSessionStore();
const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();
const mutation = useUpdateProfile();

const setMyLocation = async () => {
  if (mutation.isPending.value) return;
  try {
    await mutation.mutateAsync({
      data: {
        currentLocationId: props.location.id,
        currentSystem: props.location.name ?? "",
      },
    });
    comlink.emit("user-update");
    displaySuccess({ text: t("labels.location.setLocationSuccess") });
  } catch {
    displayAlert({ text: t("labels.location.setLocationFailure") });
  }
};

const setShipLocation = () =>
  comlink.emit("open-modal", {
    component: () => import("./ShipModal/index.vue"),
    props: { location: props.location },
  });
</script>

<template>
  <BtnDropdown v-if="session.isAuthenticated" data-test="set-location">
    <template #label
      ><i class="fa-duotone fa-location-dot" />
      {{ t("labels.location.setLocation") }}</template
    >
    <Btn
      :loading="mutation.isPending.value"
      data-test="set-my-location"
      @click="setMyLocation"
    >
      <i class="fa-duotone fa-user" /> {{ t("labels.location.myLocation") }}
    </Btn>
    <Btn data-test="set-ship-location" @click="setShipLocation">
      <i class="fa-duotone fa-rocket" /> {{ t("labels.location.shipLocation") }}
    </Btn>
  </BtnDropdown>
</template>
