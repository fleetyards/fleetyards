<script lang="ts">
export default {
  name: "FleetEventAdminActions",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
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
  useDestroyFleetEvent,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { checkAccess } from "@/shared/utils/Access";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  event: FleetEventExtended;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();

const canManage = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:events:manage",
    "fleet:events:update",
  ]),
);

const canDelete = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:events:manage",
    "fleet:events:delete",
  ]),
);

const viewerEventRole = computed(
  () =>
    (props.event as { viewerEventRole?: string | null }).viewerEventRole ??
    null,
);

const isEventCreator = computed(
  () => viewerEventRole.value === "creator" || canManage.value,
);

const publishMutation = usePublishFleetEvent();
const lockMutation = useLockFleetEventSignups();
const unlockMutation = useUnlockFleetEventSignups();
const startMutation = useStartFleetEvent();
const completeMutation = useCompleteFleetEvent();
const cancelMutation = useCancelFleetEvent();
const unarchiveMutation = useUnarchiveFleetEvent();
const syncDiscordMutation = useSyncFleetEventToDiscord();
const destroyMutation = useDestroyFleetEvent();

const status = computed(() => props.event.status);
const archived = computed(() => props.event.archived);
const discordConfigured = computed(() => !!props.event.discordConfigured);

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
    displaySuccess({ text: t(`messages.fleets.event.${action}.success`) });
    comlink.emit("fleet-event-updated");
  } catch {
    displayAlert({ text: t(`messages.fleets.event.${action}.failure`) });
  }
};

const handleCancel = () => {
  displayConfirm({
    text: t("messages.fleets.event.cancel.confirm"),
    confirmText: t("actions.fleets.events.cancel"),
    onConfirm: () => transition("cancel", cancelMutation as never),
  });
};

const performDestroy = async () => {
  const wasArchived = props.event.archived;
  try {
    await destroyMutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.event.slug,
    });
    displaySuccess({
      text: wasArchived
        ? t("messages.fleets.event.destroy.success")
        : t("messages.fleets.event.archive.success"),
    });
    if (wasArchived) {
      void router.push({
        name: "fleet-events",
        params: { slug: props.fleet.slug },
      });
    } else {
      comlink.emit("fleet-event-updated");
    }
  } catch {
    displayAlert({
      text: wasArchived
        ? t("messages.fleets.event.destroy.failure")
        : t("messages.fleets.event.archive.failure"),
    });
  }
};

const handleDestroy = () => {
  displayConfirm({
    text: archived.value
      ? t("messages.fleets.event.destroy.confirm")
      : t("messages.fleets.event.archive.confirm"),
    confirmText: archived.value
      ? t("actions.fleets.events.destroy")
      : t("actions.fleets.events.archive"),
    onConfirm: performDestroy,
  });
};

const goToEdit = () => {
  void router.push({
    name: "fleet-event-edit",
    params: { slug: props.fleet.slug, event: props.event.slug },
  });
};

const openAdminsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventAdminsModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: props.event,
    },
  });
};
</script>

<template>
  <BtnGroup inline>
    <Btn v-if="canManage" :size="BtnSizesEnum.SMALL" inline @click="goToEdit">
      <i class="fa-light fa-pen" />
      <span>{{ t("actions.fleets.events.edit") }}</span>
    </Btn>
    <BtnDropdown :size="BtnSizesEnum.SMALL" inline>
      <Btn
        v-if="archived"
        :size="BtnSizesEnum.SMALL"
        inline
        :loading="unarchiveMutation.isPending.value"
        @click="transition('unarchive', unarchiveMutation as never)"
      >
        <i class="fa-light fa-box-open" />
        <span>{{ t("actions.fleets.events.unarchive") }}</span>
      </Btn>
      <Btn
        v-if="!archived && status === 'draft'"
        :size="BtnSizesEnum.SMALL"
        inline
        :loading="publishMutation.isPending.value"
        @click="transition('publish', publishMutation as never)"
      >
        <i class="fa-light fa-paper-plane" />
        <span>{{ t("actions.fleets.events.publish") }}</span>
      </Btn>
      <Btn
        v-if="!archived && status === 'open'"
        :size="BtnSizesEnum.SMALL"
        inline
        :loading="lockMutation.isPending.value"
        @click="transition('lockSignups', lockMutation as never)"
      >
        <i class="fa-light fa-lock" />
        <span>{{ t("actions.fleets.events.lockSignups") }}</span>
      </Btn>
      <Btn
        v-if="!archived && status === 'locked'"
        :size="BtnSizesEnum.SMALL"
        inline
        :loading="unlockMutation.isPending.value"
        @click="transition('unlockSignups', unlockMutation as never)"
      >
        <i class="fa-light fa-lock-open" />
        <span>{{ t("actions.fleets.events.unlockSignups") }}</span>
      </Btn>
      <Btn
        v-if="!archived && (status === 'open' || status === 'locked')"
        :size="BtnSizesEnum.SMALL"
        inline
        :loading="startMutation.isPending.value"
        @click="transition('start', startMutation as never)"
      >
        <i class="fa-light fa-play" />
        <span>{{ t("actions.fleets.events.start") }}</span>
      </Btn>
      <Btn
        v-if="!archived && status === 'active'"
        :size="BtnSizesEnum.SMALL"
        inline
        :loading="completeMutation.isPending.value"
        @click="transition('complete', completeMutation as never)"
      >
        <i class="fa-light fa-flag-checkered" />
        <span>{{ t("actions.fleets.events.complete") }}</span>
      </Btn>
      <Btn
        v-if="!archived && discordConfigured"
        :size="BtnSizesEnum.SMALL"
        inline
        :loading="syncDiscordMutation.isPending.value"
        @click="transition('syncToDiscord', syncDiscordMutation as never)"
      >
        <i class="fa-brands fa-discord" />
        <span>{{ t("actions.fleets.events.syncToDiscord") }}</span>
      </Btn>
      <Btn
        v-if="isEventCreator"
        :size="BtnSizesEnum.SMALL"
        inline
        @click="openAdminsModal"
      >
        <i class="fa-light fa-user-shield" />
        <span>{{ t("actions.fleets.events.manageEventTeam") }}</span>
      </Btn>
      <Btn
        v-if="
          !archived && ['draft', 'open', 'locked', 'active'].includes(status)
        "
        :size="BtnSizesEnum.SMALL"
        inline
        variant="danger"
        :loading="cancelMutation.isPending.value"
        @click="handleCancel"
      >
        <i class="fa-light fa-ban" />
        <span>{{ t("actions.fleets.events.cancel") }}</span>
      </Btn>
      <Btn
        v-if="canDelete"
        :size="BtnSizesEnum.SMALL"
        inline
        variant="danger"
        @click="handleDestroy"
      >
        <i class="fa-light fa-trash" />
        <span>{{
          event.archived
            ? t("actions.fleets.events.destroy")
            : t("actions.fleets.events.archive")
        }}</span>
      </Btn>
    </BtnDropdown>
  </BtnGroup>
</template>
