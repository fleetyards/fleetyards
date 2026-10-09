import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import { extractBuybackDetail } from "@/frontend/lib/RSIBuybackDetailParser";
import {
  toUsdCents,
  type RSIStorePricing,
} from "@/frontend/lib/RSIStorePricing";
import { FleetyardsSyncAction } from "@/frontend/lib/FleetyardsSyncHandler";
import { useComlink } from "@/shared/composables/useComlink";
import {
  BuybackPledgeKindEnum,
  syncRsiBuybackDetails,
  type RsiBuybackDetailInput,
  type RsiBuybackItemInput,
} from "@/services/fyApi";

export type BuybackDetailsSyncStatus =
  "idle" | "running" | "finished" | "incomplete";

type RunOptions = {
  // Resolves once another request to RSI may go out; shared with the list crawl
  // so both together stay inside one rate limit.
  // Returns early once `signal` aborts.
  waitForSlot: (signal: AbortSignal) => Promise<void>;
};

// Stored as they arrive, so a pass that stops halfway keeps what it read and
// the next sync carries on from there.
const DETAILS_PER_SUBMIT = 25;

// Several unreadable pages in a row is RSI changing its markup or the session
// ending, not one pledge that is gone: the rest would fail the same way.
const MAX_CONSECUTIVE_FAILURES = 3;

// A pass of a thousand pledges takes a quarter of an hour at the rate limit,
// so it belongs to the page, not to the modal that started it: the state is
// shared, and closing the modal or changing the route leaves the pass running.
const status = ref<BuybackDetailsSyncStatus>("idle");

const total = ref(0);

const done = ref(0);

const running = computed(() => status.value === "running");

const cancelled = ref(false);

// From the cancel until the pass actually stops, which can take as long as the
// request in flight.
const cancelling = computed(() => running.value && cancelled.value);

let abort = new AbortController();

// A discarded pass stores nothing more, not even what it already read.
let discarded = false;

let pending: RsiBuybackDetailInput[] = [];

let failures = 0;

let pricing: RSIStorePricing | undefined;

// Reads price and insurance from the RSI buy-back page of each pledge the list
// sync named as having none yet. Upgrades are priced from our own ship prices
// and have no such page. A page prices in the account's currency with tax, so
// the account's store pricing is read first to turn that back into RSI's USD
// figure, the one every other price here is in.
export const useBuybackDetailsSync = () => {
  const { request } = useSyncExtension();

  const comlink = useComlink();

  const submit = async (force = false) => {
    if (
      discarded ||
      pending.length === 0 ||
      (!force && pending.length < DETAILS_PER_SUBMIT)
    ) {
      return;
    }

    const items = pending;
    pending = [];

    try {
      await syncRsiBuybackDetails({ items });
    } catch (error) {
      pending = [...items, ...pending];
      throw error;
    }

    comlink.emit("buyback-sync-finished");
  };

  const recordFailure = () => {
    failures += 1;

    return failures >= MAX_CONSECUTIVE_FAILURES;
  };

  const readDetailPage = async (id: string) => {
    const message = await request(
      FleetyardsSyncAction.SYNC_BUYBACK_DETAIL,
      { id },
      undefined,
      (reply) => reply.id === id,
    ).catch(() => undefined);

    done.value += 1;

    // A pledge RSI has no page for any more is stored without details, so it is
    // not asked about on every sync. Anything else unreadable may be the session
    // or RSI's markup, and is asked about again.
    if (message?.code === 404) {
      failures = 0;
      pending.push({ id });

      return false;
    }

    const detail =
      message?.code === 200
        ? extractBuybackDetail(message.payload as string)
        : undefined;

    if (!detail || !pricing) {
      return recordFailure();
    }

    const { cents, currency, ...insurance } = detail;
    const usdCents =
      cents === undefined || !currency
        ? undefined
        : toUsdCents(cents, currency, pricing);

    // A price in another currency than the pricing read at the start means
    // the account's currency changed during the pass; nothing read from here
    // on can be converted.
    if (cents !== undefined && usdCents === undefined) {
      return recordFailure();
    }

    failures = 0;
    pending.push({
      id,
      ...insurance,
      ...(usdCents === undefined ? {} : { price: usdCents / 100 }),
    });

    return false;
  };

  const readPricing = async () => {
    const message = await request(
      FleetyardsSyncAction.SYNC_BUYBACK_PRICING,
    ).catch(() => undefined);

    return message?.code === 200
      ? (message.payload as RSIStorePricing)
      : undefined;
  };

  // A pass stopped on purpose failed nothing, even when its last request did.
  const endIncomplete = () => {
    status.value = cancelled.value ? "idle" : "incomplete";
  };

  const run = async (
    buybacks: RsiBuybackItemInput[],
    pendingIds: string[],
    { waitForSlot }: RunOptions,
  ) => {
    // A second pass beside the first would read every page twice and halve
    // the rate limit each has.
    if (running.value) return;

    const wanted = new Set(pendingIds);
    const pages = buybacks
      .filter(
        (buyback) =>
          wanted.has(buyback.id) &&
          buyback.kind !== BuybackPledgeKindEnum.UPGRADE,
      )
      .map((buyback) => buyback.id);

    status.value = "running";
    total.value = pages.length;
    done.value = 0;
    failures = 0;
    pending = [];
    cancelled.value = false;
    discarded = false;
    abort = new AbortController();

    if (pages.length === 0) {
      status.value = "finished";
      return;
    }

    try {
      await waitForSlot(abort.signal);
      if (cancelled.value) return;

      // Without it no page's price could be stored, so none is read.
      pricing = await readPricing();
      if (!pricing) {
        endIncomplete();
        return;
      }

      for (const id of pages) {
        await waitForSlot(abort.signal);
        if (cancelled.value) return await submit(true);

        if (await readDetailPage(id)) {
          return await stop();
        }
        await submit(cancelled.value);
        if (cancelled.value) return;
      }

      await submit(true);
      status.value = "finished";
    } catch (error) {
      console.error("Buy-back details sync error:", error);
      endIncomplete();
    } finally {
      // Only a cancelled pass gets here still running.
      if (status.value === "running") {
        status.value = "idle";
      }
    }
  };

  const stop = async () => {
    await submit(true);
    endIncomplete();
  };

  // The pass stops at the next request, and what was read up to then, the
  // answer in flight included, is still stored.
  const cancel = () => {
    cancelled.value = true;
    abort.abort();
  };

  const discard = () => {
    discarded = true;
    pending = [];
    cancel();
  };

  return { status, total, done, running, cancelling, run, cancel, discard };
};
