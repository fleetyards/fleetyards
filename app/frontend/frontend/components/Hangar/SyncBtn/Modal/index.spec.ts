import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useHangarStore } from "@/frontend/stores/hangar";
import {
  HangarSyncUnmatchedActionEnum,
  RsiPageCheckEnum,
  RsiPageKindEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

const mutateAsync = vi.fn(() => Promise.resolve());

const reportMutateAsync = vi.fn(() => Promise.resolve());

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
  useSyncRsiHangar: () => ({ mutateAsync }),
  useReportRsiPage: () => ({ mutateAsync: reportMutateAsync }),
  useSyncRsiHangarStatus: () => ({ data: ref(undefined) }),
}));

vi.mock("@/shared/composables/useSubscription", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useSubscription: () => ({}),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displayInfo: vi.fn(),
    displaySuccess: vi.fn(),
    displayWarning: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

vi.mock("@/shared/composables/useSupportPrompt", () => ({
  useSupportPrompt: () => ({ canShow: () => false }),
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

describe("HangarSyncModal", () => {
  beforeEach(() => {
    mutateAsync.mockClear();
    reportMutateAsync.mockClear();
    rsiIdentity.mockClear();
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

  // An expired RSI session answers with the sign-in page: nothing about RSI's
  // markup changed, so nobody is told it did.
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
    expect(rsiIdentity).toHaveBeenCalledTimes(2);
  });

  afterEach(() => {
    mounted?.unmount();
    mounted = undefined;
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

    await submitHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({ addBundledVehicles: false }),
    });
  });

  it("switches to the settings and back with the cog", async () => {
    const { wrapper } = await mountModal();

    expect(wrapper.find("[data-test='sync-settings']").exists()).toBe(false);

    await wrapper.find("[data-test='toggle-sync-settings']").trigger("click");
    expect(wrapper.find("[data-test='sync-settings']").exists()).toBe(true);
    expect(wrapper.find("[data-test='toggle-syncPaints']").exists()).toBe(true);

    await wrapper.find("[data-test='toggle-sync-settings']").trigger("click");
    expect(wrapper.find("[data-test='sync-settings']").exists()).toBe(false);
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

  it("reports a ship that lost its kind, and submits nothing", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    extensionReplies(
      "sync",
      hangarPage(
        '<div class="item"><div class="title">Cutter</div><div class="kind">Ship</div></div><div class="item"><div class="title">Cutlass Black</div><div class="liner">Drake Interplanetary (<span>DRAK</span>)</div></div>',
      ),
    );
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
    expect(reportMutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({ check: RsiPageCheckEnum.MISSING_KINDS }),
    });
  });

  it("submits nothing when the hangar holds nothing to sync", async () => {
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    await replyWithPage(
      '<div class="item"><div class="title">Upgrade - Clipper To S-65 Stingray</div></div>',
    );

    expect(mutateAsync).not.toHaveBeenCalled();
    expect(reportMutateAsync).not.toHaveBeenCalled();
    expect(wrapper.find("[data-test='close-sync']").exists()).toBe(true);
  });
});
