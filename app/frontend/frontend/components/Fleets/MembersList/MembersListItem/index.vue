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
          {{ member.roleLabel }}
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
          size="small"
          :disabled="!canEditOfficerActions(member) || updating"
          :inline="true"
          @click="acceptRequest(member)"
        >
          <i class="fal fa-check" />
        </Btn>
        <Btn
          v-if="member.status === 'requested'"
          v-tooltip="t('actions.fleet.members.decline')"
          size="small"
          :disabled="!canEditOfficerActions(member) || updating"
          :inline="true"
          @click="declineRequest(member)"
        >
          <i class="fal fa-times" />
        </Btn>
        <Btn
          v-if="member.role !== 'admin' && member.status === 'accepted'"
          v-tooltip="t('actions.fleet.members.promote')"
          size="small"
          :disabled="!canEditAdminActions(member) || updating"
          :inline="true"
          @click="promoteMember(member)"
        >
          <i class="fal fa-chevron-up" />
        </Btn>
        <Btn
          v-if="member.role !== 'member' && member.status === 'accepted'"
          v-tooltip="t('actions.fleet.members.demote')"
          size="small"
          :disabled="!canEditAdminActions(member) || updating"
          :inline="true"
          @click="demoteMember(member)"
        >
          <i class="fal fa-chevron-down" />
        </Btn>
        <Btn
          size="small"
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

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useNoty } from "@/shared/composables/useNoty";
import { useMobile } from "@/shared/composables/useMobile";
import type { FleetMember } from "@/services/fyApi";
import { storeToRefs } from "pinia";
import { useApiClient } from "@/frontend/composables/useApiClient";

const { t } = useI18n();

const { displayConfirm, displaySuccess, displayAlert } = useNoty();

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

const { fleetMembers: memberService } = useApiClient();

const removeMember = async (member: FleetMember) => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.fleet.members.destroy"),
    onConfirm: async () => {
      try {
        await memberService.removeMember({
          fleetSlug: String(route.params.slug),
          username: member.username,
        });

        comlink.emit("fleet-member-update");

        displaySuccess({
          text: t("messages.fleet.members.destroy.success"),
        });
      } catch (error) {
        console.error(error);

        displayAlert({
          text: t("messages.fleet.members.destroy.failure"),
        });
      }

      deleting.value = false;
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};

const demoteMember = async (member: FleetMember) => {
  updating.value = true;

  try {
    await memberService.demoteMember({
      fleetSlug: String(route.params.slug),
      username: member.username,
    });

    comlink.emit("fleet-member-update");

    displaySuccess({
      text: t("messages.fleet.members.demote.success"),
    });
  } catch (error) {
    console.error(error);

    displayAlert({
      text: t("messages.fleet.members.demote.failure"),
    });
  }

  updating.value = false;
};

const promoteMember = async (member: FleetMember) => {
  updating.value = true;

  try {
    await memberService.promoteMember({
      fleetSlug: String(route.params.slug),
      username: member.username,
    });

    comlink.emit("fleet-member-update");

    displaySuccess({
      text: t("messages.fleet.members.promote.success"),
    });
  } catch (error) {
    console.error(error);

    displayAlert({
      text: t("messages.fleet.members.promote.failure"),
    });
  }

  updating.value = false;
};

const acceptRequest = async (member: FleetMember) => {
  updating.value = true;

  try {
    await memberService.acceptMember({
      fleetSlug: String(route.params.slug),
      username: member.username,
    });

    comlink.emit("fleet-member-update");

    displaySuccess({
      text: t("messages.fleet.members.accept.success"),
    });
  } catch (error) {
    console.error(error);

    displayAlert({
      text: t("messages.fleet.members.accept.failure"),
    });
  }

  updating.value = false;
};

const declineRequest = async (member: FleetMember) => {
  updating.value = true;

  try {
    await memberService.declineMember({
      fleetSlug: String(route.params.slug),
      username: member.username,
    });

    comlink.emit("fleet-member-update");

    displaySuccess({
      text: t("messages.fleet.members.decline.success"),
    });
  } catch (error) {
    console.error(error);

    displayAlert({
      text: t("messages.fleet.members.decline.failure"),
    });
  }

  updating.value = false;
};
</script>

<script lang="ts">
export default {
  name: "MembersListItem",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
