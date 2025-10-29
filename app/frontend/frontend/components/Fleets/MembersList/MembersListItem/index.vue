<script lang="ts">
export default {
  name: "MembersListItem",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useMobile } from "@/shared/composables/useMobile";
import type { FleetMember } from "@/services/fyApi";
import { storeToRefs } from "pinia";
import {
  useDestroyFleetMember as useDestroyFleetMemberMutation,
  useDemoteFleetMember as useDemoteFleetMemberMutation,
  usePromoteFleetMember as usePromoteFleetMemberMutation,
  useAcceptFleetMember as useAcceptFleetMemberMutation,
  useDeclineFleetMember as useDeclineFleetMemberMutation,
} from "@/services/fyApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

type Props = {
  member: FleetMember;
  role?: "admin" | "officer" | "member";
  actionsVisible?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  actionsVisible: false,
  role: "member",
});

const deleting = ref(false);

const updating = ref(false);

const mobile = useMobile();

const route = useRoute();

const comlink = useComlink();

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

const currentUserAdmin = computed(() => props.role === "admin");

const currentUserOfficer = computed(() => props.role === "officer");

const canEditOfficerActions = (member: FleetMember) => {
  if (member && currentUser?.value) {
    return (
      (currentUserAdmin.value || currentUserOfficer.value) &&
      member.username !== currentUser.value.username
    );
  }

  return false;
};

const canEditAdminActions = (member: FleetMember) => {
  if (member && currentUser?.value) {
    return (
      currentUserAdmin.value && member.username !== currentUser.value.username
    );
  }

  return false;
};

const destroyMutation = useDestroyFleetMemberMutation();

const removeMember = async (member: FleetMember) => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.fleet.members.destroy"),
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({
          fleetSlug: String(route.params.slug),
          username: member.username,
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

const demoteMember = async (member: FleetMember) => {
  updating.value = true;

  await demoteMutation
    .mutateAsync({
      fleetSlug: String(route.params.slug),
      username: member.username,
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

const promoteMember = async (member: FleetMember) => {
  updating.value = true;

  await promoteMutation
    .mutateAsync({
      fleetSlug: String(route.params.slug),
      username: member.username,
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

const acceptRequest = async (member: FleetMember) => {
  updating.value = true;

  await acceptMutation
    .mutateAsync({
      fleetSlug: String(route.params.slug),
      username: member.username,
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

const declineRequest = async (member: FleetMember) => {
  updating.value = true;

  await declineMutation
    .mutateAsync({
      fleetSlug: String(route.params.slug),
      username: member.username,
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
  <div v-if="member" class="fade-list-item col-12 flex-list-item">
    <div class="flex-list-row">
      <div class="username">
        <Avatar :avatar="member.avatar" size="small" />
        <div class="username-inner">
          {{ member.username }}
          <div
            v-if="mobile && member.rsiHandle"
            v-tooltip="t('nav.rsiProfile')"
            class="rsiHandle"
          >
            (<a
              :href="`https://robertsspaceindustries.com/citizens/${member.rsiHandle}`"
              target="_blank"
              rel="noopener"
              >{{ member.rsiHandle }}</a
            >)
          </div>
        </div>
      </div>
      <div v-if="!mobile" class="rsi-handle">
        <a
          v-if="member.rsiHandle"
          v-tooltip="t('nav.rsiProfile')"
          :href="`https://robertsspaceindustries.com/citizens/${member.rsiHandle}`"
          target="_blank"
          rel="noopener"
        >
          {{ member.rsiHandle }}
        </a>
      </div>
      <div class="role">
        <template v-if="member.status === 'invited'">
          {{ t("labels.fleet.members.invited") }}
        </template>
        <template v-else-if="member.status === 'requested'">
          {{ t("labels.fleet.members.requested") }}
        </template>
        <span v-else-if="member.status === 'declined'" class="text-danger">
          {{ t("labels.fleet.members.declined") }}
        </span>
        <template v-else>
          {{ member.fleetRole.name }}
        </template>
      </div>
      <div class="joined">
        <template v-if="member.status === 'invited'">
          {{ member.invitedAtLabel }}
        </template>
        <template v-else-if="member.status === 'declined'">
          {{ member.declinedAtLabel }}
        </template>
        <template v-else-if="member.status === 'requested'">
          {{ member.requestedAtLabel }}
        </template>
        <template v-else>
          {{ member.acceptedAtLabel }}
        </template>
      </div>
      <div class="links">
        <a
          v-tooltip="t('labels.hangar')"
          :href="`/hangar/${member.username}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fad fa-bookmark" />
        </a>
        <a
          v-if="member.homepage"
          v-tooltip="t('labels.homepage')"
          :href="`//${member.homepage}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fal fa-globe globe-rotate" />
        </a>
        <a
          v-if="member.rsiHandle"
          v-tooltip="t('nav.rsiProfile')"
          :href="`https://robertsspaceindustries.com/citizens/${member.rsiHandle}`"
          target="_blank"
          rel="noopener"
        >
          <i class="icon icon-rsi icon-small" />
        </a>
        <a
          v-if="member.youtube"
          v-tooltip="t('labels.youtube')"
          :href="`//${member.youtube}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-youtube" />
        </a>
        <a
          v-if="member.twitch"
          v-tooltip="t('labels.twitch')"
          :href="`//${member.twitch}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-twitch" />
        </a>
        <a
          v-if="member.guilded"
          v-tooltip="t('labels.guilded')"
          :href="`//${member.guilded}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-guilded" />
        </a>
        <a
          v-if="member.discord"
          v-tooltip="t('labels.discord')"
          :href="`//${member.discord}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-discord" />
        </a>
      </div>
      <div v-if="actionsVisible" class="actions actions-3x">
        <Btn
          v-if="member.status === 'requested'"
          v-tooltip="t('actions.fleet.members.accept')"
          :size="BtnSizesEnum.SMALL"
          :disabled="!canEditOfficerActions(member) || updating"
          :inline="true"
          @click="acceptRequest(member)"
        >
          <i class="fal fa-check" />
        </Btn>
        <Btn
          v-if="member.status === 'requested'"
          v-tooltip="t('actions.fleet.members.decline')"
          :size="BtnSizesEnum.SMALL"
          :disabled="!canEditOfficerActions(member) || updating"
          :inline="true"
          @click="declineRequest(member)"
        >
          <i class="fal fa-times" />
        </Btn>
        <Btn
          v-if="member.role !== 'admin' && member.status === 'accepted'"
          v-tooltip="t('actions.fleet.members.promote')"
          :size="BtnSizesEnum.SMALL"
          :disabled="!canEditAdminActions(member) || updating"
          :inline="true"
          @click="promoteMember(member)"
        >
          <i class="fal fa-chevron-up" />
        </Btn>
        <Btn
          v-if="member.fleetRole !== 'member' && member.status === 'accepted'"
          v-tooltip="t('actions.fleet.members.demote')"
          :size="BtnSizesEnum.SMALL"
          :disabled="!canEditAdminActions(member) || updating"
          :inline="true"
          @click="demoteMember(member)"
        >
          <i class="fal fa-chevron-down" />
        </Btn>
        <Btn
          :size="BtnSizesEnum.SMALL"
          :disabled="!canEditAdminActions(member) || deleting"
          :inline="true"
          @click="removeMember(member)"
        >
          <i class="fad fa-trash-alt" />
        </Btn>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
