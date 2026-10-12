<script lang="ts">
export default {
  name: "FleetMemberHealthActions",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import MemberContactMenu from "@/frontend/components/base/MemberContactMenu/index.vue";
import {
  useAcceptFleetMember,
  useCreateFleetSquadronMember,
  useDeclineFleetMember,
  useDemoteFleetMember,
  useDestroyFleetMember,
  usePromoteFleetMember,
  useRemindFleetMemberVerification,
  type FleetMemberHealthMember,
  type FleetMembershipCapabilities,
  type FleetSquadron,
} from "@/services/fyApi";

// What resolves the row, and only that: a member in no squadron is added to
// one, a stale invitation withdrawn, a candidate promoted into the gap. Where
// only the member can fix it, the row offers to ask them: a reminder, or a
// way to reach them.
export type MemberHealthAction =
  | "answer"
  | "revoke"
  | "demote"
  | "remove"
  | "promote"
  | "addToSquadron"
  | "remind"
  | "contact";

// Matches the API's cooldown, so the button is off when a send would be refused.
const REMINDER_COOLDOWN_MS = 7 * 24 * 60 * 60 * 1000;

type Props = {
  fleetSlug: string;
  member: FleetMemberHealthMember;
  actions: MemberHealthAction[];
  capabilities?: FleetMembershipCapabilities;
  squadrons?: FleetSquadron[];
  // Names the role a promotion lands in, so the button says what it does.
  promoteTo?: string;
};

const props = withDefaults(defineProps<Props>(), {
  capabilities: undefined,
  squadrons: () => [],
  promoteTo: undefined,
});

const { t, timeDistance } = useI18n();

const comlink = useComlink();

const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const { currentUser } = storeToRefs(useSessionStore());

const isSelf = computed(
  () => props.member.username === currentUser?.value?.username,
);

const contact = computed(() => ({
  username: props.member.username,
  rsiHandle: props.member.rsiHandle ?? undefined,
  discordProfileUrl: props.member.discordProfileUrl ?? undefined,
}));

const remindedRecently = computed(() => {
  const at = props.member.verificationRemindedAt;

  return !!at && Date.now() - new Date(at).getTime() < REMINDER_COOLDOWN_MS;
});

const allowed = computed(() => {
  const can = props.capabilities;
  const others = !isSelf.value;

  return {
    answer: !!can?.updateMembers,
    revoke: !!can?.updateMembers,
    demote: others && !!can?.updateMembers,
    remove: others && !!can?.destroyMembers,
    promote: others && !!can?.updateMembers,
    addToSquadron: !!can?.manageSquadronMembers && props.squadrons.length > 0,
    remind: others && !!can?.updateMembers,
    contact:
      others && (!!props.member.rsiHandle || !!contact.value.discordProfileUrl),
  } satisfies Record<MemberHealthAction, boolean>;
});

const shown = (action: MemberHealthAction) =>
  props.actions.includes(action) && allowed.value[action];

const busy = ref(false);

const variables = computed(() => ({
  fleetSlug: props.fleetSlug,
  username: props.member.username,
}));

const run = async (messages: string, request: () => Promise<unknown>) => {
  busy.value = true;

  try {
    await request();
    comlink.emit("fleet-member-update");
    displaySuccess({ text: t(`${messages}.success`) });
  } catch {
    displayAlert({ text: t(`${messages}.failure`) });
  } finally {
    busy.value = false;
  }
};

const acceptMutation = useAcceptFleetMember();
const declineMutation = useDeclineFleetMember();
const promoteMutation = usePromoteFleetMember();
const demoteMutation = useDemoteFleetMember();
const destroyMutation = useDestroyFleetMember();
const addToSquadronMutation = useCreateFleetSquadronMember();
const remindMutation = useRemindFleetMemberVerification();

const accept = () =>
  run("messages.fleet.members.accept", () =>
    acceptMutation.mutateAsync(variables.value),
  );

const decline = () =>
  run("messages.fleet.members.decline", () =>
    declineMutation.mutateAsync(variables.value),
  );

const promote = () =>
  run("messages.fleet.members.promote", () =>
    promoteMutation.mutateAsync(variables.value),
  );

const demote = () =>
  run("messages.fleet.members.demote", () =>
    demoteMutation.mutateAsync(variables.value),
  );

// Withdrawn rather than removed: the decline endpoint takes back an invitation.
const revoke = () =>
  run("messages.fleet.members.decline", () =>
    declineMutation.mutateAsync(variables.value),
  );

const promoteLabel = computed(() =>
  props.promoteTo
    ? t("actions.fleet.members.health.promoteTo", { role: props.promoteTo })
    : t("actions.fleet.members.promote"),
);

// Says when, once sent: the button stays off for the week.
const remindLabel = computed(() =>
  remindedRecently.value && props.member.verificationRemindedAt
    ? t("labels.fleet.members.health.remindedAt", {
        distance: timeDistance(props.member.verificationRemindedAt),
      })
    : t("actions.fleet.members.health.remind"),
);

const remind = () =>
  run("labels.fleet.members.health.reminded", () =>
    remindMutation.mutateAsync(variables.value),
  );

const remove = () => {
  displayConfirm({
    text: t("messages.confirm.fleet.members.destroy"),
    onConfirm: () =>
      run("messages.fleet.members.destroy", () =>
        destroyMutation.mutateAsync(variables.value),
      ),
  });
};

const addToSquadron = (squadron: FleetSquadron) =>
  run("labels.fleet.members.health.addedToSquadron", () =>
    addToSquadronMutation.mutateAsync({
      fleetSlug: props.fleetSlug,
      fleetSquadronSlug: squadron.slug,
      data: { username: props.member.username },
    }),
  );
</script>

<template>
  <!-- Icons with their names as tooltips: a row keeps its actions on its own
       line in a half-width column, where labelled buttons wrapped under it. -->
  <BtnGroup>
    <template v-if="shown('answer')">
      <Btn
        v-tooltip="t('actions.fleet.members.accept')"
        :aria-label="t('actions.fleet.members.accept')"
        :size="BtnSizesEnum.SM"
        :loading="busy"
        :disabled="busy"
        data-test="health-accept"
        @click="accept"
      >
        <i class="fa-light fa-check" />
      </Btn>
      <Btn
        v-tooltip="t('actions.fleet.members.decline')"
        :aria-label="t('actions.fleet.members.decline')"
        :size="BtnSizesEnum.SM"
        :disabled="busy"
        data-test="health-decline"
        @click="decline"
      >
        <i class="fa-light fa-xmark" />
      </Btn>
    </template>
    <Btn
      v-if="shown('promote')"
      v-tooltip="promoteLabel"
      :aria-label="promoteLabel"
      :size="BtnSizesEnum.SM"
      :disabled="busy"
      data-test="health-promote"
      @click="promote"
    >
      <i class="fa-light fa-chevron-up" />
    </Btn>
    <BtnDropdown
      v-if="shown('addToSquadron')"
      :size="BtnSizesEnum.SM"
      expand-left
      expand-bottom
      data-test="health-add-to-squadron"
    >
      <template #trigger="{ toggle, visible }">
        <Btn
          v-tooltip="t('actions.fleet.members.health.addToSquadron')"
          :aria-label="t('actions.fleet.members.health.addToSquadron')"
          :size="BtnSizesEnum.SM"
          :active="visible"
          aria-haspopup="menu"
          :aria-expanded="visible"
          @click="toggle"
        >
          <i class="fa-light fa-users-medical" />
        </Btn>
      </template>
      <Btn
        v-for="squadron in squadrons"
        :key="squadron.id"
        :size="BtnSizesEnum.SM"
        :disabled="busy"
        :data-test="`health-add-to-squadron-${squadron.slug}`"
        @click="addToSquadron(squadron)"
      >
        {{ squadron.name }}
      </Btn>
    </BtnDropdown>
    <Btn
      v-if="shown('remind')"
      v-tooltip="remindLabel"
      :aria-label="remindLabel"
      :size="BtnSizesEnum.SM"
      :disabled="busy || remindedRecently"
      data-test="health-remind"
      @click="remind"
    >
      <i class="fa-light fa-bell" />
    </Btn>
    <BtnDropdown
      v-if="shown('contact')"
      :size="BtnSizesEnum.SM"
      expand-left
      expand-bottom
      data-test="health-contact"
    >
      <template #trigger="{ toggle, visible }">
        <Btn
          v-tooltip="t('labels.fleet.members.contact')"
          :aria-label="t('labels.fleet.members.contact')"
          :size="BtnSizesEnum.SM"
          :active="visible"
          aria-haspopup="menu"
          :aria-expanded="visible"
          @click="toggle"
        >
          <i class="fa-light fa-message" />
        </Btn>
      </template>
      <MemberContactMenu :member="contact" />
    </BtnDropdown>
    <Btn
      v-if="shown('demote')"
      v-tooltip="t('actions.fleet.members.demote')"
      :aria-label="t('actions.fleet.members.demote')"
      :size="BtnSizesEnum.SM"
      :disabled="busy"
      data-test="health-demote"
      @click="demote"
    >
      <i class="fa-light fa-chevron-down" />
    </Btn>
    <Btn
      v-if="shown('revoke')"
      v-tooltip="t('actions.fleet.members.health.revoke')"
      :aria-label="t('actions.fleet.members.health.revoke')"
      :size="BtnSizesEnum.SM"
      :disabled="busy"
      data-test="health-revoke"
      @click="revoke"
    >
      <i class="fa-light fa-user-xmark" />
    </Btn>
    <Btn
      v-if="shown('remove')"
      v-tooltip="t('actions.fleet.members.health.remove')"
      :aria-label="t('actions.fleet.members.health.remove')"
      :size="BtnSizesEnum.SM"
      :tone="BtnTonesEnum.DANGER"
      :disabled="busy"
      data-test="health-remove"
      @click="remove"
    >
      <i class="fa-light fa-user-minus" />
    </Btn>
  </BtnGroup>
</template>
