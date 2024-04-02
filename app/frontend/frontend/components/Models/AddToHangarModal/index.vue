<template>
  <Modal
    v-if="model"
    :title="t('headlines.addToHangar', { model: model.name })"
  >
    <div class="page-actions page-actions-block">
      <Btn
        :inline="true"
        data-test="add-to-hangar-as-normal"
        @click="addToHangar"
      >
        {{ t("actions.addToHangar") }}
      </Btn>
      <Btn
        :inline="true"
        data-test="add-to-hangar-as-wanted"
        @click="addToWishlist"
      >
        {{ t("actions.addToWishlist") }}
      </Btn>
    </div>
  </Modal>
</template>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import type { Model } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { useApiClient } from "@/frontend/composables/useApiClient";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displaySuccess } = useNoty();

const hangarStore = useHangarStore();
const wishlistStore = useWishlistStore();

const comlink = useComlink();

const { vehicles: vehiclesService } = useApiClient();

const addToWishlist = async () => {
  try {
    await vehiclesService.vehicleCreate({
      requestBody: {
        modelId: props.model.id,
        wanted: true,
      },
    });

    wishlistStore.add(props.model.slug);

    displaySuccess({
      text: t("messages.vehicle.addToWishlist.success", {
        model: props.model.name,
      }),
      icon: props.model.storeImageSmall,
    });

    comlink.emit("close-modal");
  } catch (error) {
    console.error(error);
  }
};

const addToHangar = async () => {
  try {
    await vehiclesService.vehicleCreate({
      requestBody: {
        modelId: props.model.id,
      },
    });

    hangarStore.add(props.model.slug);

    displaySuccess({
      text: t("messages.vehicle.add.success", {
        model: props.model.name,
      }),
      icon: props.model.storeImageSmall,
    });

    comlink.emit("close-modal");
  } catch (error) {
    console.error(error);
  }
};
</script>

<script lang="ts">
export default {
  name: "AddToHangarModal",
};
</script>
