<script lang="ts">
export default {
  name: "FleetSquadronMembershipBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";
import { useSessionStore } from "@/frontend/stores/session";
import {
  useJoinFleetSquadron,
  useLeaveFleetSquadron,
  useCreateFleetSquadronRequest,
  useDestroyFleetSquadronRequest,
  type Fleet,
  type FleetSquadron,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadron: FleetSquadron;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const sessionStore = useSessionStore();

const submitting = ref(false);

/*
 * One button for the reader's own place in the squadron: in it, they may
 * leave; a team they join outright; an ordinary squadron they ask for, and
 * may take the question back while it waits.
 */
const action = computed(() => {
  if (props.squadron.viewerIsMember) return "leave";
  if (props.squadron.team) return "join";
  if (props.squadron.viewerRequestedAt) return "withdrawRequest";

  return "requestJoin";
});

/*
 * A member asks one ordinary squadron at a time and holds at most one, so
 * asking for this one waits until they leave or withdraw the other.
 */
const blockedReason = computed(() => {
  if (action.value !== "requestJoin") return undefined;

  if (props.squadron.viewerExclusiveSquadron) {
    return t("messages.fleet.squadrons.requests.blocked.member", {
      squadron: props.squadron.viewerExclusiveSquadron.name,
    });
  }

  if (props.squadron.viewerRequestedSquadron) {
    return t("messages.fleet.squadrons.requests.blocked.requested", {
      squadron: props.squadron.viewerRequestedSquadron.name,
    });
  }

  return undefined;
});

const icon = computed(
  () =>
    ({
      leave: "fa-duotone fa-person-to-door",
      join: "fa-duotone fa-user-plus",
      requestJoin: "fa-duotone fa-hand",
      withdrawRequest: "fa-duotone fa-xmark",
    })[action.value],
);

const joinMutation = useJoinFleetSquadron();
const leaveMutation = useLeaveFleetSquadron();
const requestMutation = useCreateFleetSquadronRequest();
const withdrawMutation = useDestroyFleetSquadronRequest();

const run = async (
  request: () => Promise<unknown>,
  messages: { success: string; failure: string },
) => {
  submitting.value = true;

  try {
    await request();
    displaySuccess({ text: messages.success });
    comlink.emit("fleet-squadron-members-updated");
  } catch (error) {
    displayAlert({ text: firstErrorMessageFrom(error) ?? messages.failure });
  } finally {
    submitting.value = false;
  }
};

const ids = computed(() => ({
  fleetSlug: props.fleet.slug,
  slug: props.squadron.slug,
}));

const join = () =>
  run(() => joinMutation.mutateAsync(ids.value), {
    success: t("messages.fleet.squadrons.join.success"),
    failure: t("messages.fleet.squadrons.join.failure"),
  });

const requestJoin = () =>
  run(
    () =>
      requestMutation.mutateAsync({
        fleetSlug: ids.value.fleetSlug,
        fleetSquadronSlug: ids.value.slug,
      }),
    {
      success: t("messages.fleet.squadrons.requests.create.success"),
      failure: t("messages.fleet.squadrons.requests.create.failure"),
    },
  );

const withdrawRequest = () =>
  run(
    () =>
      withdrawMutation.mutateAsync({
        fleetSlug: ids.value.fleetSlug,
        fleetSquadronSlug: ids.value.slug,
        username: sessionStore.currentUser?.username as string,
      }),
    {
      success: t("messages.fleet.squadrons.requests.withdraw.success"),
      failure: t("messages.fleet.squadrons.requests.withdraw.failure"),
    },
  );

const leave = () => {
  displayConfirm({
    text: t("messages.fleet.squadrons.leave.confirm", {
      squadron: props.squadron.name,
    }),
    confirmText: t("actions.fleet.squadrons.leave"),
    onConfirm: () =>
      run(() => leaveMutation.mutateAsync(ids.value), {
        success: t("messages.fleet.squadrons.leave.success"),
        failure: t("messages.fleet.squadrons.leave.failure"),
      }),
  });
};

const onClick = () =>
  ({ leave, join, requestJoin, withdrawRequest })[action.value]();
</script>

<template>
  <span v-tooltip="blockedReason" class="squadron-membership-btn">
    <Btn
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      :disabled="submitting || !!blockedReason"
      :data-test="`squadron-${action}`"
      @click="onClick"
    >
      <i :class="icon" />
      {{ t(`actions.fleet.squadrons.${action}`) }}
    </Btn>
  </span>
</template>

<style lang="scss" scoped>
.squadron-membership-btn {
  display: inline-flex;
}
</style>
