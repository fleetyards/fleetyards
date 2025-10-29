<script lang="ts">
export default {
  name: "AddToHangarModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import type { Model } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { useCreateVehicle as useCreateVehicleMutation } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displaySuccess } = useAppNotifications();

const hangarStore = useHangarStore();
const wishlistStore = useWishlistStore();

const comlink = useComlink();

const mutation = useCreateVehicleMutation();

const addToWishlist = async () => {
  await mutation
    .mutateAsync({
      data: {
        modelId: props.model.id,
        wanted: true,
      },
    })
    .then((vehicle) => {
      wishlistStore.add(props.model.slug);

      displaySuccess({
        text: t("messages.vehicle.addToWishlist.success.noHtml", {
          model: props.model.name,
        }),
        component: () =>
          import(
            "@/frontend/components/Models/AddToHangar/Notifications/Success/index.vue"
          ),
        componentProps: {
          vehicle: vehicle,
        },
        timeout: false,
      });

      comlink.emit("close-modal");
    })
    .catch((error) => {
      console.error(error);
    });
};

const addToHangar = async () => {
  await mutation
    .mutateAsync({
      data: {
        modelId: props.model.id,
      },
    })
    .then((vehicle) => {
      hangarStore.add(props.model.slug);

      displaySuccess({
        text: t("messages.vehicle.add.success.noHtml", {
          model: props.model.name,
        }),
        component: () =>
          import(
            "@/frontend/components/Models/AddToHangar/Notifications/Success/index.vue"
          ),
        componentProps: {
          vehicle: vehicle,
        },
        icon: props.model.media.storeImage?.small,
      });

      comlink.emit("close-modal");
    })
    .catch((error) => {
      console.error(error);
    });
};
</script>

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
