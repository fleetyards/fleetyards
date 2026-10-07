import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import { extractBuybackDetail } from "@/frontend/lib/RSIBuybackDetailParser";
import {
  toUsdCents,
  type RSIStorePricing,
} from "@/frontend/lib/RSIStorePricing";
import { FleetyardsSyncAction } from "@/frontend/lib/FleetyardsSyncHandler";
import {
  BuybackPledgeKindEnum,
  useSyncRsiBuybackDetails,
  type RsiBuybackDetailInput,
  type RsiBuybackItemInput,
} from "@/services/fyApi";

export type BuybackDetailsSyncStatus =
  "idle" | "running" | "finished" | "incomplete";

type Options = {
  // Resolves once another request to RSI may go out; shared with the list crawl
  // so both together stay inside one rate limit.
  waitForSlot: () => Promise<void>;
};

// Stored as they arrive, so a pass that stops halfway keeps what it read and
// the next sync carries on from there.
const DETAILS_PER_SUBMIT = 25;

// Several unreadable pages in a row is RSI changing its markup or the session
// ending, not one pledge that is gone: the rest would fail the same way.
const MAX_CONSECUTIVE_FAILURES = 3;

// Reads price and insurance from the RSI buy-back page of each pledge the list
// sync named as having none yet. Upgrades are priced from our own ship prices
// and have no such page. A page prices in the account's currency with tax, so
// the account's store pricing is read first to turn that back into RSI's USD
// figure, the one every other price here is in.
export const useBuybackDetailsSync = ({ waitForSlot }: Options) => {
  const { request } = useSyncExtension();

  const mutation = useSyncRsiBuybackDetails();

  const status = ref<BuybackDetailsSyncStatus>("idle");

  const total = ref(0);

  const done = ref(0);

  let cancelled = false;

  let pending: RsiBuybackDetailInput[] = [];

  let failures = 0;

  let pricing: RSIStorePricing | undefined;

  const submit = async (force = false) => {
    if (
      pending.length === 0 ||
      (!force && pending.length < DETAILS_PER_SUBMIT)
    ) {
      return;
    }

    const items = pending;
    pending = [];

    try {
      await mutation.mutateAsync({ data: { items } });
    } catch (error) {
      pending = [...items, ...pending];
      throw error;
    }
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

  const run = async (buybacks: RsiBuybackItemInput[], pendingIds: string[]) => {
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
    cancelled = false;

    if (pages.length === 0) {
      status.value = "finished";
      return;
    }

    try {
      await waitForSlot();
      if (cancelled) return;

      // Without it no page's price could be stored, so none is read.
      pricing = await readPricing();
      if (!pricing) {
        status.value = "incomplete";
        return;
      }

      for (const id of pages) {
        await waitForSlot();
        if (cancelled) return await submit(true);

        if (await readDetailPage(id)) {
          return await stop();
        }
        await submit(cancelled);
        if (cancelled) return;
      }

      await submit(true);
      status.value = "finished";
    } catch (error) {
      console.error("Buy-back details sync error:", error);
      status.value = "incomplete";
    }
  };

  const stop = async () => {
    await submit(true);
    status.value = "incomplete";
  };

  // The pass stops at the next request, and what was read up to then, the
  // answer in flight included, is still stored.
  const cancel = () => {
    cancelled = true;
  };

  return { status, total, done, run, cancel };
};
