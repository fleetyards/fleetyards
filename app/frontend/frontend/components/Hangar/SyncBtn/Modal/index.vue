<script lang="ts">
export default {
  name: "VehiclesResetIngameModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { RSIHangarParser } from "@/frontend/lib/RSIHangarParser";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useRouter, useRoute } from "vue-router";
import { extensionUrls } from "@/types/extension";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import SyncResultPanel from "@/frontend/components/Hangar/SyncBtn/Result/index.vue";
import type { SyncProcessStep } from "@/frontend/components/Hangar/SyncBtn/Result/types";
import { useSupportPrompt } from "@/shared/composables/useSupportPrompt";
import type { RsiHangarItemInput, HangarSyncResult } from "@/services/fyApi";
import {
  useSyncRsiHangar as useSyncRsiHangarMutation,
  useSyncRsiHangarStatus,
} from "@/services/fyApi";
import {
  useSubscription,
  ChannelsEnum,
} from "@/shared/composables/useSubscription";
import { differenceInMinutes } from "date-fns";
import {
  type FleetyardsSyncMessage,
  type FleetyardsSyncEvent,
  type FleetyardsSyncSessionPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";

const { t } = useI18n();

const { displayInfo, displaySuccess, displayWarning, displayAlert } =
  useAppNotifications();

const started = ref(false);

const identityStatus = ref<"pending" | "connected" | "notFound">("pending");

const loadingIdentity = ref(false);

const currentPage = ref(1);

const syncStartedAt = ref<Date>(new Date());

const fetchCount = ref(0);

const maxMessagesPerMinute = 60;

const hangarStore = useHangarStore();

const pledges = ref<RsiHangarItemInput[]>([]);

const seenPledgeIds = new Set<string>();

const result = ref<HangarSyncResult | undefined>();

const processSteps = ref<SyncProcessStep[]>([
  {
    name: "fetchHangar",
    status: "pending",
  },
  {
    name: "submitData",
    status: "pending",
  },
]);

const onExtensionMessage = (event: FleetyardsSyncEvent) => {
  handleExtensionMessage(event).catch((error) => {
    console.error("Hangar sync error:", error);
    updateStep("fetchHangar", "failure");
    displayAlert({ text: t("messages.syncExtension.failure") });
  });
};

onMounted(() => {
  started.value = false;
  currentPage.value = 1;
  hangarStore.syncModalOpen = true;

  window.addEventListener("message", onExtensionMessage as EventListener);

  if (hangarStore.extensionReady) {
    checkRSIIdentity();
  }
});

onBeforeUnmount(() => {
  hangarStore.syncModalOpen = false;
  window.removeEventListener("message", onExtensionMessage as EventListener);

  if (pollingDelayTimer) {
    clearTimeout(pollingDelayTimer);
  }
});

const handleExtensionMessage = async (event: FleetyardsSyncEvent) => {
  if (event.data.direction === "fy-sync") {
    const message = JSON.parse(event.data.message) as FleetyardsSyncMessage;

    if (message.action === "sync") {
      if (message.code === 200) {
        await fetchRSIHangar(message.payload as string);
      } else {
        displayAlert({ text: t("messages.syncExtension.failure") });
        updateStep("fetchHangar", "failure");
      }
    }

    if (message.action === "identify") {
      loadingIdentity.value = false;
      if (
        message.code !== 200 ||
        !(message.payload as FleetyardsSyncSessionPayload)?.handle
      ) {
        console.info("FY Extension: No RSI Session found");
        displayWarning({ text: t("messages.syncExtension.notLoggedIn") });
        identityStatus.value = "notFound";
      } else {
        identityStatus.value = "connected";
      }
    }
  }
};

watch(
  () => hangarStore.extensionReady,
  () => {
    if (hangarStore.extensionReady) {
      checkRSIIdentity();
    }
  },
);

const checkRSIIdentity = () => {
  identityStatus.value = "pending";
  loadingIdentity.value = true;

  window.postMessage({
    direction: "fy",
    message: '{ "action": "identify" }',
  });
};

const updateStep = (step: string, status: SyncProcessStep["status"]) => {
  const index = processSteps.value.findIndex((s) => s.name === step);

  if (index !== -1) {
    processSteps.value[index].status = status;
  }
};

const finished = computed(() =>
  processSteps.value.every((step) => step.status === "success"),
);

const finishedWithErrors = computed(() =>
  processSteps.value.some((step) => step.status === "failure"),
);

const retryable = computed(() => {
  const submitDataStatus = processSteps.value.find(
    (step) => step.name === "submitData",
  )?.status;

  return submitDataStatus === "backendFailure" && pledges.value.length > 0;
});

const supportPrompt = useSupportPrompt();
const supportHintDismissed = ref(false);
const showSupportHint = computed(
  () =>
    finished.value &&
    !finishedWithErrors.value &&
    !supportHintDismissed.value &&
    supportPrompt.canShow(),
);

const comlink = useComlink();

const cancel = async () => {
  comlink.emit("close-modal", true);
};

const start = async () => {
  started.value = true;
  pledges.value = [];
  currentPage.value = 1;
  seenPledgeIds.clear();
  syncStartedAt.value = new Date();
  fetchCount.value = 0;
  fetchPage(currentPage.value);

  displayInfo({ text: t("messages.syncExtension.started") });
};

const fetchPage = (page: number) => {
  const elapsedMinutes = differenceInMinutes(new Date(), syncStartedAt.value);

  const allowedMessages = (elapsedMinutes + 1) * maxMessagesPerMinute;

  if (fetchCount.value >= allowedMessages) {
    setTimeout(() => {
      fetchPage(page);
    }, 500);

    return;
  }

  fetchCount.value += 1;

  window.postMessage({
    direction: "fy",
    message: `{ "action": "sync", "page": ${page} }`,
  });
};

const fetchRSIHangar = async (htmlPage: string) => {
  updateStep("fetchHangar", "processing");

  const parser = new RSIHangarParser();
  const result = parser.extractPage(htmlPage);

  if (result === undefined) {
    updateStep("fetchHangar", "success");
    await finishSync();
    return;
  }

  const newPledgeIds = result.pledgeIds.filter((id) => !seenPledgeIds.has(id));

  if (newPledgeIds.length === 0) {
    updateStep("fetchHangar", "success");
    await finishSync();
    return;
  }

  newPledgeIds.forEach((id) => seenPledgeIds.add(id));

  const newPledges = result.pledges.filter((pledge) =>
    newPledgeIds.includes(pledge.id),
  );

  if (newPledges.length > 0) {
    pledges.value = [...pledges.value, ...newPledges];
  }

  currentPage.value += 1;
  setTimeout(() => fetchPage(currentPage.value), 500);
};

const mutation = useSyncRsiHangarMutation();

const pollingActive = ref(false);

let pollingDelayTimer: ReturnType<typeof setTimeout> | null = null;

const pollingEnabled = computed(() => {
  const submitStep = processSteps.value.find(
    (step) => step.name === "submitData",
  );

  return pollingActive.value && submitStep?.status === "processing";
});

const { data: syncStatusData } = useSyncRsiHangarStatus({
  query: {
    enabled: pollingEnabled,
    refetchInterval: 5000,
  },
});

watch(syncStatusData, (statusData) => {
  if (!statusData || !pollingEnabled.value) {
    return;
  }

  if (statusData.status === "finished" && statusData.result) {
    result.value = statusData.result as HangarSyncResult;
    hangarStore.syncRunning = false;

    displaySuccess({ text: t("messages.syncExtension.success") });
    updateStep("submitData", "success");
    comlink.emit("hangar-sync-finished");
  } else if (statusData.status === "failed") {
    hangarStore.syncRunning = false;
    updateStep("submitData", "backendFailure");
  }
});

const onSyncResult = (data: string) => {
  const message = JSON.parse(data) as {
    status: string;
    result?: HangarSyncResult;
    error?: string;
  };

  if (message.status === "finished" && message.result) {
    result.value = message.result;
    hangarStore.syncRunning = false;

    displaySuccess({ text: t("messages.syncExtension.success") });
    updateStep("submitData", "success");
    comlink.emit("hangar-sync-finished");
  } else if (message.status === "failed") {
    hangarStore.syncRunning = false;
    updateStep("submitData", "backendFailure");
    console.error("Hangar sync failed:", message.error);
  }
};

const onSyncDisconnected = () => {
  // Don't immediately mark as failure — polling will pick up the result
};

useSubscription({
  channelName: ChannelsEnum.HANGAR_SYNC,
  received: onSyncResult,
  disconnected: onSyncDisconnected,
});

const finishSync = async () => {
  updateStep("submitData", "processing");
  hangarStore.syncRunning = true;

  pollingActive.value = false;
  if (pollingDelayTimer) {
    clearTimeout(pollingDelayTimer);
  }
  pollingDelayTimer = setTimeout(() => {
    pollingActive.value = true;
  }, 10000);

  await mutation
    .mutateAsync({
      data: {
        items: pledges.value,
      },
    })
    .catch((error) => {
      hangarStore.syncRunning = false;
      updateStep("submitData", "backendFailure");
      console.error(error);
    });
};

const router = useRouter();
const route = useRoute();

const refreshPage = async () => {
  await router.replace({
    name: "hangar",
    query: { ...route.query, openSync: "1" },
  });
  window.location.reload();
};
</script>

<template>
  <Modal :title="t('headlines.syncExtension')" :fixed="true">
    <transition name="fade" mode="out-in">
      <div v-if="!hangarStore.extensionReady">
        <p>{{ t("texts.syncExtension.gettingStarted") }}</p>
        <div class="sync-extension-platforms">
          <a
            v-for="link in extensionUrls"
            :key="`extension-link-${link.platform}`"
            v-tooltip="t(`labels.syncExtension.platforms.${link.platform}`)"
            :aria-label="t(`labels.syncExtension.platforms.${link.platform}`)"
            :href="link.url"
            target="_blank"
          >
            <i :class="`fa-brands fa-${link.platform}`" />
          </a>
        </div>
      </div>
      <div v-else-if="!started">
        <p
          class="flex justify-center text-uppercase relative mt-4"
          :class="{
            'text-warning': identityStatus === 'pending',
            'text-success': identityStatus === 'connected',
            'text-danger': identityStatus === 'notFound',
          }"
        >
          {{ t("labels.syncExtension.sessionStatus") }}:
          {{ t(`labels.syncExtension.identityStatus.${identityStatus}`) }}
          <SmallLoader :loading="loadingIdentity" alignment="right" />
          <Btn
            v-if="identityStatus === 'notFound'"
            v-tooltip="t('labels.syncExtension.checkIdentity')"
            :size="BtnSizesEnum.SMALL"
            :variant="BtnVariantsEnum.LINK"
            class="check-identity-btn"
            :text-inline="true"
            :disabled="loadingIdentity"
            @click="checkRSIIdentity"
          >
            <i class="fa-light fa-sync" />
          </Btn>
        </p>
        <p v-html="t('texts.syncExtension.info')" />
        <p v-if="hangarStore.syncRunning" class="text-warning">
          {{ t("texts.syncExtension.alreadyRunning") }}
        </p>
      </div>
      <SyncResultPanel
        v-else
        :process-steps="processSteps"
        :current-page="currentPage"
        :pledges="pledges"
        :result="result"
        :finished="finished"
        :finished-with-errors="finishedWithErrors"
        :show-support-hint="showSupportHint"
        @support-hint-dismiss="supportHintDismissed = true"
      />
    </transition>
    <div class="page-actions page-actions-block">
      <Btn
        v-if="finished"
        :size="BtnSizesEnum.SMALL"
        :inline="true"
        data-test="close-sync"
        @click="cancel"
      >
        {{ t("actions.syncExtension.close") }}
      </Btn>
      <template v-else>
        <Btn
          :size="BtnSizesEnum.SMALL"
          :inline="true"
          data-test="cancel-sync"
          :disabled="started && !finishedWithErrors"
          @click="cancel"
        >
          {{ t("actions.syncExtension.cancel") }}
        </Btn>
        <Btn
          v-if="retryable"
          :inline="true"
          data-test="start-sync"
          @click.native="finishSync"
        >
          {{ t("actions.syncExtension.retry") }}
        </Btn>
        <Btn
          v-else-if="hangarStore.extensionReady"
          :inline="true"
          data-test="start-sync"
          :loading="started || loadingIdentity"
          :disabled="identityStatus !== 'connected' || hangarStore.syncRunning"
          @click="start"
        >
          {{ t("actions.syncExtension.start") }}
        </Btn>
        <Btn
          v-else
          :inline="true"
          data-test="recheck-sync"
          @click="refreshPage"
        >
          {{ t("actions.syncExtension.refresh") }}
        </Btn>
      </template>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
