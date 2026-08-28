<script lang="ts">
export default {
  name: "UnlistedModelActionItems",
};
</script>

<script lang="ts" setup>
import {
  type ScDataUnlistedModel,
  useScDataUnlistedModelIgnore,
  useScDataUnlistedModelMarkAsPaint,
  useScDataUnlistedModelCreateModel,
  getScDataUnlistedModelsQueryKey,
} from "@/services/fyAdminApi";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  unlistedModel: ScDataUnlistedModel;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const invalidate = () =>
  queryClient.invalidateQueries({
    queryKey: getScDataUnlistedModelsQueryKey(),
  });

const ignoreMutation = useScDataUnlistedModelIgnore({
  mutation: { onSettled: invalidate },
});
const paintMutation = useScDataUnlistedModelMarkAsPaint({
  mutation: { onSettled: invalidate },
});
const createMutation = useScDataUnlistedModelCreateModel({
  mutation: { onSettled: invalidate },
});

// `belongs_to :manufacturer` is required on a model, and an identifier whose
// prefix resolves to nothing is either a new company or not a ship at all.
const canCreate = computed(() => !!props.unlistedModel.manufacturer);

const createModel = () => {
  displayConfirm({
    text: t("messages.confirm.unlistedModel.createModel", {
      name: props.unlistedModel.name ?? props.unlistedModel.identifier,
    }),
    onConfirm: async () => {
      await createMutation.mutateAsync({ id: props.unlistedModel.id });
    },
  });
};

const markAsPaint = async () => {
  await paintMutation.mutateAsync({ id: props.unlistedModel.id });
};

const ignore = async () => {
  await ignoreMutation.mutateAsync({ id: props.unlistedModel.id });
};
</script>

<template>
  <Btn
    v-tooltip="
      !withLabels &&
      (canCreate
        ? t('actions.unlistedModel.createModel')
        : t('actions.unlistedModel.noManufacturer'))
    "
    :disabled="!canCreate"
    @click="createModel"
  >
    <i class="fa-duotone fa-starship" />
    <span v-if="withLabels">{{ t("actions.unlistedModel.createModel") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.unlistedModel.markAsPaint')"
    @click="markAsPaint"
  >
    <i class="fa-duotone fa-palette" />
    <span v-if="withLabels">{{ t("actions.unlistedModel.markAsPaint") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.unlistedModel.ignore')"
    :tone="BtnTonesEnum.DANGER"
    @click="ignore"
  >
    <i class="fa-duotone fa-eye-slash" />
    <span v-if="withLabels">{{ t("actions.unlistedModel.ignore") }}</span>
  </Btn>
</template>
