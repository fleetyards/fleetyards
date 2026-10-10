import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useHangarStore } from "@/frontend/stores/hangar";
import type { HangarSyncData } from "@/services/fyCable/channels/HangarSyncChannel";
import {
  type HangarSyncStatus,
  HangarSyncOutcomeEnum,
  HangarSyncUnmatchedActionEnum,
  RsiPageCheckEnum,
  RsiPageKindEnum,
} from "@/services/fyApi";
import { useHangarSync } from "@/frontend/composables/useHangarSync";
import { rsiRateLimiter } from "@/frontend/lib/RsiRateLimiter";
import Component from "./index.vue";
import HangarSyncResult from "@/frontend/components/Hangar/SyncBtn/Result/index.vue";

const mutateAsync = vi.fn((_input: unknown) => Promise.resolve());

const reportMutateAsync = vi.fn((_input: unknown) => Promise.resolve());

// What the extension says about the RSI session when the modal checks it
// before reporting a page.
const rsiIdentity = vi.fn(
  async (): Promise<{ code: number; payload: { handle?: string } }> => ({
    code: 200,
    payload: { handle: "ACaptain" },
  }),
);

// Only the identify check: the pages come through the same composable, and
// their requests have to reach `postMessage`.
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
  syncRsiHangar: (data: unknown) => mutateAsync({ data }),
  reportRsiPage: (data: unknown) => reportMutateAsync({ data }),
}));

const comlinkEmit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: comlinkEmit, on: vi.fn(), off: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const displayInfo = vi.fn();

const displayWarning = vi.fn();

const displayAlert = vi.fn();

const displaySuccess = vi.fn();

const supportPromptCanShow = vi.fn(() => false);

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displayInfo,
    displaySuccess,
    displayWarning,
    displayAlert,
  }),
}));

vi.mock("@/shared/composables/useSupportPrompt", () => ({
  useSupportPrompt: () => ({ canShow: supportPromptCanShow }),
}));

vi.mock("vue-router", () => ({
  useRouter: () => ({ replace: vi.fn() }),
  useRoute: () => ({ query: {} }),
}));

// jsdom's `postMessage` insists on a targetOrigin the component does not pass,
// and nothing here reads what it would have posted.
vi.spyOn(window, "postMessage").mockImplementation(() => {});

// The extension answers `postMessage` out of band; in a test the reply is the
// event the component listens for, dispatched by hand.
const extensionReplies = (action: string, payload?: unknown) => {
  window.dispatchEvent(
    new MessageEvent("message", {
      // What the extension's content script posts from: the page's own window.
      source: window,
      data: {
        direction: "fy-sync",
        message: JSON.stringify({ action, code: 200, payload }),
      },
    }),
  );
};

// The modal listens on `window` for as long as it is mounted, so one left
// behind would answer the next test's extension replies as well -- and submit a
// second sync carrying its own store's value.
let mounted: ReturnType<typeof mount> | undefined;

const mountModal = async (
  identity: { handle?: string } = { handle: "ACaptain" },
) => {
  rsiIdentity.mockResolvedValueOnce({ code: 200, payload: identity });

  const wrapper = mount(Component, {
    global: {
      plugins: [createTestingPinia({ stubActions: false })],
      stubs: {
        Modal: {
          template:
            "<div><slot name='header-actions' /><slot /><slot name='footer' /></div>",
        },
        HangarGroupsSelect: true,
        // Mounts a `useQuery` of its own, which needs a QueryClient this spec
        // has no reason to stand up: every assertion below drives the store.
        BaseSelect: true,
        SyncResultPanel: true,
      },
      directives: { Tooltip: {} },
    },
  });

  mounted = wrapper;

  const hangarStore = useHangarStore();
  hangarStore.extensionReady = true;
  await flushPromises();

  return { wrapper, hangarStore };
};

const hangarPage = (items: string) =>
  `<title>My Hangar</title><ul class="list-items"><li><input type="hidden" class="js-pledge-id" value="101"><input type="hidden" class="js-pledge-name" value="Package - Cutter Starter Pack">${items}</li></ul>`;

// The modal waits half a second before it asks for the next page.
const replyWithPage = async (items: string) => {
  vi.useFakeTimers({ toFake: ["setTimeout", "clearTimeout"] });

  try {
    const sent = vi.mocked(window.postMessage).mock.calls.length;

    extensionReplies("sync", hangarPage(items));
    await flushPromises();

    vi.advanceTimersByTime(500);
    await flushPromises();

    expect(vi.mocked(window.postMessage).mock.calls.length).toBeGreaterThan(
      sent,
    );

    extensionReplies(
      "sync",
      '<title>My Hangar</title><div class="list-items"><div class="empty-list"></div></div>',
    );
    await flushPromises();
  } finally {
    vi.useRealTimers();
  }
};

// One page with a ship, then RSI's empty list: the shortest route from
// "start" to the request this spec is about.
const submitHangar = async (
  wrapper: Awaited<ReturnType<typeof mountModal>>["wrapper"],
) => {
  await wrapper.find("[data-test='start-sync']").trigger("click");
  await flushPromises();

  await replyWithPage(
    '<div class="item"><div class="title">Cutter</div><div class="kind">Ship</div></div>',
  );
};

// What the app-wide cable subscription hands on to the run.
const receiveSyncResult = (outcome: HangarSyncOutcomeEnum) =>
  useHangarSync().receive({
    status: "finished",
    result: {
      importedVehicles: [],
      foundVehicles: [],
      movedVehiclesToWanted: [],
      deletedVehicles: [],
      groupedVehicles: [],
      unchangedVehicles: [],
      missingModels: [],
      importedComponents: [],
      foundComponents: [],
      missingComponents: [],
      missingComponentVehicles: [],
      importedUpgrades: [],
      foundUpgrades: [],
      missingUpgrades: [],
      missingUpgradeVehicles: [],
      outcome,
    },
  } as HangarSyncData);

describe("HangarSyncModal", () => {
  beforeEach(() => {
    rsiRateLimiter.reset();
    mutateAsync.mockClear();
    displayInfo.mockClear();
    displayWarning.mockClear();
    displayAlert.mockClear();
    displaySuccess.mockClear();
    comlinkEmit.mockClear();
    supportPromptCanShow.mockReset().mockReturnValue(false);
    reportMutateAsync.mockClear();
    // A queued answer a test never used would answer the next test's check.
    rsiIdentity.mockReset().mockResolvedValue({
      code: 200,
      payload: { handle: "ACaptain" },
    });
  });

  // An error or login page in the middle of the run, read as the end, would
  // submit a partial hangar and leave every later ship unmatched.
  it("submits nothing and reports a page it does not recognise", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    extensionReplies(
      "sync",
      "<html><body><form id='sign-in'></form></body></html>",
    );
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
    expect(reportMutateAsync).toHaveBeenCalledWith({
      data: {
        page: RsiPageKindEnum.HANGAR,
        check: RsiPageCheckEnum.MISSING_LIST,
        pageNumber: 1,
        extensionVersion: undefined,
        details: ['page title ""'],
      },
    });
  });

  it("ignores a late reply once a page was not recognised", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    extensionReplies(
      "sync",
      "<html><body><form id='sign-in'></form></body></html>",
    );
    await flushPromises();
    extensionReplies(
      "sync",
      '<title>My Hangar</title><div class="list-items"><div class="empty-list"></div></div>',
    );
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
  });

  // The modal is usually closed by then, so nothing else would say it.
  it("warns when the RSI session runs out mid-read", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();
    wrapper.unmount();
    mounted = undefined;
    displayWarning.mockClear();
    rsiIdentity.mockResolvedValueOnce({ code: 400, payload: {} });

    extensionReplies(
      "sync",
      "<html><body><form id='sign-in'></form></body></html>",
    );
    await flushPromises();

    expect(useHangarSync().finishedWithErrors.value).toBe(true);
    expect(displayWarning).toHaveBeenCalledWith({
      text: "messages.syncExtension.notLoggedIn",
    });
  });

  // An expired RSI session answers with the sign-in page: nothing about RSI's
  // markup changed, so nobody is told it did.
  it("warns once and disables Start when the session runs out", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();
    displayWarning.mockClear();
    rsiIdentity.mockResolvedValue({ code: 400, payload: {} });

    try {
      extensionReplies(
        "sync",
        "<html><body><form id='sign-in'></form></body></html>",
      );
      await flushPromises();

      expect(displayWarning).toHaveBeenCalledTimes(1);
      expect(
        wrapper.find("[data-test='start-sync']").attributes("disabled"),
      ).toBeDefined();
    } finally {
      rsiIdentity.mockResolvedValue({
        code: 200,
        payload: { handle: "ACaptain" },
      });
    }
  });

  it("asks RSI for no session check while a read is going", async () => {
    const first = await mountModal();

    await first.wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();
    first.wrapper.unmount();
    rsiIdentity.mockClear();

    await mountModal();

    expect(rsiIdentity).not.toHaveBeenCalled();
  });

  it("reports nothing when the RSI session has run out", async () => {
    const { wrapper } = await mountModal();
    rsiIdentity.mockResolvedValueOnce({ code: 400, payload: {} });

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    extensionReplies(
      "sync",
      "<html><body><form id='sign-in'></form></body></html>",
    );
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
    expect(reportMutateAsync).not.toHaveBeenCalled();
    // On open, before the report, and once the read has failed so Start knows
    // the session is gone.
    expect(rsiIdentity).toHaveBeenCalledTimes(3);
  });

  // The run outlives the modal, so one left over would greet the next test
  // instead of the start screen.
  afterEach(() => {
    mounted?.unmount();
    mounted = undefined;
    useHangarSync().reset(true);
  });

  it("shows which RSI account the extension is signed in to", async () => {
    const { wrapper } = await mountModal();

    expect(
      wrapper.find("[data-test='sync-extension-signed-in-as']").exists(),
    ).toBe(true);
  });

  it("names no account without an RSI session", async () => {
    const { wrapper } = await mountModal({});

    expect(
      wrapper.find("[data-test='sync-extension-signed-in-as']").exists(),
    ).toBe(false);
  });

  it("adds bundled snub crafts by default", async () => {
    const { wrapper, hangarStore } = await mountModal();

    expect(hangarStore.syncAddBundledVehicles).toBe(true);

    await submitHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({ addBundledVehicles: true }),
    });
  });

  it("moves what it does not find to the wishlist by default", async () => {
    const { wrapper, hangarStore } = await mountModal();

    expect(hangarStore.syncUnmatchedVehiclesAction).toBe(
      HangarSyncUnmatchedActionEnum.WISHLIST,
    );

    await submitHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({
        unmatchedVehiclesAction: HangarSyncUnmatchedActionEnum.WISHLIST,
        unmatchedHangarGroupId: undefined,
      }),
    });
  });

  it("passes the chosen action on to the sync", async () => {
    const { wrapper, hangarStore } = await mountModal();

    hangarStore.syncUnmatchedVehiclesAction =
      HangarSyncUnmatchedActionEnum.DELETE;
    await flushPromises();

    await submitHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({
        unmatchedVehiclesAction: HangarSyncUnmatchedActionEnum.DELETE,
      }),
    });
  });

  it("sends the group only when that is the action", async () => {
    const { wrapper, hangarStore } = await mountModal();

    // Left over from an earlier run that did pick `group`. Sending it under an
    // action that ignores it would file ships nobody asked to file.
    hangarStore.syncUnmatchedHangarGroupId = "group-1";
    hangarStore.syncUnmatchedVehiclesAction =
      HangarSyncUnmatchedActionEnum.KEEP;
    await flushPromises();

    await submitHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({ unmatchedHangarGroupId: undefined }),
    });
  });

  it("asks for a group before it will sync into one", async () => {
    const { wrapper, hangarStore } = await mountModal();

    hangarStore.syncUnmatchedVehiclesAction =
      HangarSyncUnmatchedActionEnum.GROUP;
    await flushPromises();

    expect(
      wrapper.find("[data-test='start-sync']").attributes("disabled"),
    ).toBeDefined();

    // The group is chosen in the settings, which the start screen points to.
    expect(
      wrapper.find("[data-test='sync-missing-unmatched-group']").exists(),
    ).toBe(true);
    await wrapper.find("[data-test='open-sync-settings']").trigger("click");
    expect(wrapper.find("[data-test='sync-settings']").exists()).toBe(true);

    hangarStore.syncUnmatchedHangarGroupId = "group-1";
    await flushPromises();
    await wrapper.find("[data-test='close-sync-settings']").trigger("click");

    expect(
      wrapper.find("[data-test='start-sync']").attributes("disabled"),
    ).toBeUndefined();

    await submitHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({
        unmatchedVehiclesAction: HangarSyncUnmatchedActionEnum.GROUP,
        unmatchedHangarGroupId: "group-1",
      }),
    });
  });

  it("says on the start screen when paints or hangar flair are left out", async () => {
    const { wrapper, hangarStore } = await mountModal();

    expect(wrapper.find("[data-test='sync-skipped-items']").exists()).toBe(
      false,
    );

    const skippedItems = () =>
      wrapper
        .findAll("[data-test='sync-skipped-items'] li")
        .map((item) => item.text());

    hangarStore.syncPaints = false;
    await flushPromises();
    expect(skippedItems()).toEqual(["labels.syncExtension.pledgeItems.paints"]);

    hangarStore.syncHangarFlair = false;
    await flushPromises();
    expect(skippedItems()).toEqual([
      "labels.syncExtension.pledgeItems.paints",
      "labels.syncExtension.pledgeItems.hangarFlair",
    ]);

    hangarStore.syncPaints = true;
    await flushPromises();
    expect(skippedItems()).toEqual([
      "labels.syncExtension.pledgeItems.hangarFlair",
    ]);

    await wrapper.find("[data-test='open-sync-settings']").trigger("click");
    expect(wrapper.find("[data-test='sync-settings']").exists()).toBe(true);
  });

  it("passes the opt-out on to the sync", async () => {
    const { wrapper, hangarStore } = await mountModal();

    await wrapper.find("[data-test='toggle-sync-settings']").trigger("click");

    await wrapper
      .find("[data-test='toggle-syncAddBundledVehicles']")
      .setValue(false);
    await flushPromises();

    // Held in the store rather than in the modal, so the next sync opens with
    // the choice the user made on this one.
    expect(hangarStore.syncAddBundledVehicles).toBe(false);

    await wrapper.find("[data-test='close-sync-settings']").trigger("click");
    await submitHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({ addBundledVehicles: false }),
    });
  });

  it("opens the settings with the cog and leaves them from the footer", async () => {
    const { wrapper } = await mountModal();

    const has = (testId: string) =>
      wrapper.find(`[data-test='${testId}']`).exists();

    expect(has("sync-settings")).toBe(false);

    await wrapper.find("[data-test='toggle-sync-settings']").trigger("click");
    expect(has("sync-settings")).toBe(true);
    expect(has("toggle-syncPaints")).toBe(true);
    expect(has("toggle-sync-settings")).toBe(false);
    expect(has("start-sync")).toBe(false);

    await wrapper.find("[data-test='close-sync-settings']").trigger("click");
    expect(has("sync-settings")).toBe(false);
    expect(has("toggle-sync-settings")).toBe(true);
    expect(has("start-sync")).toBe(true);
  });

  it("offers to continue in the background once the hangar is submitted", async () => {
    const { wrapper } = await mountModal();

    expect(wrapper.find("[data-test='cancel-sync']").text()).toBe(
      "actions.syncExtension.cancel",
    );

    await submitHangar(wrapper);

    expect(wrapper.find("[data-test='cancel-sync']").exists()).toBe(false);
    expect(wrapper.find("[data-test='start-sync']").exists()).toBe(false);
    expect(wrapper.find("[data-test='recheck-sync']").exists()).toBe(false);
    expect(wrapper.find("[data-test='background-sync']").exists()).toBe(true);
  });

  // Reopened while an earlier run is still on the server: that result belongs
  // to the cable listener.
  it("leaves a run it did not submit to the cable listener", async () => {
    await mountModal();

    expect(receiveSyncResult(HangarSyncOutcomeEnum.SYNCED)).toBe(false);
    await flushPromises();

    expect(comlinkEmit).not.toHaveBeenCalledWith("hangar-sync-finished");
  });

  it("alerts when a submit fails after the modal closed", async () => {
    let rejectSubmit: (error: Error) => void = () => {};
    mutateAsync.mockImplementationOnce(
      () =>
        new Promise((_, reject) => {
          rejectSubmit = reject;
        }),
    );

    const { wrapper } = await mountModal();
    await submitHangar(wrapper);

    wrapper.unmount();
    mounted = undefined;

    rejectSubmit(new Error("offline"));
    await flushPromises();

    expect(displayAlert).toHaveBeenCalledWith({
      text: "messages.syncExtension.failure",
    });
  });

  it("offers a retry for a run the server failed", async () => {
    const { wrapper } = await mountModal();

    await submitHangar(wrapper);

    useHangarSync().receive({
      status: "failed",
      error: "boom",
    } as HangarSyncData);
    await flushPromises();

    expect(wrapper.find("[data-test='start-sync']").text()).toBe(
      "actions.syncExtension.retry",
    );
    expect(wrapper.find("[data-test='cancel-sync']").text()).toBe(
      "actions.syncExtension.close",
    );
  });

  it("offers Refresh, not Back, when the extension goes away in the settings", async () => {
    const { wrapper, hangarStore } = await mountModal();

    await wrapper.find("[data-test='toggle-sync-settings']").trigger("click");
    hangarStore.extensionReady = false;
    await flushPromises();

    expect(wrapper.find("[data-test='close-sync-settings']").exists()).toBe(
      false,
    );
    expect(wrapper.find("[data-test='recheck-sync']").exists()).toBe(true);
  });

  it("passes the paint and flair choices on to the sync", async () => {
    const { wrapper, hangarStore } = await mountModal();

    hangarStore.syncPaints = false;
    await flushPromises();

    await submitHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({
        syncPaints: false,
        syncHangarFlair: true,
      }),
    });
  });

  it("submits a hangar whose ship upgrade has no kind", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    await replyWithPage(
      '<div class="item"><div class="title">Cutter</div><div class="kind">Ship</div></div><div class="item"><div class="title">Upgrade - Clipper To S-65 Stingray</div></div>',
    );

    expect(reportMutateAsync).not.toHaveBeenCalled();
    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({
        items: [expect.objectContaining({ name: "Cutter", type: "ship" })],
      }),
    });
  });

  it("submits the rest of a page holding a ship that lost its kind, and says which page", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    await replyWithPage(
      '<div class="item"><div class="title">Cutter</div><div class="kind">Ship</div></div><div class="item"><div class="title">Cutlass Black</div><div class="liner">Drake Interplanetary (<span>DRAK</span>)</div></div>',
    );

    expect(reportMutateAsync).not.toHaveBeenCalled();
    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({
        items: [expect.objectContaining({ name: "Cutter", type: "ship" })],
        unreadPages: [
          expect.objectContaining({
            check: RsiPageCheckEnum.MISSING_KINDS,
            pageNumber: 1,
            markup: [expect.stringContaining("Cutlass Black")],
          }),
        ],
      }),
    });
  });

  it("keeps what a repeated page could not read, though its pledges were seen", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    vi.useFakeTimers({ toFake: ["setTimeout", "clearTimeout"] });
    try {
      extensionReplies(
        "sync",
        hangarPage(
          '<div class="item"><div class="title">Cutter</div><div class="kind">Ship</div></div>',
        ),
      );
      await flushPromises();
      vi.advanceTimersByTime(500);
      await flushPromises();

      extensionReplies(
        "sync",
        hangarPage(
          '<div class="item"><div class="title">Cutter</div><div class="kind">Ship</div></div><div class="item"><div class="title">Cutlass Black</div><div class="liner">Drake Interplanetary (<span>DRAK</span>)</div></div>',
        ),
      );
      await flushPromises();
    } finally {
      vi.useRealTimers();
    }

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({
        unreadPages: [
          expect.objectContaining({
            check: RsiPageCheckEnum.MISSING_KINDS,
            pageNumber: 2,
          }),
        ],
      }),
    });
  });

  it("submits a hangar with nothing to sync and says what the run found", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    await replyWithPage(
      '<div class="item"><div class="title">Upgrade - Clipper To S-65 Stingray</div></div>',
    );

    expect(reportMutateAsync).not.toHaveBeenCalled();
    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({ items: [] }),
    });

    receiveSyncResult(HangarSyncOutcomeEnum.NOTHING_TO_SYNC);
    receiveSyncResult(HangarSyncOutcomeEnum.NOTHING_TO_SYNC);
    await flushPromises();

    expect(displayInfo).toHaveBeenCalledTimes(2);
    expect(displayInfo).toHaveBeenLastCalledWith({
      text: "messages.syncExtension.nothingToSync",
    });
    expect(wrapper.find("[data-test='close-sync']").exists()).toBe(true);
  });

  it("submits paints and flair that are turned off, and says the run skipped them", async () => {
    supportPromptCanShow.mockReturnValue(true);
    const { wrapper, hangarStore } = await mountModal();

    hangarStore.syncPaints = false;
    hangarStore.syncHangarFlair = false;
    await flushPromises();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    await replyWithPage(
      '<div class="item"><div class="title">Cutter Paint</div><div class="kind">Skin</div></div><div class="item"><div class="title">Poster</div><div class="kind">Hangar decoration</div></div>',
    );

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({
        items: [
          expect.objectContaining({ type: "skin" }),
          expect.objectContaining({ type: "flair" }),
        ],
      }),
    });

    receiveSyncResult(HangarSyncOutcomeEnum.ONLY_SKIPPED_ITEMS);
    await flushPromises();

    expect(displayInfo).toHaveBeenCalledWith({
      text: "messages.syncExtension.onlySkippedItems",
    });
    expect(
      wrapper.findComponent(HangarSyncResult).props("showSupportHint"),
    ).toBe(false);
    expect(wrapper.find("[data-test='close-sync']").exists()).toBe(true);
  });

  it("asks for support after a run that synced", async () => {
    supportPromptCanShow.mockReturnValue(true);
    const { wrapper } = await mountModal();

    await submitHangar(wrapper);
    receiveSyncResult(HangarSyncOutcomeEnum.SYNCED);
    await flushPromises();

    expect(
      wrapper.findComponent(HangarSyncResult).props("showSupportHint"),
    ).toBe(true);
  });

  it("keeps reading the hangar once the modal is closed", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    await wrapper.find("[data-test='background-sync']").trigger("click");
    wrapper.unmount();
    mounted = undefined;

    await replyWithPage(
      '<div class="item"><div class="title">Cutter</div><div class="kind">Ship</div></div>',
    );

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({
        items: [expect.objectContaining({ name: "Cutter", type: "ship" })],
      }),
    });
    // Left out without a version from the extension, and without a page it
    // read only in part.
    expect(mutateAsync.mock.calls[0][0]).not.toHaveProperty(
      "data.extensionVersion",
    );
    expect(mutateAsync.mock.calls[0][0]).not.toHaveProperty("data.unreadPages");
    expect(useHangarSync().awaitingResult.value).toBe(true);

    const reopened = await mountModal();
    expect(reopened.wrapper.find("[data-test='recheck-sync']").exists()).toBe(
      false,
    );
    expect(reopened.wrapper.find("[data-test='start-sync']").exists()).toBe(
      false,
    );
    reopened.wrapper.unmount();

    receiveSyncResult(HangarSyncOutcomeEnum.SYNCED);
    await flushPromises();

    expect(useHangarSync().running.value).toBe(false);
  });

  it("opens on a run that is still going", async () => {
    const first = await mountModal();

    await first.wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();
    first.wrapper.unmount();

    const { wrapper } = await mountModal();

    expect(wrapper.findComponent(HangarSyncResult).exists()).toBe(true);
    expect(wrapper.find("[data-test='background-sync']").exists()).toBe(true);
  });

  it("opens on the start screen once the run is over", async () => {
    const first = await mountModal();

    await submitHangar(first.wrapper);
    receiveSyncResult(HangarSyncOutcomeEnum.SYNCED);
    await flushPromises();
    first.wrapper.unmount();

    const { wrapper } = await mountModal();

    expect(wrapper.findComponent(HangarSyncResult).exists()).toBe(false);
    expect(
      wrapper.find("[data-test='start-sync']").attributes("disabled"),
    ).toBeUndefined();
  });

  it("stops reading RSI when cancelled from the modal", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    await wrapper.find("[data-test='cancel-sync']").trigger("click");
    expect(useHangarSync().started.value).toBe(false);

    extensionReplies(
      "sync",
      '<title>My Hangar</title><div class="list-items"><div class="empty-list"></div></div>',
    );
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
  });

  it("shows the result of a run that ended in the background", async () => {
    const first = await mountModal();

    await submitHangar(first.wrapper);
    first.wrapper.unmount();

    receiveSyncResult(HangarSyncOutcomeEnum.SYNCED);
    await flushPromises();

    const { wrapper } = await mountModal();

    expect(wrapper.findComponent(HangarSyncResult).props("result")).toEqual(
      expect.objectContaining({ outcome: HangarSyncOutcomeEnum.SYNCED }),
    );
    expect(wrapper.find("[data-test='close-sync']").exists()).toBe(true);
  });

  it("says so when the backend fails a run in the background", async () => {
    const first = await mountModal();

    await submitHangar(first.wrapper);
    first.wrapper.unmount();

    useHangarSync().receive({ status: "failed" } as HangarSyncData);
    await flushPromises();

    expect(displayAlert).toHaveBeenCalledWith({
      text: "messages.syncExtension.failure",
    });

    // And can still be retried.
    const { wrapper } = await mountModal();
    await wrapper.find("[data-test='start-sync']").trigger("click");
    expect(mutateAsync).toHaveBeenCalledTimes(2);
  });

  // The poll is the fallback for a cable message delayed across a reconnect;
  // when it still arrives, it is the same run and is not told twice.
  it("tells a run once when the poll answers before the cable", async () => {
    const { wrapper } = await mountModal();

    await submitHangar(wrapper);

    useHangarSync().receiveStatus({
      active: false,
      status: "finished",
      result: { outcome: HangarSyncOutcomeEnum.NOTHING_TO_SYNC },
    } as HangarSyncStatus);
    expect(
      useHangarSync().receive({ status: "finished" } as HangarSyncData),
    ).toBe(true);

    expect(displaySuccess).not.toHaveBeenCalled();
    expect(displayInfo).toHaveBeenLastCalledWith({
      text: "messages.syncExtension.nothingToSync",
    });
  });

  it("ends a run the backend reports finished without a result", async () => {
    const { wrapper } = await mountModal();

    await submitHangar(wrapper);

    useHangarSync().receiveStatus({
      active: false,
      status: "finished",
    } as HangarSyncStatus);

    expect(useHangarSync().running.value).toBe(false);
    expect(useHangarSync().polling.value).toBe(false);
    expect(displaySuccess).toHaveBeenCalledTimes(1);
  });

  it("tells a sync from another tab once the late answer is overdue", async () => {
    const { wrapper } = await mountModal();

    await submitHangar(wrapper);

    const now = Date.now();
    const clock = vi.spyOn(Date, "now").mockReturnValue(now);

    try {
      useHangarSync().receiveStatus({
        active: false,
        status: "finished",
        result: { outcome: HangarSyncOutcomeEnum.SYNCED },
      } as HangarSyncStatus);

      clock.mockReturnValue(now + 61_000);

      expect(
        useHangarSync().receive({ status: "finished" } as HangarSyncData),
      ).toBe(false);
    } finally {
      clock.mockRestore();
    }
  });

  it("can start again after a run it reopened on fails", async () => {
    const first = await mountModal();

    await first.wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();
    first.wrapper.unmount();

    const { wrapper } = await mountModal();

    extensionReplies(
      "sync",
      "<html><body><form id='sign-in'></form></body></html>",
    );
    await flushPromises();

    expect(
      wrapper.find("[data-test='start-sync']").attributes("disabled"),
    ).toBeUndefined();
  });
});
