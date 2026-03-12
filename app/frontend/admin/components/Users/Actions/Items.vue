<script lang="ts">
export default {
  name: "UserActionItems",
};
</script>

<script lang="ts" setup>
import {
  type User,
  loginAsUser,
  useResendUserConfirmation,
  useSendUserPasswordReset,
  useDestroyUser,
  getUsersQueryKey,
} from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  user: User;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const invalidateUsers = () =>
  queryClient.invalidateQueries({
    queryKey: getUsersQueryKey(),
  });

const resendConfirmationMutation = useResendUserConfirmation({
  mutation: {
    onSettled: invalidateUsers,
  },
});

const sendPasswordResetMutation = useSendUserPasswordReset({
  mutation: {
    onSettled: invalidateUsers,
  },
});

const destroyMutation = useDestroyUser({
  mutation: {
    onSettled: invalidateUsers,
  },
});

const loginAs = () => {
  if (!props.user.id) return;

  displayConfirm({
    text: t("messages.confirm.user.loginAs"),
    onConfirm: async () => {
      await loginAsUser(props.user.id!);
      window.open(window.FRONTEND_ENDPOINT, "_blank");
    },
  });
};

const resendConfirmation = () => {
  if (!props.user.id) return;

  displayConfirm({
    text: t("messages.confirm.user.resendConfirmation"),
    onConfirm: async () => {
      await resendConfirmationMutation.mutateAsync({ id: props.user.id! });
    },
  });
};

const sendPasswordReset = () => {
  if (!props.user.id) return;

  displayConfirm({
    text: t("messages.confirm.user.sendPasswordReset"),
    onConfirm: async () => {
      await sendPasswordResetMutation.mutateAsync({ id: props.user.id! });
    },
  });
};

const destroy = () => {
  if (!props.user.id) return;

  displayConfirm({
    text: t("messages.confirm.user.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.user.id! });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :size="BtnSizesEnum.SMALL"
    :to="{ name: 'admin-user-edit', params: { id: user.id } }"
  >
    <i class="fad fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.users.loginAs')"
    :size="BtnSizesEnum.SMALL"
    @click="loginAs"
  >
    <i class="fad fa-right-to-bracket" />
    <span v-if="withLabels">{{ t("actions.users.loginAs") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.users.resendConfirmation')"
    :size="BtnSizesEnum.SMALL"
    @click="resendConfirmation"
  >
    <i class="fad fa-envelope" />
    <span v-if="withLabels">{{ t("actions.users.resendConfirmation") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.users.sendPasswordReset')"
    :size="BtnSizesEnum.SMALL"
    @click="sendPasswordReset"
  >
    <i class="fad fa-key" />
    <span v-if="withLabels">{{ t("actions.users.sendPasswordReset") }}</span>
  </Btn>
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
