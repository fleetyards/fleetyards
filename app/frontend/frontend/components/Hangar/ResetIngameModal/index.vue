<script lang="ts">
export default {
  name: "HangarResetIngameModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
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
</script>

<template>
  <Modal :title="t('headlines.hangar.resetIngame')">
    <div class="page-actions page-actions-block">
      <Btn
        :inline="true"
        data-test="reset-ingame-modal-reset-to-wishlist"
        @click="moveToWishlist"
      >
        {{ t("actions.hangar.resetIngame.moveToWishlist") }}
      </Btn>
      <Btn
        :inline="true"
        data-test="reset-ingame-modal-reset"
        @click="removeAll"
      >
        {{ t("actions.hangar.resetIngame.removeAll") }}
      </Btn>
    </div>
  </Modal>
</template>
