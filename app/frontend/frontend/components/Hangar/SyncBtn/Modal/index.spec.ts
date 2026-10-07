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

vi.mock("@/frontend/composables/useSyncExtension", () => ({
  useSyncExtension: () => ({ request: rsiIdentity, supports: vi.fn() }),
}));

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

const mountModal = async (identity: unknown = { handle: "ACaptain" }) => {
  const wrapper = mount(Component, {
    global: {
      plugins: [createTestingPinia({ stubActions: false })],
      stubs: {
        Modal: { template: "<div><slot /><slot name='footer' /></div>" },
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

  extensionReplies("identify", identity);
  await flushPromises();

  return { wrapper, hangarStore };
};

// RSI's empty list ends the fetch loop, which is the shortest route from
// "start" to the request this spec is about.
const submitEmptyHangar = async (
  wrapper: Awaited<ReturnType<typeof mountModal>>["wrapper"],
) => {
  await wrapper.find("[data-test='start-sync']").trigger("click");
  await flushPromises();

  extensionReplies(
    "sync",
    '<title>My Hangar</title><div class="list-items"><div class="empty-list"></div></div>',
  );
  await flushPromises();
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
    rsiIdentity.mockResolvedValueOnce({ code: 400, payload: {} });
    const { wrapper } = await mountModal();

    await wrapper.find("[data-test='start-sync']").trigger("click");
    await flushPromises();

    extensionReplies(
      "sync",
      "<html><body><form id='sign-in'></form></body></html>",
    );
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
    expect(reportMutateAsync).not.toHaveBeenCalled();
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

    await submitEmptyHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({ addBundledVehicles: true }),
    });
  });

  it("moves what it does not find to the wishlist by default", async () => {
    const { wrapper, hangarStore } = await mountModal();

    expect(hangarStore.syncUnmatchedVehiclesAction).toBe(
      HangarSyncUnmatchedActionEnum.WISHLIST,
    );

    await submitEmptyHangar(wrapper);

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

    await submitEmptyHangar(wrapper);

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

    await submitEmptyHangar(wrapper);

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

    hangarStore.syncUnmatchedHangarGroupId = "group-1";
    await flushPromises();

    expect(
      wrapper.find("[data-test='start-sync']").attributes("disabled"),
    ).toBeUndefined();

    await submitEmptyHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({
        unmatchedVehiclesAction: HangarSyncUnmatchedActionEnum.GROUP,
        unmatchedHangarGroupId: "group-1",
      }),
    });
  });

  it("passes the opt-out on to the sync", async () => {
    const { wrapper, hangarStore } = await mountModal();

    await wrapper
      .find("[data-test='toggle-syncAddBundledVehicles']")
      .setValue(false);
    await flushPromises();

    // Held in the store rather than in the modal, so the next sync opens with
    // the choice the user made on this one.
    expect(hangarStore.syncAddBundledVehicles).toBe(false);

    await submitEmptyHangar(wrapper);

    expect(mutateAsync).toHaveBeenCalledWith({
      data: expect.objectContaining({ addBundledVehicles: false }),
    });
  });
});
