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
import { useNoty } from "@/shared/composables/useNoty";

const { displaySuccess, displayAlert } = useNoty();

const { t } = useI18n();

const comlink = useComlink();

const moveToWishlist = async () => {
  const success = await vehiclesCollection.ingameMoveToWishlist();

  if (success) {
    displaySuccess({
      text: t("messages.vehicle.resetIngame.moveToWishlist.success"),
    });

    comlink.emit("close-modal");
  } else {
    displayAlert({
      text: t("messages.vehicle.resetIngame.moveToWishlist.failure"),
    });
  }
};

const removeAll = async () => {
  const success = await vehiclesCollection.destroyAllIngame();

  if (success) {
    displaySuccess({
      text: t("messages.vehicle.resetIngame.removeAll.success"),
    });

    comlink.emit("close-modal");
  } else {
    displayAlert({
      text: t("messages.vehicle.resetIngame.removeAll.failure"),
    });
  }
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
