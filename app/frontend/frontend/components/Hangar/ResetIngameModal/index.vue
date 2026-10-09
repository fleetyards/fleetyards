<script lang="ts">
export default {
  name: "HangarResetIngameModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useMoveAllIngameToWishlist as useMoveAllIngameToWishlistMutation,
  useDestroyAllIngameVehicles as useDestroyAllIngameVehiclesMutation,
} from "@/services/fyApi";

const { displaySuccess, displayAlert } = useAppNotifications();

const { t } = useI18n();

const comlink = useComlink();

const moveToWishlistMutation = useMoveAllIngameToWishlistMutation();

const moveToWishlist = async () => {
  await moveToWishlistMutation
    .mutateAsync()
    .then(() => {
      displaySuccess({
        text: t("messages.vehicle.resetIngame.moveToWishlist.success"),
      });

      comlink.emit("close-modal");
    })
    .catch(() => {
      displayAlert({
        text: t("messages.vehicle.resetIngame.moveToWishlist.failure"),
      });
    });
};

const destroyAllIngameMutation = useDestroyAllIngameVehiclesMutation();

const removeAll = async () => {
  await destroyAllIngameMutation
    .mutateAsync()
    .then(() => {
      displaySuccess({
        text: t("messages.vehicle.resetIngame.removeAll.success"),
      });

      comlink.emit("close-modal");
    })
    .catch(() => {
      displayAlert({
        text: t("messages.vehicle.resetIngame.removeAll.failure"),
      });
    });
};

// Both act on the same vehicles, so neither may start while the other runs.
const busy = computed(
  () =>
    moveToWishlistMutation.isPending.value ||
    destroyAllIngameMutation.isPending.value,
);
</script>

<template>
  <Modal :title="t('headlines.hangar.resetIngame')">
    <p>{{ t("texts.resetIngame.info") }}</p>
    <template #footer>
      <Btn
        :loading="moveToWishlistMutation.isPending.value"
        :disabled="busy"
        data-test="reset-ingame-modal-reset-to-wishlist"
        @click="moveToWishlist"
      >
        {{ t("actions.hangar.resetIngame.moveToWishlist") }}
      </Btn>
      <Btn
        :tone="BtnTonesEnum.DANGER"
        :confirm="t('messages.vehicle.resetIngame.removeAll.confirm')"
        :loading="destroyAllIngameMutation.isPending.value"
        :disabled="busy"
        data-test="reset-ingame-modal-reset"
        @click="removeAll"
      >
        {{ t("actions.hangar.resetIngame.removeAll") }}
      </Btn>
    </template>
  </Modal>
</template>
