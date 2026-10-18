import { extractBuybackPage } from "@/frontend/lib/RSIBuybackParser";
import { RsiPageStatus } from "@/frontend/lib/RsiPageStatus";
import { rsiRateLimiter } from "@/frontend/lib/RsiRateLimiter";
import {
  FleetyardsSyncAction,
  type FleetyardsSyncMessage,
} from "@/frontend/lib/FleetyardsSyncHandler";
import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import { useBuybackDetailsSync } from "@/frontend/composables/useBuybackDetailsSync";
import {
  RsiPageReportOutcome,
  useRsiPageReport,
} from "@/frontend/composables/useRsiPageReport";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  RsiPageKindEnum,
  syncRsiBuybacks,
  hangarBuybacks,
  type BuybackSyncResult,
  type RsiBuybackItemInput,
} from "@/services/fyApi";

export type BuybackSyncStatus =
  "idle" | "fetching" | "submitting" | "finished" | "unsupported" | "failed";

export type BuybackSyncOptions = {
  // An extension that can read the list but not yet a pledge's price still
  // syncs the list.
  readDetails: boolean;
  extensionVersion?: string;
};

// Half a second between pages, on top of the rate limit.
const PAGE_DELAY = 500;

// An extension that never answers would otherwise leave the sync spinning.
const REPLY_TIMEOUT = 30000;

// A long buy-back list takes a while to read, so the run belongs to the page,
// not to the modal that started it: the state is shared, and closing the modal
// or changing the route leaves the run going.
const status = ref<BuybackSyncStatus>("idle");

const currentPage = ref(1);

const buybacks = ref<RsiBuybackItemInput[]>([]);

// How many buy-backs are stored, taken when a run starts: the last sync left
// the list that way, so it is what this run reads against.
const lastCount = ref<number>();

// The list's length in pages: RSI's pager where a page shows one, otherwise an
// estimate from the stored count and the first page's size.
const totalPages = ref<number>();

const pagesEstimated = ref(false);

// Whether this run reads prices after the list: decided when it starts, by the
// extension it started with, and not by whichever extension answers later.
const readsDetails = ref(false);

const result = ref<BuybackSyncResult | undefined>();

// The price pass outlives the run; its counts only describe a pass this run
// started.
const detailsStarted = ref(false);

const running = computed(
  () => status.value === "fetching" || status.value === "submitting",
);

let options: BuybackSyncOptions = { readDetails: false };

let seenIds = new Set<string>();

// The first page's size, for the estimate: RSI shows the same number per page.
let firstPageSize = 0;

// Runs when the stored count or the first page arrives, whichever is last. A
// pager, once seen, wins over the estimate.
const estimatePages = () => {
  if (totalPages.value && !pagesEstimated.value) return;
  if (!lastCount.value || !firstPageSize) return;

  totalPages.value = Math.ceil(lastCount.value / firstPageSize);
  pagesEstimated.value = true;
};

let abort = new AbortController();

// Every start, cancel and reset moves this on, so an answer still out for an
// earlier run never touches the next one.
let runId = 0;

const clear = () => {
  runId += 1;
  abort.abort();
  status.value = "idle";
  currentPage.value = 1;
  buybacks.value = [];
  lastCount.value = undefined;
  totalPages.value = undefined;
  pagesEstimated.value = false;
  readsDetails.value = false;
  result.value = undefined;
  detailsStarted.value = false;
  seenIds = new Set();
  firstPageSize = 0;
};

// An extension released before buy-backs answers the action it does not know
// with this.
const isUnknownAction = (message: FleetyardsSyncMessage) =>
  message.code === 500 && message.error === "Unknown Action";

export const useBuybackSync = () => {
  const { t } = useI18n();

  const comlink = useComlink();

  const { displayInfo, displaySuccess, displayWarning, displayAlert } =
    useAppNotifications();

  const extension = useSyncExtension();

  const reportRsiPage = useRsiPageReport();

  const details = useBuybackDetailsSync();

  // A run the user can put right themselves, such as by signing in again,
  // warns rather than alerts.
  const fail = (
    text = t("messages.buybackSync.failure"),
    { warn = false } = {},
  ) => {
    status.value = "failed";
    (warn ? displayWarning : displayAlert)({ text });
  };

  // Only ever after the last page: the endpoint replaces the whole list, so a
  // partial one would drop every buy-back on the pages that were never read.
  const submit = async (id: number) => {
    status.value = "submitting";

    let synced: BuybackSyncResult;

    try {
      synced = await syncRsiBuybacks({ items: buybacks.value });
    } catch (error) {
      console.error(error);
      if (id === runId) fail();
      return;
    }

    // Stored even when the run was dropped meanwhile; the lists still refresh.
    comlink.emit("buyback-sync-finished");

    if (id !== runId) return;

    result.value = synced;

    if (synced.detailsPending.length && options.readDetails) {
      detailsStarted.value = true;
      void details.run(buybacks.value, synced.detailsPending);
    }

    status.value = "finished";
    displaySuccess({ text: t("messages.buybackSync.success") });
  };

  const handlePage = async (id: number, html: string) => {
    const page = extractBuybackPage(html);

    // Not a buy-back page this parser understands: the list read so far is
    // incomplete, and submitting it would delete every buy-back after it.
    // Still reading until the report has answered, so a modal closed
    // meanwhile cannot clear the run before it says how it ended.
    if (page.status === RsiPageStatus.UNRECOGNISED) {
      const outcome = await reportRsiPage({
        page: RsiPageKindEnum.BUYBACK,
        check: page.check,
        pageNumber: currentPage.value,
        extensionVersion: options.extensionVersion,
      });

      if (id !== runId) return;

      if (outcome === RsiPageReportOutcome.REPORTED) {
        fail(t("messages.syncExtension.pageNotRecognised"));
      } else if (outcome === RsiPageReportOutcome.SIGNED_OUT) {
        fail(t("messages.syncExtension.notLoggedIn"), { warn: true });
      } else {
        fail();
      }
      return;
    }

    if (page.status === RsiPageStatus.END) {
      await submit(id);
      return;
    }

    const newBuybacks = page.pledges.filter(
      (pledge) => !seenIds.has(pledge.id),
    );

    if (newBuybacks.length === 0) {
      await submit(id);
      return;
    }

    if (page.lastPage) {
      totalPages.value = Math.max(
        pagesEstimated.value ? 0 : (totalPages.value ?? 0),
        page.lastPage,
      );
      pagesEstimated.value = false;
    } else if (currentPage.value === 1) {
      firstPageSize = page.pledges.length;
      estimatePages();
    }

    newBuybacks.forEach((pledge) => seenIds.add(pledge.id));
    // RSI gives a pledge no address of its own, so the page it was read from
    // is what a link to it can go by.
    buybacks.value = [
      ...buybacks.value,
      ...newBuybacks.map((pledge) => ({ ...pledge, page: currentPage.value })),
    ];

    currentPage.value += 1;
    setTimeout(() => void fetchPage(id), PAGE_DELAY);
  };

  // Every later page arrives through a timer, which can fire after the run
  // failed, was cancelled or was replaced.
  const fetchPage = async (id: number) => {
    if (id !== runId || status.value !== "fetching") return;

    await rsiRateLimiter.take(abort.signal);
    if (id !== runId) return;

    const message = await extension
      .request(
        FleetyardsSyncAction.SYNC_BUYBACK,
        { page: currentPage.value },
        REPLY_TIMEOUT,
      )
      .catch(() => undefined);

    // A reply landing after the run failed belongs to a read that is over. No
    // reply at all is a timeout.
    if (id !== runId || status.value !== "fetching") return;

    if (message?.code === 200) {
      await handlePage(id, message.payload as string).catch((error) => {
        console.error("Buy-back sync error:", error);
        if (id === runId) fail();
      });
    } else if (message && isUnknownAction(message)) {
      status.value = "unsupported";
      displayWarning({ text: t("texts.buybackSync.unsupported") });
    } else {
      fail();
    }
  };

  const start = (syncOptions: BuybackSyncOptions) => {
    // A second price pass beside the first would read every page twice, and
    // the list run would report the first pass's counts as its own.
    if (running.value || details.running.value) return;

    clear();
    abort = new AbortController();
    options = syncOptions;
    readsDetails.value = syncOptions.readDetails;
    status.value = "fetching";

    displayInfo({ text: t("messages.buybackSync.started") });

    const id = runId;

    // Only a measure to read the run against; without it the run reads all the
    // same.
    hangarBuybacks({ perPage: "1" })
      .then((stored) => {
        const count = stored.meta.pagination?.totalCount;
        // Once the list is saved the stored count is this run's own.
        if (id !== runId || status.value !== "fetching" || !count) return;

        lastCount.value = count;
        estimatePages();
      })
      .catch(() => undefined);

    void fetchPage(runId);
  };

  // Only while the list is read: once submitted it is stored, and the price
  // pass has a cancel of its own.
  const cancel = () => {
    if (status.value !== "fetching") return;

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
    status,
    currentPage,
    totalPages,
    pagesEstimated,
    lastCount,
    readsDetails,
    buybacks,
    result,
    detailsStarted,
    running,
    start,
    cancel,
    reset,
  };
};
