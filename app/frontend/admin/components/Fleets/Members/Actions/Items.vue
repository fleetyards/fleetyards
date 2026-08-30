<script lang="ts">
export default {
  name: "FleetMemberActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Fleet,
  type AdminFleetMember,
  getFleetMembersQueryKey,
  loginAsFleetMember,
  removeFleetMember,
} from "@/services/fyAdminApi";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  fleet: Fleet;
  member: AdminFleetMember;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();
const router = useRouter();

// The permanent role cannot be left without a holder, so its member keeps the
// remove action off rather than being told no after asking.
const isPermanent = computed(() => {
  if (!props.member.roleId) return false;

  return (props.fleet.fleetRoles || []).some(
    (role) => role.permanent && role.id === props.member.roleId,
  );
});

const invalidateMembers = () =>
  queryClient.invalidateQueries({
    queryKey: getFleetMembersQueryKey(props.fleet.id),
  });

const editRole = () => {
  void router.push({
    name: "admin-fleet-member-edit",
    params: { id: props.fleet.id, memberId: props.member.id },
  });
};

const loginAs = () => {
  displayConfirm({
    text: t("messages.confirm.user.loginAs"),
    onConfirm: async () => {
      await loginAsFleetMember(props.fleet.id, props.member.id);
      window.open(window.FRONTEND_ENDPOINT, "_blank");
    },
  });
};

const remove = () => {
  displayConfirm({
    text: t("messages.confirm.fleet.members.remove"),
    onConfirm: async () => {
      await removeFleetMember(props.fleet.id, props.member.id)
        .then(invalidateMembers)
        .catch((error) => {
          displayAlert({ text: error.response?.data?.message });
        });
    },
  });
};
</script>

<template>
  <Btn v-tooltip="!withLabels && t('actions.users.loginAs')" @click="loginAs">
    <i class="fa-duotone fa-right-to-bracket" />
    <span v-if="withLabels">{{ t("actions.users.loginAs") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.fleet.members.editRole')"
    @click="editRole"
  >
    <i class="fa-duotone fa-user-pen" />
    <span v-if="withLabels">{{ t("actions.fleet.members.editRole") }}</span>
  </Btn>
  <Btn
    v-if="!isPermanent"
    v-tooltip="!withLabels && t('actions.fleet.members.remove')"
    @click="remove"
    :tone="BtnTonesEnum.DANGER"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.fleet.members.remove") }}</span>
  </Btn>
</template>
