<script lang="ts">
export default {
  name: "UserActionItems",
};
</script>

<script lang="ts" setup>
import {
  type User,
  type ValidationError,
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
import { type AxiosError } from "axios";

type Props = {
  user: User;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm, displayAlert } = useAppNotifications();
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

const runDestroy = async (destroyFleets: boolean) => {
  try {
    await destroyMutation.mutateAsync({
      id: props.user.id!,
      params: destroyFleets ? { destroy_fleets: true } : undefined,
    });
  } catch (error) {
    const response = (error as AxiosError<ValidationError>).response;
    const data = response?.data;
    const baseError = data?.errors
      ?.find((field) => field.attribute === "base")
      ?.messages?.find(
        (message) => message.code === "has_permanent_fleet_memberships",
      );

    if (baseError && !destroyFleets) {
      const fleets =
        baseError.message.match(
          /admin of the following fleets?: ([^.]+)\./i,
        )?.[1] ?? baseError.message;

      setTimeout(() => {
        displayConfirm({
          text: t("messages.confirm.user.destroyWithFleets", { fleets }),
          onConfirm: () => {
            void runDestroy(true);
          },
        });
      }, 0);
      return;
    }

    const fallback =
      data?.errors
        ?.flatMap((field) => field.messages.map((m) => m.message))
        ?.join(" ") ||
      data?.message ||
      t("messages.user.destroy.failure");

    displayAlert({ text: fallback });
  }
};

const destroy = () => {
  if (!props.user.id) return;

  displayConfirm({
    text: t("messages.confirm.user.destroy"),
    onConfirm: () => {
      void runDestroy(false);
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
    <i class="fa-duotone fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.users.loginAs')"
    :size="BtnSizesEnum.SMALL"
    @click="loginAs"
  >
    <i class="fa-duotone fa-right-to-bracket" />
    <span v-if="withLabels">{{ t("actions.users.loginAs") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.users.resendConfirmation')"
    :size="BtnSizesEnum.SMALL"
    @click="resendConfirmation"
  >
    <i class="fa-duotone fa-envelope" />
    <span v-if="withLabels">{{ t("actions.users.resendConfirmation") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.users.sendPasswordReset')"
    :size="BtnSizesEnum.SMALL"
    @click="sendPasswordReset"
  >
    <i class="fa-duotone fa-key" />
    <span v-if="withLabels">{{ t("actions.users.sendPasswordReset") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    :size="BtnSizesEnum.SMALL"
    :variant="BtnVariantsEnum.DANGER"
    @click="destroy"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
