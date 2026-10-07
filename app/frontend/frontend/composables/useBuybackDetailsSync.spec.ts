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

const ship = (id: string): RsiBuybackItemInput => ({
  id,
  kind: "ship",
  name: `Standalone Ship - ${id}`,
});

const upgrade = (
  id: string,
  from: number,
  to: number,
): RsiBuybackItemInput => ({
  id,
  kind: "upgrade",
  name: `Upgrade - ${id}`,
  upgradeFromShipId: from,
  upgradeToSkuId: to,
});

const detailPage = (cents: number) =>
  `<strong class="final-price" data-value="${cents}" data-currency="EUR"></strong>`;

const submitted = () =>
  submitDetails.mock.calls.flatMap(
    ([variables]) => (variables as { data: { items: unknown[] } }).data.items,
  );

describe("useBuybackDetailsSync", () => {
  beforeEach(() => {
    request.mockReset();
    submitDetails.mockClear();
  });

  it("reads only the pledges the list sync named", async () => {
    request.mockResolvedValue({ code: 200, id: "2", payload: detailPage(500) });

    const { run, status } = useBuybackDetailsSync({ waitForSlot });
    await run([ship("1"), ship("2")], ["2"]);

    expect(request).toHaveBeenCalledTimes(1);
    expect(request).toHaveBeenCalledWith(
      "syncBuybackDetail",
      { id: "2" },
      undefined,
      expect.any(Function),
    );
    expect(submitted()).toEqual([
      { id: "2", price: 5, currency: "EUR", lifetimeInsurance: false },
    ]);
    expect(status.value).toBe("finished");
  });

  // An upgrade has no buy-back page; its price comes from our ship prices.
  it("reads no page for an upgrade", async () => {
    const { run, total } = useBuybackDetailsSync({ waitForSlot });
    await run([upgrade("1", 308, 19461)], ["1"]);

    expect(request).not.toHaveBeenCalled();
    expect(submitted()).toEqual([]);
    expect(total.value).toBe(0);
  });

  // RSI changing its markup, or the session ending, fails every page the same
  // way; reading another thousand of them would only take a quarter of an hour.
  it("stops after three unreadable pages in a row and keeps what it read", async () => {
    request
      .mockResolvedValueOnce({ code: 200, id: "1", payload: detailPage(500) })
      .mockResolvedValue({ code: 200, payload: "<html></html>" });

    const ids = ["1", "2", "3", "4", "5", "6"];

    const { run, status, done } = useBuybackDetailsSync({ waitForSlot });
    await run(ids.map(ship), ids);

    expect(request).toHaveBeenCalledTimes(4);
    expect(submitted()).toEqual([expect.objectContaining({ id: "1" })]);
    expect(status.value).toBe("incomplete");
    expect(done.value).toBe(4);
  });

  // A late answer to a request that timed out arrives while the next one waits.
  it("does not take a page for one pledge as another's", async () => {
    request.mockImplementation((_action, _params, _timeout, matches) => {
      const reply = { code: 200, id: "9", payload: detailPage(500) };

      return matches(reply)
        ? Promise.resolve(reply)
        : Promise.reject(new Error("no answer"));
    });

    const { run } = useBuybackDetailsSync({ waitForSlot });
    await run([ship("1")], ["1"]);

    expect(submitted()).toEqual([]);
  });

  it("stores a pledge RSI has no page for any more without details", async () => {
    request.mockResolvedValue({ code: 404, id: "1", payload: "" });

    const { run, status } = useBuybackDetailsSync({ waitForSlot });
    await run([ship("1")], ["1"]);

    expect(submitted()).toEqual([{ id: "1" }]);
    expect(status.value).toBe("finished");
  });

  it("keeps the answer in flight when the pass is cancelled", async () => {
    let answer: (reply: unknown) => void = () => {};
    request.mockReturnValue(new Promise((resolve) => (answer = resolve)));

    const { run, cancel } = useBuybackDetailsSync({ waitForSlot });
    const running = run([ship("1"), ship("2")], ["1", "2"]);
    await Promise.resolve();

    cancel();
    answer({ code: 200, id: "1", payload: detailPage(500) });
    await running;

    expect(request).toHaveBeenCalledTimes(1);
    expect(submitted()).toEqual([expect.objectContaining({ id: "1" })]);
  });
});
