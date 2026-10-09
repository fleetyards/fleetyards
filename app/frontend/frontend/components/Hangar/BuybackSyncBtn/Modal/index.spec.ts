import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { useHangarStore } from "@/frontend/stores/hangar";
import { RsiPageCheckEnum, RsiPageKindEnum } from "@/services/fyApi";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useBuybackSync } from "@/frontend/composables/useBuybackSync";
import { rsiRateLimiter } from "@/frontend/lib/RsiRateLimiter";
import Component from "./index.vue";

const mutateAsync = vi.fn<
  (_input: unknown) => Promise<{
    total: number;
    added: number;
    removed: number;
    detailsPending: string[];
  }>
>(() =>
  Promise.resolve({ total: 2, added: 2, removed: 0, detailsPending: [] }),
);

const submitDetails = vi.hoisted(() =>
  vi.fn((_: unknown) => Promise.resolve({ updated: 1 })),
);
const reportMutateAsync = vi.fn((_input: unknown) => Promise.resolve());

// What the extension says about the RSI session when the modal checks it
// before reporting a page.
const rsiIdentity = vi.fn(
  async (): Promise<{ code: number; payload: { handle?: string } }> => ({
    code: 200,
    payload: { handle: "ACaptain" },
  }),
);

// Only the identify check: the detail pass talks to the extension through the
// same composable, and its requests have to reach `postMessage`.
vi.mock("@/frontend/composables/useSyncExtension", async (importOriginal) => {
  const actual =
    await importOriginal<
      typeof import("@/frontend/composables/useSyncExtension")
    >();

  return {
    useSyncExtension: () => {
      const extension = actual.useSyncExtension();

      return {
        ...extension,
        request: (action: string, ...rest: unknown[]) =>
          action === "identify"
            ? rsiIdentity()
            : (extension.request as (...args: unknown[]) => unknown)(
                action,
                ...rest,
              ),
      };
    },
  };
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  syncRsiBuybacks: (data: unknown) => mutateAsync({ data }),
  syncRsiBuybackDetails: submitDetails,
  reportRsiPage: (data: unknown) => reportMutateAsync({ data }),
}));

const comlinkEmit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: comlinkEmit, on: vi.fn(), off: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const displayWarning = vi.hoisted(() => vi.fn());

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displayInfo: vi.fn(),
    displaySuccess: vi.fn(),
    displayWarning,
    displayAlert: vi.fn(),
  }),
}));

// jsdom's `postMessage` insists on a targetOrigin the component does not pass.
vi.spyOn(window, "postMessage").mockImplementation(() => {});

const extensionReplies = (
  action: string,
  payload?: unknown,
  {
    code = 200,
    error,
    id,
  }: { code?: number; error?: string; id?: string } = {},
) => {
  window.dispatchEvent(
    new MessageEvent("message", {
      source: window,
      data: {
        direction: "fy-sync",
        message: JSON.stringify({ action, code, payload, error, id }),
      },
    }),
  );
};

const buybackList = (entries: string) =>
  `<section class="available-pledges"><ul class="pledges">${entries}</ul></section>`;

const buybackPage = (id: string) =>
  buybackList(`<li><article class="pledge">
  <h1 title="Standalone Ship - Cutlass Black">Standalone Ship - Cutlass Black</h1>
  <a class="holosmallbtn" href="/pledge/buyback/${id}">Buy Back</a>
</article></li>`);

// What RSI renders past the last page.
const emptyBuybackPage = buybackList(
  '<li class="no-buy-backs">No pledges available</li>',
);

const askedFor = (action: string) =>
  vi
    .mocked(window.postMessage)
    .mock.calls.some(([data]) =>
      String((data as { message?: string })?.message).includes(
        `"action":"${action}"`,
      ),
    );

const pageRequests = () =>
  vi
    .mocked(window.postMessage)
    .mock.calls.filter(([data]) =>
      String((data as { message?: string })?.message).includes(
        '"action":"syncBuyback"',
      ),
    ).length;

let pagesAnswered = 0;

// The modal asks for the next page a moment after the last one: an answer only
// lands once it has been asked for.
const answerNextPage = async (
  html: string | undefined,
  options?: { code?: number; error?: string },
) => {
  await vi.waitFor(
    () => expect(pageRequests()).toBeGreaterThan(pagesAnswered),
    {
      timeout: 2000,
    },
  );
  pagesAnswered += 1;
  extensionReplies("syncBuyback", html, options);
  await flushPromises();
};

const currentExtension = {
  version: "1.3.0",
  actions: ["health", "identify", "sync", "syncBuyback"],
};

// The modal listens on `window` while mounted, so one left behind would answer
// the next test's extension replies as well.
let mounted: ReturnType<typeof mount> | undefined;

const mountModal = async (health?: unknown) => {
  const wrapper = mount(Component, {
    global: {
      plugins: [createTestingPinia()],
      stubs: {
        Modal: { template: "<div><slot /><slot name='footer' /></div>" },
      },
      directives: { Tooltip: {} },
    },
  });

  mounted = wrapper;
  await flushPromises();

  extensionReplies("health", health);
  await flushPromises();

  return wrapper;
};

const startSync = async () => {
  const wrapper = await mountModal(currentExtension);

  extensionReplies("identify", { handle: "ACaptain" });
  await flushPromises();

  await wrapper.find("[data-test='start-buyback-sync']").trigger("click");
  await flushPromises();

  return wrapper;
};

describe("HangarBuybackSyncModal", () => {
  beforeEach(() => {
    rsiRateLimiter.reset();
    mutateAsync.mockClear();
    submitDetails.mockClear();
    reportMutateAsync.mockClear();
    rsiIdentity.mockClear();
    comlinkEmit.mockClear();
    displayWarning.mockClear();
    vi.mocked(window.postMessage).mockClear();
    pagesAnswered = 0;
  });

  // The run outlives the modal, so one left over would greet the next test
  // instead of the start screen.
  afterEach(() => {
    mounted?.unmount();
    mounted = undefined;
    useBuybackSync().reset(true);
  });

  it("shows which RSI account the extension is signed in to", async () => {
    const wrapper = await mountModal(currentExtension);

    extensionReplies("identify", { handle: "ACaptain" });
    await flushPromises();

    expect(
      wrapper.find("[data-test='sync-extension-signed-in-as']").exists(),
    ).toBe(true);
  });

  // Every released version before buy-backs answers the health check with no
  // payload at all.
  it("asks for an update from an extension that reports nothing", async () => {
    const wrapper = await mountModal();

    expect(wrapper.find("[data-test='buyback-sync-outdated']").exists()).toBe(
      true,
    );
    expect(wrapper.find("[data-test='start-buyback-sync']").exists()).toBe(
      false,
    );
    expect(askedFor("identify")).toBe(false);
  });

  it("names the installed version of an extension without buy-backs", async () => {
    const wrapper = await mountModal({
      version: "1.2.6",
      actions: ["health", "identify", "sync"],
    });

    expect(
      wrapper.find("[data-test='buyback-sync-outdated']").text(),
    ).toContain("1.2.6");
    expect(wrapper.find("[data-test='start-buyback-sync']").exists()).toBe(
      false,
    );
  });

  it("asks only for the buy-back pages, never the hangar", async () => {
    await startSync();

    expect(askedFor("syncBuyback")).toBe(true);
    expect(askedFor("sync")).toBe(false);
  });

  it("reads every page before submitting the list", async () => {
    const wrapper = await startSync();

    await answerNextPage(buybackPage("1"));
    await answerNextPage(buybackPage("2"));

    expect(mutateAsync).not.toHaveBeenCalled();

    await answerNextPage(emptyBuybackPage);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: {
        items: [
          expect.objectContaining({ id: "1", kind: "ship" }),
          expect.objectContaining({ id: "2", kind: "ship" }),
        ],
      },
    });
    expect(wrapper.find("[data-test='buyback-sync-added']").text()).toBe("2");
  });

  it("keeps reading the list once the modal is closed", async () => {
    const wrapper = await startSync();

    await wrapper
      .find("[data-test='background-buyback-sync']")
      .trigger("click");
    expect(comlinkEmit).toHaveBeenCalledWith("close-modal");
    wrapper.unmount();
    mounted = undefined;

    await answerNextPage(buybackPage("1"));
    await answerNextPage(emptyBuybackPage);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: { items: [expect.objectContaining({ id: "1" })] },
    });
    expect(useBuybackSync().status.value).toBe("finished");
  });

  it("opens on a run that is still going", async () => {
    const first = await startSync();
    first.unmount();

    const wrapper = await mountModal(currentExtension);

    expect(wrapper.find("[data-test='buyback-sync-progress']").exists()).toBe(
      true,
    );
    expect(wrapper.find("[data-test='background-buyback-sync']").exists()).toBe(
      true,
    );
    expect(wrapper.find("[data-test='start-buyback-sync']").exists()).toBe(
      false,
    );
  });

  it("shows the result of a run that ended in the background", async () => {
    const first = await startSync();
    first.unmount();

    await answerNextPage(buybackPage("1"));
    await answerNextPage(emptyBuybackPage);

    const wrapper = await mountModal(currentExtension);

    expect(wrapper.find("[data-test='buyback-sync-added']").text()).toBe("2");
    wrapper.unmount();
    mounted = undefined;

    // Shown once: the next open is a fresh start screen.
    const again = await mountModal(currentExtension);
    expect(again.find("[data-test='buyback-sync-added']").exists()).toBe(false);
  });

  // A submitted list is stored whatever the modal does; only the read can be
  // cancelled.
  it("offers only the background once the list is submitted", async () => {
    mutateAsync.mockImplementationOnce(() => new Promise(() => {}));
    const wrapper = await startSync();

    await answerNextPage(buybackPage("1"));
    await answerNextPage(emptyBuybackPage);

    expect(wrapper.text()).toContain("labels.buybackSync.status.submitting");
    expect(wrapper.find("[data-test='close-buyback-sync']").exists()).toBe(
      false,
    );
    expect(wrapper.find("[data-test='background-buyback-sync']").exists()).toBe(
      true,
    );
  });

  it("stops reading the list when cancelled", async () => {
    const wrapper = await startSync();

    await wrapper.find("[data-test='close-buyback-sync']").trigger("click");
    expect(comlinkEmit).toHaveBeenCalledWith("close-modal");
    expect(useBuybackSync().status.value).toBe("idle");

    extensionReplies("syncBuyback", emptyBuybackPage);
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
  });

  // Both syncs take their requests from one budget, so neither has to wait for
  // the other to finish.
  it("starts while a hangar sync is running", async () => {
    const wrapper = await mountModal(currentExtension);
    useHangarStore().syncRunning = true;

    extensionReplies("identify", { handle: "ACaptain" });
    await flushPromises();

    expect(
      wrapper.find("[data-test='start-buyback-sync']").attributes("disabled"),
    ).toBeUndefined();
  });

  // The same guard the hangar sync has: a page repeating ids already read
  // would otherwise keep the loop asking forever.
  it("stops at a page with nothing new on it", async () => {
    await startSync();

    await answerNextPage(buybackPage("1"));
    await answerNextPage(buybackPage("1"));

    expect(mutateAsync).toHaveBeenCalledWith({
      data: { items: [expect.objectContaining({ id: "1" })] },
    });
  });

  // An expired RSI session answers with the login page, and a 200 at that.
  // Read as an empty list, it would delete every stored buy-back.
  it("submits nothing for a page that is not the buy-back page", async () => {
    await startSync();

    await answerNextPage("<html><body></body></html>");

    expect(mutateAsync).not.toHaveBeenCalled();
  });

  it("reports a page it does not recognise", async () => {
    await startSync();

    await answerNextPage(buybackPage("1"));
    await answerNextPage(
      buybackList(`<li><a href="/pledge/buyback/2">Buy Back</a></li>`),
    );

    expect(mutateAsync).not.toHaveBeenCalled();
    expect(reportMutateAsync).toHaveBeenCalledWith({
      data: {
        page: RsiPageKindEnum.BUYBACK,
        check: RsiPageCheckEnum.MISSING_ENTRIES,
        pageNumber: 2,
        extensionVersion: "1.3.0",
      },
    });
  });

  // The modal is usually closed by then, so nothing else would say it.
  it("warns when the RSI session runs out mid-read", async () => {
    const wrapper = await startSync();
    wrapper.unmount();
    mounted = undefined;
    rsiIdentity.mockResolvedValueOnce({ code: 400, payload: {} });

    await answerNextPage("<html><body></body></html>");

    expect(useBuybackSync().status.value).toBe("failed");
    expect(displayWarning).toHaveBeenCalledWith({
      text: "messages.syncExtension.notLoggedIn",
    });
  });

  it("shows a running read before the extension has answered", async () => {
    const first = await startSync();
    first.unmount();

    const wrapper = mount(Component, {
      global: {
        plugins: [createTestingPinia()],
        stubs: {
          Modal: { template: "<div><slot /><slot name='footer' /></div>" },
        },
        directives: { Tooltip: {} },
      },
    });
    mounted = wrapper;
    await flushPromises();

    expect(wrapper.find("[data-test='buyback-sync-progress']").exists()).toBe(
      true,
    );
    expect(wrapper.text()).not.toContain("texts.syncExtension.gettingStarted");
  });

  it("asks RSI for no session check while a read is going", async () => {
    const first = await startSync();
    first.unmount();
    rsiIdentity.mockClear();

    await mountModal(currentExtension);

    expect(rsiIdentity).not.toHaveBeenCalled();
  });

  it("reports nothing when the RSI session has run out", async () => {
    await startSync();
    rsiIdentity.mockResolvedValueOnce({ code: 400, payload: {} });

    await answerNextPage("<html><body></body></html>");

    expect(mutateAsync).not.toHaveBeenCalled();
    expect(reportMutateAsync).not.toHaveBeenCalled();
    // On open, before the report, and once the run has ended so Start knows
    // the session is gone.
    expect(rsiIdentity).toHaveBeenCalledTimes(3);
  });

  it("submits nothing when a page's entries cannot be read", async () => {
    await startSync();

    await answerNextPage(buybackPage("1"));
    await answerNextPage(
      buybackList(`<li><article class="pledge"><h1>Gear</h1></article></li>`),
    );

    expect(mutateAsync).not.toHaveBeenCalled();
  });

  it("submits nothing when a page cannot be fetched", async () => {
    await startSync();

    await answerNextPage(buybackPage("1"));
    await answerNextPage("", { code: 403 });

    expect(mutateAsync).not.toHaveBeenCalled();
  });

  // The next page is asked for on a timer, which can fire after the crawl was
  // given up on.
  it("asks for no further page once the sync has failed", async () => {
    await startSync();

    await answerNextPage(buybackPage("1"));
    await answerNextPage("", { code: 403 });

    vi.mocked(window.postMessage).mockClear();
    await new Promise((resolve) => setTimeout(resolve, 600));

    expect(askedFor("syncBuyback")).toBe(false);
  });

  it("says so when the extension predates buy-backs", async () => {
    const wrapper = await startSync();

    await answerNextPage(undefined, {
      code: 500,
      error: "Unknown Action",
    });

    expect(mutateAsync).not.toHaveBeenCalled();
    expect(wrapper.text()).toContain("texts.buybackSync.unsupported");
    expect(displayWarning).toHaveBeenCalledWith({
      text: "texts.buybackSync.unsupported",
    });
  });

  describe("prices and insurance", () => {
    const detailExtension = {
      version: "1.4.0",
      actions: [
        ...currentExtension.actions,
        "syncBuybackDetail",
        "syncBuybackPricing",
      ],
    };

    const detailPage = `<strong class="final-price" data-value="10472" data-currency="EUR"></strong>
<div class="package-listing item"><ul><li>6 Month Insurance</li></ul></div>`;

    // The pass outlives the test that started it, and a pass still running
    // holds the next test's sync back.
    const finishPass = async () => {
      extensionReplies("syncBuybackPricing", {
        currencyCode: "EUR",
        exchangeRate: 8800,
        taxRate: 1900,
        isTaxInclusive: true,
      });
      await flushPromises();
      extensionReplies("syncBuybackDetail", detailPage, { id: "1" });
      await flushPromises();
    };

    const syncList = async (health: unknown) => {
      mutateAsync.mockResolvedValueOnce({
        total: 1,
        added: 1,
        removed: 0,
        detailsPending: ["1"],
      });

      const wrapper = await mountModal(health);

      extensionReplies("identify", { handle: "ACaptain" });
      await flushPromises();
      await wrapper.find("[data-test='start-buyback-sync']").trigger("click");
      await flushPromises();

      await answerNextPage(buybackPage("1"));
      await answerNextPage(emptyBuybackPage);

      return wrapper;
    };

    it("reads the buy-back page of a pledge the list sync has no details for", async () => {
      const wrapper = await syncList(detailExtension);

      expect(askedFor("syncBuybackPricing")).toBe(true);

      extensionReplies("syncBuybackPricing", {
        currencyCode: "EUR",
        exchangeRate: 8800,
        taxRate: 1900,
        isTaxInclusive: true,
      });
      await flushPromises();

      expect(askedFor("syncBuybackDetail")).toBe(true);

      extensionReplies("syncBuybackDetail", detailPage, { id: "1" });
      await flushPromises();

      expect(submitDetails).toHaveBeenCalledWith({
        items: [
          {
            id: "1",
            price: 100,
            insuranceMonths: 6,
            lifetimeInsurance: false,
          },
        ],
      });
      expect(wrapper.find("[data-test='buyback-sync-prices']").text()).toBe(
        "1 / 1",
      );
    });

    // A long list takes a quarter of an hour; the list itself is already
    // stored, and nothing about the prices needs the modal open.
    it("finishes the list sync while prices are still being read", async () => {
      const wrapper = await syncList(detailExtension);

      expect(wrapper.text()).toContain("labels.buybackSync.status.finished");
      expect(
        wrapper.find("[data-test='buyback-sync-details-background']").exists(),
      ).toBe(true);
      expect(
        wrapper.find("[data-test='close-buyback-sync']").attributes("disabled"),
      ).toBeUndefined();

      wrapper.unmount();
      mounted = undefined;

      extensionReplies("syncBuybackPricing", {
        currencyCode: "EUR",
        exchangeRate: 8800,
        taxRate: 1900,
        isTaxInclusive: true,
      });
      await flushPromises();
      extensionReplies("syncBuybackDetail", detailPage, { id: "1" });
      await flushPromises();

      expect(submitDetails).toHaveBeenCalledWith({
        items: [expect.objectContaining({ id: "1", price: 100 })],
      });
    });

    // A second pass would read the same pages again beside the first.
    // The modal disables Start; the run refuses on its own as well.
    it("starts no new list read while prices are still being read", async () => {
      await syncList(detailExtension);
      vi.mocked(window.postMessage).mockClear();

      useBuybackSync().start({ readDetails: true });
      await flushPromises();

      expect(useBuybackSync().status.value).toBe("finished");
      expect(askedFor("syncBuyback")).toBe(false);

      await finishPass();
    });

    it("offers no new sync while prices are still being read", async () => {
      await syncList(detailExtension);
      mounted?.unmount();

      const wrapper = await mountModal(detailExtension);
      extensionReplies("identify", { handle: "ACaptain" });
      await flushPromises();

      expect(
        wrapper.find("[data-test='buyback-sync-details-running']").exists(),
      ).toBe(true);
      expect(
        wrapper.find("[data-test='start-buyback-sync']").attributes("disabled"),
      ).toBeDefined();

      extensionReplies("syncBuybackPricing", {
        currencyCode: "EUR",
        exchangeRate: 8800,
        taxRate: 1900,
        isTaxInclusive: true,
      });
      await flushPromises();
      extensionReplies("syncBuybackDetail", detailPage, { id: "1" });
      await flushPromises();

      expect(
        wrapper.find("[data-test='start-buyback-sync']").attributes("disabled"),
      ).toBeUndefined();
    });

    it("reads prices while a hangar sync runs", async () => {
      useHangarStore().syncRunning = true;

      await syncList(detailExtension);

      expect(mutateAsync).toHaveBeenCalled();
      expect(askedFor("syncBuybackPricing")).toBe(true);

      await finishPass();
    });

    it("shows no counts from an earlier pass for a sync that read no prices", async () => {
      await syncList(detailExtension);
      extensionReplies("syncBuybackPricing", {
        currencyCode: "EUR",
        exchangeRate: 8800,
        taxRate: 1900,
        isTaxInclusive: true,
      });
      await flushPromises();
      extensionReplies("syncBuybackDetail", detailPage, { id: "1" });
      await flushPromises();
      mounted?.unmount();

      const wrapper = await syncList(currentExtension);

      expect(wrapper.find("[data-test='buyback-sync-prices']").exists()).toBe(
        false,
      );
    });

    it("reads the prices of a list saved after the modal closed", async () => {
      let answerSubmit: (value: {
        total: number;
        added: number;
        removed: number;
        detailsPending: string[];
      }) => void = () => {};
      mutateAsync.mockImplementationOnce(
        () =>
          new Promise((resolve) => {
            answerSubmit = resolve;
          }),
      );

      const wrapper = await mountModal(detailExtension);
      extensionReplies("identify", { handle: "ACaptain" });
      await flushPromises();
      await wrapper.find("[data-test='start-buyback-sync']").trigger("click");
      await flushPromises();

      await answerNextPage(buybackPage("1"));
      await answerNextPage(emptyBuybackPage);

      wrapper.unmount();
      mounted = undefined;

      answerSubmit({ total: 1, added: 1, removed: 0, detailsPending: ["1"] });
      await flushPromises();

      expect(askedFor("syncBuybackPricing")).toBe(true);

      await finishPass();
    });

    it("syncs only the list with an extension that cannot read prices", async () => {
      const wrapper = await syncList(currentExtension);

      expect(askedFor("syncBuybackPricing")).toBe(false);
      expect(askedFor("syncBuybackDetail")).toBe(false);
      expect(submitDetails).not.toHaveBeenCalled();
      expect(
        wrapper.find("[data-test='buyback-sync-details-unsupported']").exists(),
      ).toBe(true);
    });
  });
});
