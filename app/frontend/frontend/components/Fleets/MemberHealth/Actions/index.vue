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
import { useMobileStore } from "@/shared/stores/mobile";
import { useSessionStore } from "@/frontend/stores/session";
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
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";

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

// Entries of this menu like any other's, rather than the contact menu's own
// header and links, which are laid out for a different container.
const spectrumDmUrl = computed(() =>
  props.member.rsiHandle
    ? `https://robertsspaceindustries.com/spectrum/messages/member/${props.member.rsiHandle}`
    : undefined,
);

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

// Read, not watched: the page keeps the flag current, and a resize listener
// per row would be one per member on a long list.
const { mobile } = storeToRefs(useMobileStore());

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
    tone: AppConfirmTonesEnum.DANGER,
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

type ButtonEntry = {
  kind: "button";
  key: string;
  icon: string;
  label: string;
  onClick: () => unknown;
  disabled: boolean;
  loading?: boolean;
  danger?: boolean;
};

type Entry = ButtonEntry | { kind: "squadrons" } | { kind: "contact" };

// One list in the order both layouts show it: the toolbar draws each entry as
// an icon, the phone menu as a labelled row.
const entries = computed<Entry[]>(() => {
  const list: Entry[] = [];
  const button = (
    entry: Omit<ButtonEntry, "kind" | "disabled"> & { disabled?: boolean },
  ) => list.push({ kind: "button", disabled: busy.value, ...entry });

  if (shown("answer")) {
    button({
      key: "accept",
      icon: "fa-check",
      label: t("actions.fleet.members.accept"),
      onClick: accept,
      loading: busy.value,
    });
    button({
      key: "decline",
      icon: "fa-xmark",
      label: t("actions.fleet.members.decline"),
      onClick: decline,
    });
  }
  if (shown("promote")) {
    button({
      key: "promote",
      icon: "fa-chevron-up",
      label: promoteLabel.value,
      onClick: promote,
    });
  }
  if (shown("addToSquadron")) list.push({ kind: "squadrons" });
  if (shown("remind")) {
    button({
      key: "remind",
      icon: "fa-bell",
      label: remindLabel.value,
      onClick: remind,
      disabled: busy.value || remindedRecently.value,
    });
  }
  if (shown("contact")) list.push({ kind: "contact" });
  if (shown("demote")) {
    button({
      key: "demote",
      icon: "fa-chevron-down",
      label: t("actions.fleet.members.demote"),
      onClick: demote,
    });
  }
  if (shown("revoke")) {
    button({
      key: "revoke",
      icon: "fa-user-xmark",
      label: t("actions.fleet.members.health.revoke"),
      onClick: revoke,
    });
  }
  if (shown("remove")) {
    button({
      key: "remove",
      icon: "fa-user-minus",
      label: t("actions.fleet.members.health.remove"),
      onClick: remove,
      danger: true,
    });
  }

  return list;
});

const entryKey = (entry: Entry) =>
  entry.kind === "button" ? entry.key : entry.kind;
</script>

<template>
  <!-- A phone has no hover for the tooltips and no room for the row of icons,
       so every action is one labelled entry in a menu. The squadron and
       contact choices are spread out flat, because a menu cannot open a
       second one. -->
  <BtnDropdown
    v-if="mobile && entries.length"
    :size="BtnSizesEnum.SM"
    expand-left
    data-test="health-actions-menu"
  >
    <template v-for="entry in entries" :key="entryKey(entry)">
      <Btn
        v-if="entry.kind === 'button'"
        :tone="entry.danger ? BtnTonesEnum.DANGER : undefined"
        :loading="entry.loading"
        :disabled="entry.disabled"
        :data-test="`health-${entry.key}`"
        @click="entry.onClick"
      >
        <i :class="['fa-light', entry.icon]" />
        <span>{{ entry.label }}</span>
      </Btn>
      <template v-else-if="entry.kind === 'squadrons'">
        <Btn
          v-for="squadron in squadrons"
          :key="squadron.id"
          :disabled="busy"
          :data-test="`health-add-to-squadron-${squadron.slug}`"
          @click="addToSquadron(squadron)"
        >
          <i class="fa-light fa-users-medical" />
          <span>
            {{
              t("actions.fleet.members.health.addToNamedSquadron", {
                squadron: squadron.name,
              })
            }}
          </span>
        </Btn>
      </template>
      <template v-else>
        <Btn
          v-if="spectrumDmUrl"
          :href="spectrumDmUrl"
          target="_blank"
          data-test="health-contact-spectrum"
        >
          <i class="icon icon-rsi" />
          <span>{{ t("labels.fleet.members.spectrumDm") }}</span>
        </Btn>
        <Btn
          v-if="contact.discordProfileUrl"
          :href="contact.discordProfileUrl"
          target="_blank"
          data-test="health-contact-discord"
        >
          <i class="fa-brands fa-discord" />
          <span>{{ t("labels.fleet.members.discordContact") }}</span>
        </Btn>
      </template>
    </template>
  </BtnDropdown>
  <!-- Icons with their names as tooltips: a row keeps its actions on its own
       line in a half-width column, where labelled buttons wrapped under it. -->
  <BtnGroup v-else-if="!mobile && entries.length">
    <template v-for="entry in entries" :key="entryKey(entry)">
      <Btn
        v-if="entry.kind === 'button'"
        v-tooltip="entry.label"
        :aria-label="entry.label"
        :size="BtnSizesEnum.SM"
        :tone="entry.danger ? BtnTonesEnum.DANGER : undefined"
        :loading="entry.loading"
        :disabled="entry.disabled"
        :data-test="`health-${entry.key}`"
        @click="entry.onClick"
      >
        <i :class="['fa-light', entry.icon]" />
      </Btn>
      <BtnDropdown
        v-else-if="entry.kind === 'squadrons'"
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
      <BtnDropdown
        v-else
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
        <Btn
          v-if="spectrumDmUrl"
          :size="BtnSizesEnum.SM"
          :href="spectrumDmUrl"
          target="_blank"
          data-test="health-contact-spectrum"
        >
          <i class="icon icon-rsi" />
          <span>{{ t("labels.fleet.members.spectrumDm") }}</span>
        </Btn>
        <Btn
          v-if="contact.discordProfileUrl"
          :size="BtnSizesEnum.SM"
          :href="contact.discordProfileUrl"
          target="_blank"
          data-test="health-contact-discord"
        >
          <i class="fa-brands fa-discord" />
          <span>{{ t("labels.fleet.members.discordContact") }}</span>
        </Btn>
      </BtnDropdown>
    </template>
  </BtnGroup>
</template>
