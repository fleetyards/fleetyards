import { beforeEach, describe, expect, it, vi } from "vitest";
import { type RsiBuybackItemInput } from "@/services/fyApi";
import { useBuybackDetailsSync } from "./useBuybackDetailsSync";

const request = vi.fn();

vi.mock("@/frontend/composables/useSyncExtension", () => ({
  useSyncExtension: () => ({ request }),
}));

const submitDetails = vi.fn((_: unknown) => Promise.resolve({ updated: 0 }));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useSyncRsiBuybackDetails: () => ({ mutateAsync: submitDetails }),
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
    ([variables]) => (variables as { data: { items: unknown[] } }).data.items,
  );

describe("useBuybackDetailsSync", () => {
  beforeEach(() => {
    request.mockReset();
    submitDetails.mockClear();
  });

  it("stores RSI's USD price for a page priced in the account's currency", async () => {
    extension((id) => ({ code: 200, id, payload: detailPage(15708) }));

    const { run, status } = useBuybackDetailsSync({ waitForSlot });
    await run([ship("1"), ship("2")], ["2"]);

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
    const { run, total } = useBuybackDetailsSync({ waitForSlot });
    await run([upgrade("1")], ["1"]);

    expect(request).not.toHaveBeenCalled();
    expect(submitted()).toEqual([]);
    expect(total.value).toBe(0);
  });

  // Every price read without it would be stored in the wrong currency.
  it("reads no page without the account's pricing", async () => {
    extension((id) => ({ code: 200, id, payload: detailPage(15708) }), {
      code: 502,
    });

    const { run, status } = useBuybackDetailsSync({ waitForSlot });
    await run([ship("1")], ["1"]);

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

    const { run } = useBuybackDetailsSync({ waitForSlot });
    await run([ship("1"), ship("2")], ["1", "2"]);

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

    const { run, status, done } = useBuybackDetailsSync({ waitForSlot });
    await run(ids.map(ship), ids);

    expect(pageRequests()).toHaveLength(4);
    expect(submitted()).toEqual([expect.objectContaining({ id: "1" })]);
    expect(status.value).toBe("incomplete");
    expect(done.value).toBe(4);
  });

  // A late answer to a request that timed out arrives while the next one waits.
  it("does not take a page for one pledge as another's", async () => {
    extension(() => ({ code: 200, id: "9", payload: detailPage(15708) }));

    const { run } = useBuybackDetailsSync({ waitForSlot });
    await run([ship("1")], ["1"]);

    expect(submitted()).toEqual([]);
  });

  it("stores a pledge RSI has no page for any more without details", async () => {
    extension((id) => ({ code: 404, id, payload: "" }));

    const { run, status } = useBuybackDetailsSync({ waitForSlot });
    await run([ship("1")], ["1"]);

    expect(submitted()).toEqual([{ id: "1" }]);
    expect(status.value).toBe("finished");
  });

  it("keeps the answer in flight when the pass is cancelled", async () => {
    let answer: (reply: Reply) => void = () => {};
    extension(() => new Promise<Reply>((resolve) => (answer = resolve)));

    const { run, cancel } = useBuybackDetailsSync({ waitForSlot });
    const running = run([ship("1"), ship("2")], ["1", "2"]);
    await vi.waitFor(() => expect(pageRequests()).toHaveLength(1));

    cancel();
    answer({ code: 200, id: "1", payload: detailPage(15708) });
    await running;

    expect(pageRequests()).toHaveLength(1);
    expect(submitted()).toEqual([expect.objectContaining({ id: "1" })]);
  });
});
