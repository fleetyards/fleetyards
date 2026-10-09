import { beforeEach, describe, expect, it, vi } from "vitest";
import { type RsiBuybackItemInput } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useBuybackDetailsSync } from "./useBuybackDetailsSync";

const request = vi.fn();

vi.mock("@/frontend/composables/useSyncExtension", () => ({
  useSyncExtension: () => ({ request }),
}));

const submitDetails = vi.hoisted(() =>
  vi.fn((_: unknown) => Promise.resolve({ updated: 0 })),
);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  syncRsiBuybackDetails: submitDetails,
}));

const waitForSlot = () => Promise.resolve();

const euroPricing = {
  code: 200,
  payload: {
    currencyCode: "EUR",
    exchangeRate: 8800,
    taxRate: 1900,
    isTaxInclusive: true,
  },
};

type Reply = { code: number; id?: string; payload?: unknown };

// Answers the pricing request with an account in euros and every page request
// with `page`, honouring the request's own check of whose answer it is.
const extension = (
  page: (id: string) => Reply | Promise<Reply>,
  pricing: Reply = euroPricing,
) =>
  request.mockImplementation(
    async (
      action: string,
      params: { id?: string } = {},
      _timeout?: number,
      matches: (reply: Reply) => boolean = () => true,
    ) => {
      const reply =
        action === "syncBuybackPricing" ? pricing : await page(params.id || "");

      if (!matches(reply)) {
        throw new Error("no answer");
      }

      return reply;
    },
  );

const pageRequests = () =>
  request.mock.calls.filter(([action]) => action === "syncBuybackDetail");

const ship = (id: string): RsiBuybackItemInput => ({
  id,
  kind: "ship",
  name: `Standalone Ship - ${id}`,
});

const upgrade = (id: string): RsiBuybackItemInput => ({
  id,
  kind: "upgrade",
  name: `Upgrade - ${id}`,
  upgradeFromShipId: 308,
  upgradeToSkuId: 19461,
});

const detailPage = (cents: number, currency = "EUR") =>
  `<strong class="final-price" data-value="${cents}" data-currency="${currency}"></strong>`;

const submitted = () =>
  submitDetails.mock.calls.flatMap(
    ([input]) => (input as { items: unknown[] }).items,
  );

describe("useBuybackDetailsSync", () => {
  beforeEach(() => {
    request.mockReset();
    submitDetails.mockClear();
  });

  it("stores RSI's USD price for a page priced in the account's currency", async () => {
    extension((id) => ({ code: 200, id, payload: detailPage(15708) }));

    const { run, status } = useBuybackDetailsSync();
    await run([ship("1"), ship("2")], ["2"], { waitForSlot });

    expect(pageRequests()).toEqual([
      ["syncBuybackDetail", { id: "2" }, undefined, expect.any(Function)],
    ]);
    expect(submitted()).toEqual([
      { id: "2", price: 150, lifetimeInsurance: false },
    ]);
    expect(status.value).toBe("finished");
  });

  // An upgrade has no buy-back page; its price comes from our ship prices.
  it("reads nothing for an upgrade", async () => {
    const { run, total } = useBuybackDetailsSync();
    await run([upgrade("1")], ["1"], { waitForSlot });

    expect(request).not.toHaveBeenCalled();
    expect(submitted()).toEqual([]);
    expect(total.value).toBe(0);
  });

  // Every price read without it would be stored in the wrong currency.
  it("reads no page without the account's pricing", async () => {
    extension((id) => ({ code: 200, id, payload: detailPage(15708) }), {
      code: 502,
    });

    const { run, status } = useBuybackDetailsSync();
    await run([ship("1")], ["1"], { waitForSlot });

    expect(pageRequests()).toEqual([]);
    expect(submitted()).toEqual([]);
    expect(status.value).toBe("incomplete");
  });

  it("stores no price in another currency than the pricing", async () => {
    extension((id) =>
      id === "1"
        ? { code: 200, id, payload: detailPage(15000, "GBP") }
        : { code: 200, id, payload: detailPage(15708) },
    );

    const { run } = useBuybackDetailsSync();
    await run([ship("1"), ship("2")], ["1", "2"], { waitForSlot });

    expect(submitted()).toEqual([
      expect.objectContaining({ id: "2", price: 150 }),
    ]);
  });

  // RSI changing its markup, or the session ending, fails every page the same
  // way; reading another thousand of them would only take a quarter of an hour.
  it("stops after three unreadable pages in a row and keeps what it read", async () => {
    extension((id) =>
      id === "1"
        ? { code: 200, id, payload: detailPage(15708) }
        : { code: 200, id, payload: "<html></html>" },
    );

    const ids = ["1", "2", "3", "4", "5", "6"];

    const { run, status, done } = useBuybackDetailsSync();
    await run(ids.map(ship), ids, { waitForSlot });

    expect(pageRequests()).toHaveLength(4);
    expect(submitted()).toEqual([expect.objectContaining({ id: "1" })]);
    expect(status.value).toBe("incomplete");
    expect(done.value).toBe(4);
  });

  // A late answer to a request that timed out arrives while the next one waits.
  it("does not take a page for one pledge as another's", async () => {
    extension(() => ({ code: 200, id: "9", payload: detailPage(15708) }));

    const { run } = useBuybackDetailsSync();
    await run([ship("1")], ["1"], { waitForSlot });

    expect(submitted()).toEqual([]);
  });

  it("stores a pledge RSI has no page for any more without details", async () => {
    extension((id) => ({ code: 404, id, payload: "" }));

    const { run, status } = useBuybackDetailsSync();
    await run([ship("1")], ["1"], { waitForSlot });

    expect(submitted()).toEqual([{ id: "1" }]);
    expect(status.value).toBe("finished");
  });

  it("keeps the answer in flight when the pass is cancelled", async () => {
    let answer: (reply: Reply) => void = () => {};
    extension(() => new Promise<Reply>((resolve) => (answer = resolve)));

    const { run, cancel, status } = useBuybackDetailsSync();
    const running = run([ship("1"), ship("2")], ["1", "2"], { waitForSlot });
    await vi.waitFor(() => expect(pageRequests()).toHaveLength(1));

    cancel();
    answer({ code: 200, id: "1", payload: detailPage(15708) });
    await running;

    expect(pageRequests()).toHaveLength(1);
    expect(submitted()).toEqual([expect.objectContaining({ id: "1" })]);
    expect(status.value).toBe("idle");
  });

  // The modal that started the pass may be gone; whatever shows its progress
  // next reads the same pass.
  it("shares one pass between every caller", async () => {
    let answer: (reply: Reply) => void = () => {};
    extension(() => new Promise<Reply>((resolve) => (answer = resolve)));

    const starter = useBuybackDetailsSync();
    const running = starter.run([ship("1")], ["1"], { waitForSlot });
    await vi.waitFor(() => expect(pageRequests()).toHaveLength(1));

    const watcher = useBuybackDetailsSync();
    expect(watcher.running.value).toBe(true);
    expect(watcher.total.value).toBe(1);

    await watcher.run([ship("2")], ["2"], { waitForSlot });
    expect(pageRequests()).toHaveLength(1);

    answer({ code: 200, id: "1", payload: detailPage(15708) });
    await running;

    expect(watcher.status.value).toBe("finished");
    expect(submitted()).toEqual([expect.objectContaining({ id: "1" })]);
  });

  // Cancelled, the pass still waits for the answer in flight; whatever shows
  // it should not.
  it("says it is stopping from the cancel on", async () => {
    let answer: (reply: Reply) => void = () => {};
    extension(() => new Promise<Reply>((resolve) => (answer = resolve)));

    const { run, cancel, cancelling } = useBuybackDetailsSync();
    const running = run([ship("1"), ship("2")], ["1", "2"], { waitForSlot });
    await vi.waitFor(() => expect(pageRequests()).toHaveLength(1));

    cancel();
    expect(cancelling.value).toBe(true);

    answer({ code: 200, id: "1", payload: detailPage(15708) });
    await running;

    expect(cancelling.value).toBe(false);
  });

  // After a sign-out, a store would go to whoever is signed in by then.
  it("stores nothing once discarded, the answer in flight included", async () => {
    let answer: (reply: Reply) => void = () => {};
    extension((id) =>
      id === "1"
        ? { code: 200, id, payload: detailPage(15708) }
        : new Promise<Reply>((resolve) => (answer = resolve)),
    );

    const { run, discard, status } = useBuybackDetailsSync();
    const running = run([ship("1"), ship("2")], ["1", "2"], { waitForSlot });
    await vi.waitFor(() => expect(pageRequests()).toHaveLength(2));

    discard();
    answer({ code: 200, id: "2", payload: detailPage(15708) });
    await running;

    expect(submitted()).toEqual([]);
    expect(status.value).toBe("idle");
  });

  // Signed out, the pricing answer fails too; that is not a pass that failed.
  it("ends quietly when the pricing fails after a discard", async () => {
    let answer: (reply: Reply) => void = () => {};
    request.mockImplementation(
      () => new Promise<Reply>((resolve) => (answer = resolve)),
    );

    const { run, discard, status } = useBuybackDetailsSync();
    const running = run([ship("1")], ["1"], { waitForSlot });
    await vi.waitFor(() => expect(request).toHaveBeenCalled());

    discard();
    answer({ code: 401 });
    await running;

    expect(status.value).toBe("idle");
  });

  it("ends quietly when the last failure lands after a cancel", async () => {
    let answer: (reply: Reply) => void = () => {};
    extension((id) =>
      id === "3"
        ? new Promise<Reply>((resolve) => (answer = resolve))
        : { code: 200, id, payload: "<html></html>" },
    );

    const ids = ["1", "2", "3", "4"];
    const { run, cancel, status } = useBuybackDetailsSync();
    const running = run(ids.map(ship), ids, { waitForSlot });
    await vi.waitFor(() => expect(pageRequests()).toHaveLength(3));

    cancel();
    answer({ code: 200, id: "3", payload: "<html></html>" });
    await running;

    expect(status.value).toBe("idle");
  });

  it("stops while waiting for a slot as soon as it is cancelled", async () => {
    extension((id) => ({ code: 200, id, payload: detailPage(15708) }));

    let slotWaits = 0;
    const blockedSlot = (signal: AbortSignal) =>
      ++slotWaits === 1
        ? Promise.resolve()
        : new Promise<void>((resolve) =>
            signal.addEventListener("abort", () => resolve()),
          );

    const { run, cancel, status } = useBuybackDetailsSync();
    const running = run([ship("1")], ["1"], { waitForSlot: blockedSlot });
    await vi.waitFor(() => expect(slotWaits).toBe(2));

    cancel();
    await running;

    expect(pageRequests()).toHaveLength(0);
    expect(status.value).toBe("idle");
  });

  it("tells the lists once, after the last batch is stored", async () => {
    extension((id) => ({ code: 200, id, payload: detailPage(15708) }));

    const finished = vi.fn();
    const off = useComlink().on("buyback-sync-finished", finished);

    const ids = Array.from({ length: 30 }, (_, index) => String(index + 1));
    const { run } = useBuybackDetailsSync();
    await run(ids.map(ship), ids, { waitForSlot });
    off();

    expect(submitDetails).toHaveBeenCalledTimes(2);
    expect(finished).toHaveBeenCalledTimes(1);
  });
});
