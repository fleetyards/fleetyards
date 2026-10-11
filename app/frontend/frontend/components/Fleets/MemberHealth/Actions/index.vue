<script lang="ts">
export default {
  name: "FleetMemberHealthActions",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import {
  useAcceptFleetMember,
  useCreateFleetSquadronMember,
  useDeclineFleetMember,
  useDemoteFleetMember,
  useDestroyFleetMember,
  usePromoteFleetMember,
  type FleetMemberHealthMember,
  type FleetMembershipCapabilities,
  type FleetSquadron,
} from "@/services/fyApi";

// What resolves the row, and only that: a member in no squadron is added to
// one, a stale invitation withdrawn, a candidate promoted into the gap.
export type MemberHealthAction =
  "answer" | "revoke" | "demote" | "remove" | "promote" | "addToSquadron";

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

const { t } = useI18n();

const comlink = useComlink();

const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const { currentUser } = storeToRefs(useSessionStore());

const isSelf = computed(
  () => props.member.username === currentUser?.value?.username,
);

const allowed = computed(() => {
  const can = props.capabilities;
  const others = !isSelf.value;

  return {
    answer: !!can?.updateMembers,
    revoke: !!can?.destroyMembers,
    demote: others && !!can?.updateMembers,
    remove: others && !!can?.destroyMembers,
    promote: others && !!can?.updateMembers,
    addToSquadron: !!can?.manageSquadronMembers && props.squadrons.length > 0,
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
  <template v-if="shown('answer')">
    <Btn
      :size="BtnSizesEnum.SM"
      :loading="busy"
      :disabled="busy"
      data-test="health-accept"
      @click="accept"
    >
      {{ t("actions.fleet.members.accept") }}
    </Btn>
    <Btn
      :size="BtnSizesEnum.SM"
      :disabled="busy"
      data-test="health-decline"
      @click="decline"
    >
      {{ t("actions.fleet.members.decline") }}
    </Btn>
  </template>
  <Btn
    v-if="shown('promote')"
    :size="BtnSizesEnum.SM"
    :disabled="busy"
    data-test="health-promote"
    @click="promote"
  >
    <i class="fa-light fa-chevron-up" />
    {{
      promoteTo
        ? t("actions.fleet.members.health.promoteTo", { role: promoteTo })
        : t("actions.fleet.members.promote")
    }}
  </Btn>
  <BtnDropdown
    v-if="shown('addToSquadron')"
    :size="BtnSizesEnum.SM"
    expand-left
    expand-bottom
    data-test="health-add-to-squadron"
  >
    <template #label>
      <i class="fa-light fa-users-medical" />
      {{ t("actions.fleet.members.health.addToSquadron") }}
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
    v-if="shown('demote')"
    :size="BtnSizesEnum.SM"
    :disabled="busy"
    data-test="health-demote"
    @click="demote"
  >
    <i class="fa-light fa-chevron-down" />
    {{ t("actions.fleet.members.demote") }}
  </Btn>
  <Btn
    v-if="shown('remove') || shown('revoke')"
    :size="BtnSizesEnum.SM"
    :disabled="busy"
    data-test="health-remove"
    @click="remove"
  >
    {{
      shown("revoke")
        ? t("actions.fleet.members.health.revoke")
        : t("actions.fleet.members.health.remove")
    }}
  </Btn>
</template>
