<template>
  <Modal :title="t('headlines.hangar.resetIngame')">
    <div class="page-actions page-actions-block">
      <Btn
        :inline="true"
        data-test="reset-ingame-modal-reset-to-wishlist"
        @click.native="moveToWishlist"
      >
        {{ t("actions.hangar.resetIngame.moveToWishlist") }}
      </Btn>
      <Btn
        :inline="true"
        data-test="reset-ingame-modal-reset"
        @click.native="removeAll"
      >
        {{ t("actions.hangar.resetIngame.removeAll") }}
      </Btn>
    </div>
  </Modal>
</template>

<script lang="ts" setup>
import Modal from "@/frontend/core/components/AppModal/Inner/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { displaySuccess, displayAlert } from "@/frontend/lib/Noty";
import vehiclesCollection from "@/frontend/api/collections/Vehicles";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();

const comlink = useComlink();

const moveToWishlist = async () => {
  const success = await vehiclesCollection.ingameMoveToWishlist();

  if (success) {
    displaySuccess({
      text: t("messages.vehicle.resetIngame.moveToWishlist.success"),
    });

    comlink.$emit("close-modal");
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

    comlink.$emit("close-modal");
  } else {
    displayAlert({
      text: t("messages.vehicle.resetIngame.removeAll.failure"),
    });
  }
};
</script>

<script lang="ts">
export default {
  name: "VehiclesResetIngameModal",
};
</script>
