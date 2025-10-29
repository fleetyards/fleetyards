<script lang="ts">
export default {
  name: "VehiclesTableListActions",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  selected: string[];
  wishlist?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wishlist: false,
});

const { t } = useI18n();

const comlink = useComlink();

const deleting = ref(false);

const updating = ref(false);

const emit = defineEmits(["reset-selected"]);

const resetSelected = () => {
  emit("reset-selected");
};

const openBulkGroupEditModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/BulkGroupModal/index.vue"),
    props: {
      vehicleIds: props.selected,
    },
  });
};

const { useUpdateBulkMutation, useDestroyBulkMutation } = useVehicleMutations();

const updateBulkMutation = useUpdateBulkMutation();

const addToWishlistBulk = async () => {
  updating.value = true;

  await updateBulkMutation
    .mutateAsync({
      data: {
        ids: props.selected,
        wanted: true,
      },
    })
    .then(() => {
      resetSelected();
    })
    .finally(() => {
      updating.value = false;
    });
};

const addToHangarBulk = async () => {
  updating.value = true;

  await updateBulkMutation
    .mutateAsync({
      data: {
        ids: props.selected,
        wanted: false,
      },
    })
    .then(() => {
      resetSelected();
    })
    .finally(() => {
      updating.value = false;
    });
};

const hideFromPublicHangar = async () => {
  updating.value = true;

  await updateBulkMutation
    .mutateAsync({
      data: {
        ids: props.selected,
        public: false,
      },
    })
    .finally(() => {
      updating.value = false;
    });
};

const showOnPublicHangar = async () => {
  updating.value = true;

  await updateBulkMutation
    .mutateAsync({
      data: {
        ids: props.selected,
        public: true,
      },
    })
    .finally(() => {
      updating.value = false;
    });
};

const destroyBulkMutation = useDestroyBulkMutation();

const { displayConfirm } = useAppNotifications();

const destroyBulk = async () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.hangar.destroySelected"),
    onConfirm: async () => {
      await destroyBulkMutation
        .mutateAsync({
          data: {
            ids: props.selected,
          },
        })
        .then(() => {
          resetSelected();
        })
        .catch((error) => {
          console.error(error);
        })
        .finally(() => {
          deleting.value = false;
        });
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};
</script>

<template>
  <BtnGroup inline>
    <span>{{ t("labels.public") }}</span>
    <Btn
      v-tooltip="t('actions.hangar.showOnPublicHangar')"
      :size="BtnSizesEnum.SMALL"
      :disabled="updating"
      @click="showOnPublicHangar"
    >
      <i class="fad fa-eye" />
    </Btn>
    <Btn
      v-tooltip="t('actions.hangar.hideFromPublicHangar')"
      :size="BtnSizesEnum.SMALL"
      :disabled="updating"
      @click="hideFromPublicHangar"
    >
      <i class="fad fa-eye-slash" />
    </Btn>
  </BtnGroup>
  <Btn
    v-if="wishlist"
    :size="BtnSizesEnum.SMALL"
    :disabled="updating"
    inline
    @click="addToHangarBulk"
  >
    {{ t("actions.addToHangar") }}
  </Btn>
  <Btn
    v-else
    :size="BtnSizesEnum.SMALL"
    :disabled="updating"
    inline
    @click="addToWishlistBulk"
  >
    {{ t("actions.addToWishlist") }}
  </Btn>
  <Btn
    v-if="!wishlist"
    :size="BtnSizesEnum.SMALL"
    inline
    @click="openBulkGroupEditModal"
  >
    {{ t("actions.hangar.editGroupsSelected") }}
  </Btn>
  <Btn
    v-tooltip="t('actions.deleteSelected')"
    :size="BtnSizesEnum.SMALL"
    :disabled="deleting"
    inline
    @click="destroyBulk"
  >
    <i class="fal fa-trash" />
  </Btn>
</template>
