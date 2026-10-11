<script lang="ts">
export default {
  name: "FleetMemberHealthMemberMenu",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import {
  useDemoteFleetMember,
  useDestroyFleetMember,
  type FleetMemberHealthMember,
  type FleetMembershipCapabilities,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  member: FleetMemberHealthMember;
  capabilities?: FleetMembershipCapabilities;
  // Offered where a lower rank resolves the row: a leader who stopped showing up.
  demote?: boolean;
  // An invitation is withdrawn rather than a member removed; same request.
  revoke?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  capabilities: undefined,
  demote: false,
  revoke: false,
});

const { t } = useI18n();

const comlink = useComlink();

const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const { currentUser } = storeToRefs(useSessionStore());

const isSelf = computed(
  () => props.member.username === currentUser?.value?.username,
);

const canDemote = computed(
  () => props.demote && !isSelf.value && !!props.capabilities?.updateMembers,
);

const canRemove = computed(
  () => !isSelf.value && !!props.capabilities?.destroyMembers,
);

const memberLink = computed(() => ({
  name: "fleet-members-index",
  params: { slug: props.fleetSlug },
  // An invitation is only listed in the invites view.
  query: props.revoke
    ? { view: "invites", searchCont: props.member.username }
    : { searchCont: props.member.username },
}));

const busy = ref(false);

const demoteMutation = useDemoteFleetMember();

const destroyMutation = useDestroyFleetMember();

const variables = computed(() => ({
  fleetSlug: props.fleetSlug,
  username: props.member.username,
}));

const demote = async () => {
  busy.value = true;

  try {
    await demoteMutation.mutateAsync(variables.value);
    comlink.emit("fleet-member-update");
    displaySuccess({ text: t("messages.fleet.members.demote.success") });
  } catch {
    displayAlert({ text: t("messages.fleet.members.demote.failure") });
  } finally {
    busy.value = false;
  }
};

const remove = () => {
  displayConfirm({
    text: t("messages.confirm.fleet.members.destroy"),
    onConfirm: async () => {
      busy.value = true;

      try {
        await destroyMutation.mutateAsync(variables.value);
        comlink.emit("fleet-member-update");
        displaySuccess({ text: t("messages.fleet.members.destroy.success") });
      } catch {
        displayAlert({ text: t("messages.fleet.members.destroy.failure") });
      } finally {
        busy.value = false;
      }
    },
  });
};
</script>

<template>
  <BtnDropdown
    :size="BtnSizesEnum.SM"
    :variant="BtnVariantsEnum.BARE"
    :aria-label="
      t('actions.fleet.members.health.actionsFor', { name: member.username })
    "
    expand-left
    expand-bottom
    data-test="health-member-menu"
  >
    <Btn :size="BtnSizesEnum.SM" :to="memberLink">
      <i class="fa-light fa-user" />
      <span>{{ t("actions.fleet.members.health.openMember") }}</span>
    </Btn>
    <Btn
      v-if="canDemote"
      :size="BtnSizesEnum.SM"
      :disabled="busy"
      data-test="health-member-demote"
      @click="demote"
    >
      <i class="fa-light fa-chevron-down" />
      <span>{{ t("actions.fleet.members.demote") }}</span>
    </Btn>
    <Btn
      v-if="canRemove"
      :size="BtnSizesEnum.SM"
      :disabled="busy"
      data-test="health-member-remove"
      @click="remove"
    >
      <i class="fa-light fa-user-minus" />
      <span>
        {{
          revoke
            ? t("actions.fleet.members.health.revoke")
            : t("actions.fleet.members.health.remove")
        }}
      </span>
    </Btn>
  </BtnDropdown>
</template>
