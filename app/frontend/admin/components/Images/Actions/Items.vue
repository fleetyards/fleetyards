<script lang="ts">
export default {
  name: "ImageActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Image,
  useDestroyImage,
  getImagesQueryKey,
} from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  image: Image;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const invalidateImages = async () => {
  await queryClient.invalidateQueries({
    queryKey: getImagesQueryKey(),
  });
};

const destroyMutation = useDestroyImage({
  mutation: {
    onSettled: invalidateImages,
  },
});

const destroy = () => {
  if (!props.image.id) return;

  displayConfirm({
    text: t("messages.confirm.image.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.image.id! });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    :size="BtnSizesEnum.SMALL"
    :variant="BtnVariantsEnum.DANGER"
    @click="destroy"
  >
    <i class="fad fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
