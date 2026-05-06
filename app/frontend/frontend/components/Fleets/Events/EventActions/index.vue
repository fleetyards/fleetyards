<script lang="ts">
export default {
  name: "FleetEventsActions",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type Fleet,
  type FleetEventExtended,
  usePublishFleetEvent,
  useLockFleetEventSignups,
  useUnlockFleetEventSignups,
  useStartFleetEvent,
  useCompleteFleetEvent,
  useCancelFleetEvent,
  useUnarchiveFleetEvent,
  useSyncFleetEventToDiscord,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  event: FleetEventExtended;
  canManage: boolean;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();

const publishMutation = usePublishFleetEvent();
const lockMutation = useLockFleetEventSignups();
const unlockMutation = useUnlockFleetEventSignups();
const startMutation = useStartFleetEvent();
const completeMutation = useCompleteFleetEvent();
const cancelMutation = useCancelFleetEvent();
const unarchiveMutation = useUnarchiveFleetEvent();
const syncDiscordMutation = useSyncFleetEventToDiscord();

const transition = async (
  action: string,
  mutation: {
    mutateAsync: (args: {
      fleetSlug: string;
      slug: string;
    }) => Promise<unknown>;
  },
) => {
  try {
    await mutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.event.slug,
    });
    displaySuccess({
      text: t(`messages.fleets.event.${action}.success`),
    });
    comlink.emit("fleet-event-updated");
  } catch {
    displayAlert({
      text: t(`messages.fleets.event.${action}.failure`),
    });
  }
};

const handleCancel = () => {
  displayConfirm({
    text: t("messages.fleets.event.cancel.confirm"),
    confirmText: t("actions.fleets.events.cancel"),
    onConfirm: () => transition("cancel", cancelMutation as never),
  });
};

const status = computed(() => props.event.status);
const archived = computed(() => props.event.archived);
const discordConfigured = computed(() => !!props.event.discordConfigured);

const syncToDiscord = async () => {
  try {
    await syncDiscordMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.event.slug,
    });
    displaySuccess({
      text: t("messages.fleets.event.syncToDiscord.success"),
    });
    comlink.emit("fleet-event-updated");
  } catch {
    displayAlert({
      text: t("messages.fleets.event.syncToDiscord.failure"),
    });
  }
};
</script>

<template>
  <div v-if="canManage" class="event-actions">
    <Btn
      v-if="archived"
      :size="BtnSizesEnum.SMALL"
      inline
      :loading="unarchiveMutation.isPending.value"
      @click="transition('unarchive', unarchiveMutation as never)"
    >
      <i class="fa-light fa-box-open" />
      {{ t("actions.fleets.events.unarchive") }}
    </Btn>
    <Btn
      v-if="!archived && status === 'draft'"
      :size="BtnSizesEnum.SMALL"
      inline
      :loading="publishMutation.isPending.value"
      @click="transition('publish', publishMutation as never)"
    >
      <i class="fa-light fa-paper-plane" />
      {{ t("actions.fleets.events.publish") }}
    </Btn>

    <Btn
      v-if="!archived && status === 'open'"
      :size="BtnSizesEnum.SMALL"
      inline
      :loading="lockMutation.isPending.value"
      @click="transition('lockSignups', lockMutation as never)"
    >
      <i class="fa-light fa-lock" />
      {{ t("actions.fleets.events.lockSignups") }}
    </Btn>
    <Btn
      v-if="!archived && status === 'locked'"
      :size="BtnSizesEnum.SMALL"
      inline
      :loading="unlockMutation.isPending.value"
      @click="transition('unlockSignups', unlockMutation as never)"
    >
      <i class="fa-light fa-lock-open" />
      {{ t("actions.fleets.events.unlockSignups") }}
    </Btn>

    <Btn
      v-if="!archived && (status === 'open' || status === 'locked')"
      :size="BtnSizesEnum.SMALL"
      inline
      :loading="startMutation.isPending.value"
      @click="transition('start', startMutation as never)"
    >
      <i class="fa-light fa-play" />
      {{ t("actions.fleets.events.start") }}
    </Btn>

    <Btn
      v-if="!archived && status === 'active'"
      :size="BtnSizesEnum.SMALL"
      inline
      :loading="completeMutation.isPending.value"
      @click="transition('complete', completeMutation as never)"
    >
      <i class="fa-light fa-flag-checkered" />
      {{ t("actions.fleets.events.complete") }}
    </Btn>

    <Btn
      v-if="!archived && ['draft', 'open', 'locked', 'active'].includes(status)"
      :size="BtnSizesEnum.SMALL"
      inline
      variant="danger"
      :loading="cancelMutation.isPending.value"
      @click="handleCancel"
    >
      <i class="fa-light fa-ban" />
      {{ t("actions.fleets.events.cancel") }}
    </Btn>

    <Btn
      v-if="!archived && discordConfigured"
      :size="BtnSizesEnum.SMALL"
      inline
      variant="link"
      :loading="syncDiscordMutation.isPending.value"
      @click="syncToDiscord"
    >
      <i class="fa-brands fa-discord" />
      {{ t("actions.fleets.events.syncToDiscord") }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
.event-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}
</style>
