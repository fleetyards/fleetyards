<script lang="ts">
export default {
  name: "AddToHangarModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import type { Model } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { useSupportPrompt } from "@/shared/composables/useSupportPrompt";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displaySuccess } = useAppNotifications();

const hangarStore = useHangarStore();
const wishlistStore = useWishlistStore();

const comlink = useComlink();

const { useCreateMutation } = useVehicleMutations();
const { mutateAsync, isPending } = useCreateMutation();

const supportPrompt = useSupportPrompt();

const addToWishlist = async () => {
  await mutateAsync({
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
          import("@/frontend/components/Models/AddToHangar/Notifications/Success/index.vue"),
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
  await mutateAsync({
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
          import("@/frontend/components/Models/AddToHangar/Notifications/Success/index.vue"),
        componentProps: {
          vehicle: vehicle,
        },
        icon: props.model.media.storeImage?.smallUrl,
      });

      comlink.emit("close-modal");

      supportPrompt.notifyIfMilestone(
        "vehiclesAdded",
        [10, 25, 50, 100],
        "vehicleAdded",
      );
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
    :loading="isPending"
  >
    <div class="add-to-hangar-choices">
      <button
        type="button"
        class="add-to-hangar-choice"
        :disabled="isPending"
        data-test="add-to-hangar-as-normal"
        @click="addToHangar"
      >
        <i class="fa-light fa-warehouse add-to-hangar-choice__icon" />
        <span class="add-to-hangar-choice__text">
          <span class="add-to-hangar-choice__title">
            {{ t("actions.addToHangar") }}
          </span>
          <span class="add-to-hangar-choice__hint">
            {{ t("texts.addToHangar.hangarHint") }}
          </span>
        </span>
      </button>
      <button
        type="button"
        class="add-to-hangar-choice"
        :disabled="isPending"
        data-test="add-to-hangar-as-wanted"
        @click="addToWishlist"
      >
        <i class="fa-light fa-star add-to-hangar-choice__icon" />
        <span class="add-to-hangar-choice__text">
          <span class="add-to-hangar-choice__title">
            {{ t("actions.addToWishlist") }}
          </span>
          <span class="add-to-hangar-choice__hint">
            {{ t("texts.addToHangar.wishlistHint") }}
          </span>
        </span>
      </button>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
.add-to-hangar-choices {
  display: grid;
  gap: 8px;
}

.add-to-hangar-choice {
  display: flex;
  align-items: center;
  gap: 16px;
  width: 100%;
  padding: 14px 16px;
  border: 1px solid var(--color-edge-soft);
  border-radius: var(--radius-surface-slim);
  background: var(--color-control);
  color: var(--color-text);
  text-align: left;
  cursor: pointer;
  transition: background-color 0.15s ease;

  &:hover {
    background: var(--color-control-hover);
  }

  &:active {
    background: var(--color-control-press);
  }

  &:disabled {
    cursor: default;
    opacity: 0.6;
    background: var(--color-control);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
  }
}

.add-to-hangar-choice__icon {
  width: 1.5em;
  font-size: 1.4rem;
  text-align: center;
  color: var(--color-muted);
}

.add-to-hangar-choice__text {
  display: grid;
  gap: 2px;
  min-width: 0;
}

.add-to-hangar-choice__title {
  font-weight: 600;
  color: var(--color-lifted);
}

.add-to-hangar-choice__hint {
  font-size: 0.875rem;
  color: var(--color-text-dim);
}
</style>
