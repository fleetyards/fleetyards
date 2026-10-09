import { RSIHangarParser } from "@/frontend/lib/RSIHangarParser";
import { RsiPageStatus } from "@/frontend/lib/RsiPageStatus";
import { createRsiRateLimiter } from "@/frontend/lib/RsiRateLimiter";
import { FleetyardsSyncAction } from "@/frontend/lib/FleetyardsSyncHandler";
import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import {
  RsiPageReportOutcome,
  useRsiPageReport,
} from "@/frontend/composables/useRsiPageReport";
import type {
  SyncProcessStep,
  SyncProcessStepName,
} from "@/frontend/components/Hangar/SyncBtn/Result/types";
import { syncOutcomeMessage } from "@/frontend/components/Hangar/SyncBtn/Result/status";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import type { HangarSyncData } from "@/services/fyCable/channels/HangarSyncChannel";
import {
  RsiPageKindEnum,
  syncRsiHangar,
  type HangarSyncResult,
  type HangarSyncStatus,
  type RsiHangarItemInput,
  type SyncRsiHangarInput,
} from "@/services/fyApi";

export type HangarSyncOptions = Omit<SyncRsiHangarInput, "items"> & {
  extensionVersion?: string;
};

const MAX_MESSAGES_PER_MINUTE = 60;

// Half a second between pages, on top of the rate limit.
const PAGE_DELAY = 500;

const initialSteps = (): SyncProcessStep[] => [
  { name: "fetchHangar", status: "pending" },
  { name: "submitData", status: "pending" },
];

// Reading a large hangar takes minutes, so the run belongs to the page, not to
// the modal that started it: the state is shared, and closing the modal or
// changing the route leaves the run going.
const started = ref(false);

const processSteps = ref<SyncProcessStep[]>(initialSteps());

const currentPage = ref(1);

const pledges = ref<RsiHangarItemInput[]>([]);

const result = ref<HangarSyncResult | undefined>();

// Set once the backend has taken the run, so the status poll cannot read the
// previous run's result as this one's.
const submitted = ref(false);

const stepStatus = (name: SyncProcessStepName) =>
  processSteps.value.find((step) => step.name === name)?.status;

const finished = computed(() =>
  processSteps.value.every((step) => step.status === "success"),
);

const finishedWithErrors = computed(() =>
  processSteps.value.some((step) => step.status === "failure"),
);

const retryable = computed(() => stepStatus("submitData") === "backendFailure");

const running = computed(
  () =>
    started.value &&
    !finished.value &&
    !finishedWithErrors.value &&
    !retryable.value,
);

const fetching = computed(
  () => running.value && stepStatus("submitData") === "pending",
);

const awaitingResult = computed(
  () => stepStatus("submitData") === "processing",
);

const polling = computed(() => awaitingResult.value && submitted.value);

let input: Omit<SyncRsiHangarInput, "items"> = {};

let extensionVersion: string | undefined;

let seenPledgeIds = new Set<string>();

let rateLimiter = createRsiRateLimiter(MAX_MESSAGES_PER_MINUTE);

let abort = new AbortController();

// The cable message for a run the poll already ended arrives late, and must
// not be told as a sync from another tab. Only for a while: across the
// reconnect the poll exists for, that message may never come.
const LATE_ANSWER_WINDOW = 60_000;

let answeredByPollAt: number | undefined;

// Every start, cancel and reset moves this on, so an answer still out for an
// earlier run never touches the next one.
let runId = 0;

const updateStep = (
  name: SyncProcessStepName,
  status: SyncProcessStep["status"],
) => {
  const step = processSteps.value.find((s) => s.name === name);

  if (step) {
    step.status = status;
  }
};

const clear = () => {
  runId += 1;
  abort.abort();
  started.value = false;
  processSteps.value = initialSteps();
  currentPage.value = 1;
  pledges.value = [];
  result.value = undefined;
  submitted.value = false;
  answeredByPollAt = undefined;
  seenPledgeIds = new Set();
};

export const useHangarSync = () => {
  const { t } = useI18n();

  const comlink = useComlink();

  const { displayInfo, displaySuccess, displayAlert } = useAppNotifications();

  const extension = useSyncExtension();

  const reportRsiPage = useRsiPageReport();

  const failFetch = () => {
    displayAlert({ text: t("messages.syncExtension.failure") });
    updateStep("fetchHangar", "failure");
  };

  // Said here rather than only in the modal: the run may be in the background.
  const failBackend = () => {
    updateStep("submitData", "backendFailure");
    displayAlert({ text: t("messages.syncExtension.failure") });
  };

  const submit = async () => {
    const id = runId;

    updateStep("submitData", "processing");
    submitted.value = false;

    try {
      await syncRsiHangar({ ...input, items: pledges.value });
    } catch (error) {
      if (id !== runId) return;

      failBackend();
      console.error(error);
      return;
    }

    if (id === runId) {
      submitted.value = true;
    }
  };

  const readPage = async (id: number, htmlPage: string) => {
    updateStep("fetchHangar", "processing");

    const page = new RSIHangarParser().extractPage(htmlPage);

    // Nothing is submitted: what was read so far is only part of the hangar,
    // and every ship on the pages after it would count as unmatched.
    if (page.status === RsiPageStatus.UNRECOGNISED) {
      updateStep("fetchHangar", "failure");

      const outcome = await reportRsiPage({
        page: RsiPageKindEnum.HANGAR,
        check: page.check,
        pageNumber: currentPage.value,
        extensionVersion,
        details: page.details,
      });

      if (id !== runId) return;

      // Signed out, the identify answer has already said so.
      if (outcome === RsiPageReportOutcome.REPORTED) {
        displayAlert({ text: t("messages.syncExtension.pageNotRecognised") });
      } else if (outcome === RsiPageReportOutcome.NO_ANSWER) {
        displayAlert({ text: t("messages.syncExtension.failure") });
      }
      return;
    }

    if (page.status === RsiPageStatus.END) {
      updateStep("fetchHangar", "success");
      await submit();
      return;
    }

    const newPledgeIds = page.pledgeIds.filter(
      (pledgeId) => !seenPledgeIds.has(pledgeId),
    );

    if (newPledgeIds.length === 0) {
      updateStep("fetchHangar", "success");
      await submit();
      return;
    }

    const newPledges = page.pledges.filter(
      (pledge) => !seenPledgeIds.has(pledge.id),
    );

    newPledgeIds.forEach((pledgeId) => seenPledgeIds.add(pledgeId));

    pledges.value = [...pledges.value, ...newPledges];

    currentPage.value += 1;
    setTimeout(() => void fetchPage(id), PAGE_DELAY);
  };

  const fetchPage = async (id: number) => {
    await rateLimiter.take(abort.signal);
    if (id !== runId) return;

    const message = await extension
      .request(FleetyardsSyncAction.SYNC, { page: currentPage.value })
      .catch(() => undefined);

    // A reply after the fetch has ended belongs to a run that is over: read
    // now, it could submit the pages collected before an unrecognised one.
    const fetchStatus = stepStatus("fetchHangar");
    if (id !== runId || fetchStatus === "failure" || fetchStatus === "success")
      return;

    if (message?.code !== 200) {
      failFetch();
      return;
    }

    await readPage(id, message.payload as string).catch((error) => {
      console.error("Hangar sync error:", error);
      if (id === runId) failFetch();
    });
  };

  const start = ({
    extensionVersion: version,
    ...syncInput
  }: HangarSyncOptions) => {
    if (running.value) return;

    clear();
    abort = new AbortController();
    rateLimiter = createRsiRateLimiter(MAX_MESSAGES_PER_MINUTE);
    input = syncInput;
    extensionVersion = version;
    started.value = true;

    void fetchPage(runId);

    displayInfo({ text: t("messages.syncExtension.started") });
  };

  const retry = () => {
    if (!retryable.value) return;

    void submit();
  };

  const settle = (message: HangarSyncData | HangarSyncStatus) => {
    if (message.status === "finished") {
      complete(message.result as HangarSyncResult | undefined);
    } else if (message.status === "failed") {
      failBackend();
      if ("error" in message) {
        console.error("Hangar sync failed:", message.error);
      }
    } else if (message.status === "cancelled") {
      updateStep("submitData", "failure");
      displayInfo({ text: t("messages.syncExtension.cancelled") });
    } else {
      return false;
    }

    return true;
  };

  // From the cable. A message may also be for a run started in another tab;
  // answers whether it was this run's.
  const receive = (message: HangarSyncData) => {
    if (awaitingResult.value) return settle(message);

    if (
      answeredByPollAt !== undefined &&
      Date.now() - answeredByPollAt < LATE_ANSWER_WINDOW
    ) {
      answeredByPollAt = undefined;
      return true;
    }

    return false;
  };

  // From the status poll, which only runs once the backend has taken this run.
  const receiveStatus = (status: HangarSyncStatus) => {
    if (!polling.value) return;

    if (settle(status)) {
      answeredByPollAt = Date.now();
    }
  };

  const complete = (syncResult?: HangarSyncResult) => {
    result.value = syncResult;

    const { synced, key } = syncOutcomeMessage(syncResult?.outcome);
    (synced ? displaySuccess : displayInfo)({ text: t(key) });

    updateStep("submitData", "success");
    comlink.emit("hangar-sync-finished");
  };

  // Only while RSI is being read: once submitted, the backend run goes on
  // regardless and its result is still shown when it arrives.
  const cancel = () => {
    if (!fetching.value) return;

    clear();
  };

  // Back to the start screen, for a run that is over. A sign-out drops a run
  // in any state: whatever it would still submit or show belongs to an account
  // that is no longer here.
  const reset = (force = false) => {
    if (running.value && !force) return;

    clear();
  };

  return {
    started,
    processSteps,
    currentPage,
    pledges,
    result,
    finished,
    finishedWithErrors,
    retryable,
    running,
    fetching,
    awaitingResult,
    polling,
    start,
    retry,
    receive,
    receiveStatus,
    cancel,
    reset,
  };
};
