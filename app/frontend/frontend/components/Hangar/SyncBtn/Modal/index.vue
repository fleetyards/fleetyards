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
import { RsiPageStatus } from "@/frontend/lib/RsiPageStatus";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useRouter, useRoute } from "vue-router";
import SyncExtensionLinks from "@/frontend/components/SyncExtensionLinks/index.vue";
import SyncSessionStatus from "@/frontend/components/Hangar/SyncSessionStatus/index.vue";
import HangarGroupsSelect from "@/frontend/components/base/HangarGroupsSelect/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import SyncResultPanel from "@/frontend/components/Hangar/SyncBtn/Result/index.vue";
import type { SyncProcessStep } from "@/frontend/components/Hangar/SyncBtn/Result/types";
import { isSyncStepRunning } from "@/frontend/components/Hangar/SyncBtn/Result/status";
import { useSupportPrompt } from "@/shared/composables/useSupportPrompt";
import type { RsiHangarItemInput, HangarSyncResult } from "@/services/fyApi";
import {
  HangarSyncUnmatchedActionEnum,
  RsiPageKindEnum,
} from "@/services/fyApi";
import {
  RsiPageReportOutcome,
  useRsiPageReport,
} from "@/frontend/composables/useRsiPageReport";
import {
  useSyncRsiHangar as useSyncRsiHangarMutation,
  useSyncRsiHangarStatus,
} from "@/services/fyApi";
import { useSubscription } from "@/shared/composables/useSubscription";
import {
  HangarSyncChannel,
  type HangarSyncData,
} from "@/services/fyCable/channels/HangarSyncChannel";
import { differenceInMinutes } from "date-fns";
import {
  FleetyardsSyncAction,
  type FleetyardsSyncMessage,
  type FleetyardsSyncSessionPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";
import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import { useBuybackDetailsSync } from "@/frontend/composables/useBuybackDetailsSync";

const { t } = useI18n();

// Both read RSI pages, and side by side they would each take the whole rate
// limit. A cancelled pass sends nothing more, so it only waits on its last
// answer and need not hold this sync back.
const { running, cancelling } = useBuybackDetailsSync();

const buybackDetailsRunning = computed(
  () => running.value && !cancelling.value,
);

const { displayInfo, displaySuccess, displayWarning, displayAlert } =
  useAppNotifications();

const started = ref(false);

const identityStatus = ref<"pending" | "connected" | "notFound">("pending");

// The RSI account the extension found signed in, shown so a sync into the
// wrong hangar is caught before it starts.
const rsiHandle = ref<string>();

const loadingIdentity = ref(false);

const currentPage = ref(1);

const syncStartedAt = ref<Date>(new Date());

const fetchCount = ref(0);

const maxMessagesPerMinute = 60;

const hangarStore = useHangarStore();

const pledges = ref<RsiHangarItemInput[]>([]);

const hangarGroupId = ref<string | undefined>(undefined);

// Declared order rather than alphabetical: it runs from the least destructive
// answer to the most, and "wishlist" first is what a sync has always done.
const unmatchedActionOptions = computed(() =>
  [
    HangarSyncUnmatchedActionEnum.WISHLIST,
    HangarSyncUnmatchedActionEnum.DELETE,
    HangarSyncUnmatchedActionEnum.KEEP,
    HangarSyncUnmatchedActionEnum.GROUP,
  ].map((value) => ({
    value,
    label: t(`labels.syncExtension.unmatchedVehiclesActions.${value}`),
  })),
);

const filesUnmatchedIntoGroup = computed(
  () =>
    hangarStore.syncUnmatchedVehiclesAction ===
    HangarSyncUnmatchedActionEnum.GROUP,
);

// `group` with no group is not that action: the endpoint falls back to leaving
// the ships alone, which is not what the modal would be showing the user.
const settingsOpen = ref(false);

const missingUnmatchedGroup = computed(
  () =>
    filesUnmatchedIntoGroup.value && !hangarStore.syncUnmatchedHangarGroupId,
);

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

onMounted(() => {
  started.value = false;
  currentPage.value = 1;
  hangarStore.syncModalOpen = true;

  if (hangarStore.extensionReady) {
    void checkRSIIdentity();
  }
});

let unmounted = false;

onBeforeUnmount(() => {
  unmounted = true;
  hangarStore.syncModalOpen = false;

  if (pollingDelayTimer) {
    clearTimeout(pollingDelayTimer);
  }
});

const failFetch = () => {
  displayAlert({ text: t("messages.syncExtension.failure") });
  updateStep("fetchHangar", "failure");
};

const onSyncReply = async (message?: FleetyardsSyncMessage) => {
  if (unmounted) return;

  // A reply after the fetch has ended belongs to a run that is over: read
  // now, it could submit the pages collected before an unrecognised one.
  const fetchStatus = processSteps.value.find(
    (step) => step.name === "fetchHangar",
  )?.status;
  if (fetchStatus === "failure" || fetchStatus === "success") return;

  if (message?.code !== 200) {
    failFetch();
    return;
  }

  await fetchRSIHangar(message.payload as string).catch((error) => {
    console.error("Hangar sync error:", error);
    failFetch();
  });
};

watch(
  () => hangarStore.extensionReady,
  () => {
    if (hangarStore.extensionReady) {
      void checkRSIIdentity();
    }
  },
);

const extension = useSyncExtension();

// Only the latest check answers: retry can be pressed while one is out.
let identityCheck = 0;

const checkRSIIdentity = async () => {
  const current = ++identityCheck;
  identityStatus.value = "pending";
  loadingIdentity.value = true;

  const identity = await extension
    .request(FleetyardsSyncAction.IDENTIFY)
    .catch(() => undefined);
  // A check still out when the modal closed answers nobody.
  if (unmounted || current !== identityCheck) return;
  const handle = (identity?.payload as FleetyardsSyncSessionPayload)?.handle;

  loadingIdentity.value = false;

  if (identity?.code !== 200 || !handle) {
    console.info("FY Extension: No RSI Session found");
    displayWarning({ text: t("messages.syncExtension.notLoggedIn") });
    identityStatus.value = "notFound";
    rsiHandle.value = undefined;
  } else {
    identityStatus.value = "connected";
    rsiHandle.value = handle;
  }
};

const updateStep = (step: string, status: SyncProcessStep["status"]) => {
  const index = processSteps.value.findIndex((s) => s.name === step);

  if (index !== -1) {
    processSteps.value[index].status = status;
  }
};

// Checking the RSI identity or running a step: the modal's bottom cap says so.
const working = computed(
  () => loadingIdentity.value || isSyncStepRunning(processSteps.value),
);

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
    pledges.value.length > 0 &&
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

  void extension
    .request(FleetyardsSyncAction.SYNC, { page })
    .catch(() => undefined)
    .then(onSyncReply);
};

const reportRsiPage = useRsiPageReport();

const fetchRSIHangar = async (htmlPage: string) => {
  updateStep("fetchHangar", "processing");

  const parser = new RSIHangarParser();
  const result = parser.extractPage(htmlPage);

  // Nothing is submitted: what was read so far is only part of the hangar, and
  // every ship on the pages after it would count as unmatched.
  if (result.status === RsiPageStatus.UNRECOGNISED) {
    updateStep("fetchHangar", "failure");

    const outcome = await reportRsiPage({
      page: RsiPageKindEnum.HANGAR,
      check: result.check,
      pageNumber: currentPage.value,
      extensionVersion: hangarStore.extensionVersion,
      details: result.details,
    });

    // Signed out, the identify answer has already said so.
    if (outcome === RsiPageReportOutcome.REPORTED) {
      displayAlert({ text: t("messages.syncExtension.pageNotRecognised") });
    } else if (outcome === RsiPageReportOutcome.NO_ANSWER) {
      displayAlert({ text: t("messages.syncExtension.failure") });
    }
    return;
  }

  if (result.status === RsiPageStatus.END) {
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

const onSyncResult = (message: HangarSyncData) => {
  if (message.status === "finished") {
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
  channel: HangarSyncChannel,
  received: onSyncResult,
  disconnected: onSyncDisconnected,
});

const finishSync = async () => {
  // A hangar of upgrades, game packages or merchandise only: the API refuses
  // an empty list, which would read as the sync failing.
  if (pledges.value.length === 0) {
    updateStep("submitData", "success");
    displayInfo({ text: t("messages.syncExtension.nothingToSync") });
    return;
  }

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
        hangarGroupId: hangarGroupId.value,
        addBundledVehicles: hangarStore.syncAddBundledVehicles,
        syncPaints: hangarStore.syncPaints,
        syncHangarFlair: hangarStore.syncHangarFlair,
        unmatchedVehiclesAction: hangarStore.syncUnmatchedVehiclesAction,
        unmatchedHangarGroupId: filesUnmatchedIntoGroup.value
          ? hangarStore.syncUnmatchedHangarGroupId
          : undefined,
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
  <Modal :title="t('headlines.syncExtension')" :fixed="true" :loading="working">
    <template v-if="hangarStore.extensionReady && !started" #header-actions>
      <Btn
        v-tooltip="t('labels.syncExtension.settings')"
        :variant="BtnVariantsEnum.GHOST"
        :size="BtnSizesEnum.SM"
        :active="settingsOpen"
        :aria-label="t('labels.syncExtension.settings')"
        :aria-pressed="settingsOpen"
        data-test="toggle-sync-settings"
        @click="settingsOpen = !settingsOpen"
      >
        <i class="fa-light fa-gear" />
      </Btn>
    </template>
    <transition name="fade" mode="out-in">
      <div v-if="!hangarStore.extensionReady">
        <p>{{ t("texts.syncExtension.gettingStarted") }}</p>
        <SyncExtensionLinks />
      </div>
      <div v-else-if="!started">
        <div v-if="settingsOpen" data-test="sync-settings">
          <FormToggle
            v-model="hangarStore.syncAddBundledVehicles"
            name="syncAddBundledVehicles"
            :label="t('labels.syncExtension.addBundledVehicles')"
            :info="t('labels.syncExtension.addBundledVehiclesHint')"
            no-placeholder
          />
          <FormToggle
            v-model="hangarStore.syncPaints"
            name="syncPaints"
            :label="t('labels.syncExtension.syncPaints')"
            :info="t('labels.syncExtension.syncPaintsHint')"
            no-placeholder
          />
          <FormToggle
            v-model="hangarStore.syncHangarFlair"
            name="syncHangarFlair"
            :label="t('labels.syncExtension.syncHangarFlair')"
            :info="t('labels.syncExtension.syncHangarFlairHint')"
            no-placeholder
          />
          <BaseSelect
            v-model="hangarStore.syncUnmatchedVehiclesAction"
            name="syncUnmatchedVehiclesAction"
            :options="unmatchedActionOptions"
            :label="t('labels.syncExtension.unmatchedVehiclesAction')"
            :info="t('labels.syncExtension.unmatchedVehiclesActionHint')"
            :searchable="false"
            :paginated="false"
            :no-label="false"
            unsorted
          />
          <HangarGroupsSelect
            v-if="filesUnmatchedIntoGroup"
            v-model="hangarStore.syncUnmatchedHangarGroupId"
            name="syncUnmatchedHangarGroupId"
            :multiple="false"
            :no-label="false"
            :label="t('labels.syncExtension.unmatchedHangarGroup')"
            :info="t('labels.syncExtension.unmatchedHangarGroupHint')"
          />
        </div>
        <div v-else>
          <SyncSessionStatus
            :status="identityStatus"
            :loading="loadingIdentity"
            :handle="rsiHandle"
            @recheck="checkRSIIdentity"
          />
          <p v-html="t('texts.syncExtension.info')" />
          <hr />
          <HangarGroupsSelect
            v-model="hangarGroupId"
            name="hangarGroupId"
            :multiple="false"
            :no-label="false"
            :label="t('labels.syncExtension.targetGroup')"
            :info="t('labels.imports.targetGroupHint')"
          />
          <div
            v-if="missingUnmatchedGroup"
            class="sync-missing-group"
            data-test="sync-missing-unmatched-group"
          >
            <p class="text-warning">
              {{ t("texts.syncExtension.missingUnmatchedGroup") }}
            </p>
            <Btn
              :size="BtnSizesEnum.SM"
              data-test="open-sync-settings"
              @click="settingsOpen = true"
            >
              {{ t("actions.syncExtension.openSettings") }}
            </Btn>
          </div>
          <p v-if="hangarStore.syncRunning" class="text-warning">
            {{ t("texts.syncExtension.alreadyRunning") }}
          </p>
          <p
            v-else-if="buybackDetailsRunning"
            class="text-warning"
            data-test="sync-buyback-details-running"
          >
            {{ t("texts.syncExtension.buybackDetailsRunning") }}
          </p>
        </div>
      </div>
      <div v-else>
        <SyncResultPanel
          :process-steps="processSteps"
          :current-page="currentPage"
          :pledges="pledges"
          :result="result"
          :finished="finished"
          :finished-with-errors="finishedWithErrors"
          :show-support-hint="showSupportHint"
          :sync-paints="hangarStore.syncPaints"
          :sync-hangar-flair="hangarStore.syncHangarFlair"
          @support-hint-dismiss="supportHintDismissed = true"
        />
      </div>
    </transition>
    <template #footer>
      <Btn v-if="finished" data-test="close-sync" @click="cancel">
        {{ t("actions.syncExtension.close") }}
      </Btn>
      <template v-else>
        <Btn
          data-test="cancel-sync"
          :disabled="started && !finishedWithErrors"
          @click="cancel"
        >
          {{ t("actions.syncExtension.cancel") }}
        </Btn>
        <Btn v-if="retryable" data-test="start-sync" @click.native="finishSync">
          {{ t("actions.syncExtension.retry") }}
        </Btn>
        <Btn
          v-else-if="hangarStore.extensionReady"
          data-test="start-sync"
          :loading="started || loadingIdentity"
          :disabled="
            identityStatus !== 'connected' ||
            hangarStore.syncRunning ||
            buybackDetailsRunning ||
            missingUnmatchedGroup
          "
          @click="start"
        >
          {{ t("actions.syncExtension.start") }}
        </Btn>
        <Btn v-else data-test="recheck-sync" @click="refreshPage">
          {{ t("actions.syncExtension.refresh") }}
        </Btn>
      </template>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
