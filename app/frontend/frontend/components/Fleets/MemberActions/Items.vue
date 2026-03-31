<script lang="ts">
export default {
  name: "FleetMemberActionItems",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { checkAccess } from "@/shared/utils/Access";
import { storeToRefs } from "pinia";
import type { FleetMember } from "@/services/fyApi";
import {
  useDestroyFleetMember as useDestroyFleetMemberMutation,
  useDemoteFleetMember as useDemoteFleetMemberMutation,
  usePromoteFleetMember as usePromoteFleetMemberMutation,
  useAcceptFleetMember as useAcceptFleetMemberMutation,
  useDeclineFleetMember as useDeclineFleetMemberMutation,
} from "@/services/fyApi";

type Props = {
  member: FleetMember;
  resourceAccess?: string[];
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();

const comlink = useComlink();

const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const route = useRoute();

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

const deleting = ref(false);

const updating = ref(false);

const canUpdateMembers = computed(() => {
  if (props.member && currentUser?.value) {
    return (
      checkAccess(props.resourceAccess, [
        "fleet:memberships:update",
        "fleet:memberships:manage",
        "fleet:manage",
      ]) && props.member.username !== currentUser.value.username
    );
  }

  return false;
});

const canDeleteMembers = computed(() => {
  if (props.member && currentUser?.value) {
    return (
      checkAccess(props.resourceAccess, [
        "fleet:memberships:delete",
        "fleet:memberships:manage",
        "fleet:manage",
      ]) && props.member.username !== currentUser.value.username
    );
  }

  return false;
});

const destroyMutation = useDestroyFleetMemberMutation();

const removeMember = async () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.fleet.members.destroy"),
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({
          fleetSlug: String(route.params.slug),
          username: props.member.username,
        })
        .then(() => {
          comlink.emit("fleet-member-update");

          displaySuccess({
            text: t("messages.fleet.members.destroy.success"),
          });
        })
        .catch((error) => {
          console.error(error);

          displayAlert({
            text: t("messages.fleet.members.destroy.failure"),
          });
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

const demoteMutation = useDemoteFleetMemberMutation();

const demoteMember = async () => {
  updating.value = true;

  await demoteMutation
    .mutateAsync({
      fleetSlug: String(route.params.slug),
      username: props.member.username,
    })
    .then(() => {
      comlink.emit("fleet-member-update");

      displaySuccess({
        text: t("messages.fleet.members.demote.success"),
      });
    })
    .catch((error) => {
      console.error(error);

      displayAlert({
        text: t("messages.fleet.members.demote.failure"),
      });
    })
    .finally(() => {
      updating.value = false;
    });
};

const promoteMutation = usePromoteFleetMemberMutation();

const promoteMember = async () => {
  updating.value = true;

  await promoteMutation
    .mutateAsync({
      fleetSlug: String(route.params.slug),
      username: props.member.username,
    })
    .then(() => {
      comlink.emit("fleet-member-update");

      displaySuccess({
        text: t("messages.fleet.members.promote.success"),
      });
    })
    .catch((error) => {
      console.error(error);

      displayAlert({
        text: t("messages.fleet.members.promote.failure"),
      });
    })
    .finally(() => {
      updating.value = false;
    });
};

const acceptMutation = useAcceptFleetMemberMutation();

const acceptRequest = async () => {
  updating.value = true;

  await acceptMutation
    .mutateAsync({
      fleetSlug: String(route.params.slug),
      username: props.member.username,
    })
    .then(() => {
      comlink.emit("fleet-member-update");

      displaySuccess({
        text: t("messages.fleet.members.accept.success"),
      });
    })
    .catch((error) => {
      console.error(error);

      displayAlert({
        text: t("messages.fleet.members.accept.failure"),
      });
    })
    .finally(() => {
      updating.value = false;
    });
};

const declineMutation = useDeclineFleetMemberMutation();

const declineRequest = async () => {
  updating.value = true;

  await declineMutation
    .mutateAsync({
      fleetSlug: String(route.params.slug),
      username: props.member.username,
    })
    .then(() => {
      comlink.emit("fleet-member-update");

      displaySuccess({
        text: t("messages.fleet.members.decline.success"),
      });
    })
    .catch((error) => {
      console.error(error);

      displayAlert({
        text: t("messages.fleet.members.decline.failure"),
      });
    })
    .finally(() => {
      updating.value = false;
    });
};
</script>

<template>
  <Btn
    v-if="member.status === 'requested'"
    v-tooltip="canUpdateMembers && t('actions.fleet.members.accept')"
    :size="BtnSizesEnum.SMALL"
    :disabled="!canUpdateMembers || updating"
    @click="acceptRequest"
  >
    <i class="fa-light fa-check" />
    <span v-if="withLabels">{{ t("actions.fleet.members.accept") }}</span>
  </Btn>
  <Btn
    v-if="member.status === 'requested'"
    v-tooltip="canUpdateMembers && t('actions.fleet.members.decline')"
    :size="BtnSizesEnum.SMALL"
    :disabled="!canUpdateMembers || updating"
    @click="declineRequest"
  >
    <i class="fa-light fa-times" />
    <span v-if="withLabels">{{ t("actions.fleet.members.decline") }}</span>
  </Btn>
  <Btn
    v-if="member.fleetRole?.slug !== 'admin' && member.status === 'accepted'"
    v-tooltip="canDeleteMembers && t('actions.fleet.members.promote')"
    :size="BtnSizesEnum.SMALL"
    :disabled="!canDeleteMembers || updating"
    @click="promoteMember"
  >
    <i class="fa-light fa-chevron-up" />
    <span v-if="withLabels">{{ t("actions.fleet.members.promote") }}</span>
  </Btn>
  <Btn
    v-if="member.fleetRole?.slug !== 'member' && member.status === 'accepted'"
    v-tooltip="canDeleteMembers && t('actions.fleet.members.demote')"
    :size="BtnSizesEnum.SMALL"
    :disabled="!canDeleteMembers || updating"
    @click="demoteMember"
  >
    <i class="fa-light fa-chevron-down" />
    <span v-if="withLabels">{{ t("actions.fleet.members.demote") }}</span>
  </Btn>
  <Btn
    v-tooltip="canDeleteMembers && t('actions.fleet.members.remove')"
    :size="BtnSizesEnum.SMALL"
    :variant="BtnVariantsEnum.DANGER"
    :disabled="!canDeleteMembers || deleting"
    @click="removeMember"
  >
    <i class="fa-duotone fa-trash-alt" />
    <span v-if="withLabels">{{ t("actions.fleet.members.remove") }}</span>
  </Btn>
</template>
