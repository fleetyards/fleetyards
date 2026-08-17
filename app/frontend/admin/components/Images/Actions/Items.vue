<script lang="ts">
export default {
  name: "ImageActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Image,
  useUpdateImage,
  useDestroyImage,
  getImagesQueryKey,
} from "@/services/fyAdminApi";
import {
  BtnVariantsEnum,
  BtnTonesEnum,
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

const invalidateImages = () =>
  queryClient.invalidateQueries({
    queryKey: getImagesQueryKey(),
  });

const updateMutation = useUpdateImage({
  mutation: {
    onSettled: invalidateImages,
  },
});

const toggleField = async (field: "enabled" | "global" | "background") => {
  if (!props.image.id) return;

  await updateMutation.mutateAsync({
    id: props.image.id,
    data: { [field]: !props.image[field] },
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
    v-tooltip="!withLabels && t('labels.image.active')"
    @click="toggleField('enabled')"
    :variant="BtnVariantsEnum.GHOST"
  >
    <i
      class="fa-duotone fa-circle-check"
      :class="image.enabled ? 'text-success' : 'text-muted'"
    />
    <span v-if="withLabels">{{ t("labels.image.active") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('labels.image.global')"
    @click="toggleField('global')"
    :variant="BtnVariantsEnum.GHOST"
  >
    <i
      class="fa-duotone fa-globe"
      :class="!image.global ? 'text-warning' : 'text-muted'"
    />
    <span v-if="withLabels">{{ t("labels.image.global") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('labels.image.background')"
    @click="toggleField('background')"
    :variant="BtnVariantsEnum.GHOST"
  >
    <i
      class="fa-duotone fa-image"
      :class="image.background ? 'text-info' : 'text-muted'"
    />
    <span v-if="withLabels">{{ t("labels.image.background") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    @click="destroy"
    :tone="BtnTonesEnum.DANGER"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
