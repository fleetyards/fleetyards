import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import { extractBuybackDetail } from "@/frontend/lib/RSIBuybackDetailParser";
import {
  FleetyardsSyncAction,
  type FleetyardsSyncUpgradePair,
  type FleetyardsSyncUpgradePricesPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";
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

// The most from/to pairs the extension asks RSI to price in one request.
const UPGRADE_PRICES_PER_REQUEST = 4;

// Stored as they arrive, so a pass that stops halfway keeps what it read and
// the next sync carries on from there.
const DETAILS_PER_SUBMIT = 25;

// Several unreadable pages in a row is RSI changing its markup or the session
// ending, not one pledge that is gone: the rest would fail the same way.
const MAX_CONSECUTIVE_FAILURES = 3;

const pairKey = (pair: FleetyardsSyncUpgradePair) => `${pair.from}:${pair.to}`;

// Reads price and insurance for the buy-backs the list sync named as having
// none yet: the buy-back page of each package, ship, paint or add-on, and RSI's
// upgrade price for each upgrade.
export const useBuybackDetailsSync = ({ waitForSlot }: Options) => {
  const { request } = useSyncExtension();

  const mutation = useSyncRsiBuybackDetails();

  const status = ref<BuybackDetailsSyncStatus>("idle");

  const total = ref(0);

  const done = ref(0);

  let cancelled = false;

  let pending: RsiBuybackDetailInput[] = [];

  let failures = 0;

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

    if (!detail) {
      return recordFailure();
    }

    failures = 0;
    pending.push({ id, ...detail });

    return false;
  };

  const readUpgradePrices = async (
    pairs: FleetyardsSyncUpgradePair[],
    idsByPair: Map<string, string[]>,
  ) => {
    const asked = pairs.map(pairKey).join(",");

    const message = await request(
      FleetyardsSyncAction.SYNC_BUYBACK_UPGRADE_PRICES,
      { upgrades: pairs },
      undefined,
      (reply) =>
        reply.code !== 200 ||
        (
          reply.payload as FleetyardsSyncUpgradePricesPayload | undefined
        )?.prices
          ?.map(pairKey)
          .join(",") === asked,
    ).catch(() => undefined);

    const payload =
      message?.code === 200
        ? (message.payload as FleetyardsSyncUpgradePricesPayload)
        : undefined;

    pairs.forEach((pair) => {
      done.value += idsByPair.get(pairKey(pair))?.length || 0;
    });

    if (!payload?.currency || !Array.isArray(payload.prices)) {
      return recordFailure();
    }

    failures = 0;

    payload.prices.forEach((price) => {
      idsByPair.get(pairKey(price))?.forEach((id) => {
        // Stored without a price all the same, so a pair RSI no longer prices
        // is not asked about on every sync.
        pending.push(
          price.amount === null
            ? { id }
            : { id, price: price.amount / 100, currency: payload.currency },
        );
      });
    });

    return false;
  };

  const run = async (buybacks: RsiBuybackItemInput[], pendingIds: string[]) => {
    const wanted = new Set(pendingIds);
    const targets = buybacks.filter((buyback) => wanted.has(buyback.id));

    const pages: string[] = [];
    const idsByPair = new Map<string, string[]>();

    targets.forEach((buyback) => {
      if (buyback.kind !== BuybackPledgeKindEnum.UPGRADE) {
        pages.push(buyback.id);
      } else if (buyback.upgradeFromShipId && buyback.upgradeToSkuId) {
        const key = pairKey({
          from: buyback.upgradeFromShipId,
          to: buyback.upgradeToSkuId,
        });
        idsByPair.set(key, [...(idsByPair.get(key) || []), buyback.id]);
      } else {
        pending.push({ id: buyback.id });
      }
    });

    // Many upgrades share a from/to pair, and the price depends on nothing else.
    const pairs = Array.from(idsByPair.keys()).map((key) => {
      const [from, to] = key.split(":").map(Number);
      return { from, to };
    });
    const pairBatches = Array.from(
      { length: Math.ceil(pairs.length / UPGRADE_PRICES_PER_REQUEST) },
      (_, index) =>
        pairs.slice(
          index * UPGRADE_PRICES_PER_REQUEST,
          (index + 1) * UPGRADE_PRICES_PER_REQUEST,
        ),
    );

    status.value = "running";
    total.value = targets.length;
    done.value = targets.length - pages.length - countIds(idsByPair);
    failures = 0;
    cancelled = false;

    try {
      for (const batch of pairBatches) {
        await waitForSlot();
        if (cancelled) return await submit(true);

        if (await readUpgradePrices(batch, idsByPair)) {
          return await stop();
        }
        await submit(cancelled);
        if (cancelled) return;
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

const countIds = (idsByPair: Map<string, string[]>) =>
  Array.from(idsByPair.values()).reduce((sum, ids) => sum + ids.length, 0);
