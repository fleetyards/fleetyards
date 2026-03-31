<script lang="ts">
export default {
  name: "AdminUserActionItems",
};
</script>

<script lang="ts" setup>
import {
  type AdminUser,
  useDestroyAdminUser,
  getAdminUsersQueryKey,
} from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useSessionStore } from "@/admin/stores/session";

type Props = {
  adminUser: AdminUser;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();
const { extend } = useBreadCrumbs();
const sessionStore = useSessionStore();

const isSelf = computed(
  () => sessionStore.currentUser?.id === props.adminUser.id,
);

const invalidateAdminUsers = () =>
  queryClient.invalidateQueries({
    queryKey: getAdminUsersQueryKey(),
  });

const destroyMutation = useDestroyAdminUser({
  mutation: {
    onSettled: invalidateAdminUsers,
  },
});

const destroy = () => {
  if (!props.adminUser.id) return;

  displayConfirm({
    text: t("messages.confirm.adminUser.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.adminUser.id! });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :size="BtnSizesEnum.SMALL"
    :to="
      extend({
        name: 'admin-admin-edit',
        params: { id: props.adminUser.id },
      })
    "
  >
    <i class="fa-duotone fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-if="!isSelf"
    v-tooltip="!withLabels && t('actions.delete')"
    :size="BtnSizesEnum.SMALL"
    :variant="BtnVariantsEnum.DANGER"
    @click="destroy"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
