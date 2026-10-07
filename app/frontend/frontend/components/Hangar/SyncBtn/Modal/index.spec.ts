import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useHangarStore } from "@/frontend/stores/hangar";
import { HangarSyncUnmatchedActionEnum } from "@/services/fyApi";
import Component from "./index.vue";

const mutateAsync = vi.fn(() => Promise.resolve());
const buybackMutateAsync = vi.fn(() => Promise.resolve());

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useSyncRsiHangar: () => ({ mutateAsync }),
  useSyncRsiHangarStatus: () => ({ data: ref(undefined) }),
  useSyncRsiBuybacks: () => ({ mutateAsync: buybackMutateAsync }),
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
const extensionReplies = (
  action: string,
  payload?: unknown,
  { code = 200, error }: { code?: number; error?: string } = {},
) => {
  window.dispatchEvent(
    new MessageEvent("message", {
      data: {
        direction: "fy-sync",
        message: JSON.stringify({ action, code, payload, error }),
      },
    }),
  );
};

const buybackPage = (id: string) => `
<ul class="pledges"><li><article class="pledge">
  <h1 title="Standalone Ship - Cutlass Black">Standalone Ship - Cutlass Black</h1>
  <a class="holosmallbtn" href="/pledge/buyback/${id}">Buy Back</a>
</article></li></ul>`;

const emptyPage = "<html><body></body></html>";

const askedFor = (action: string) =>
  vi
    .mocked(window.postMessage)
    .mock.calls.some(([data]) =>
      String((data as { message?: string })?.message).includes(
        `"action":"${action}"`,
      ),
    );

// The modal listens on `window` for as long as it is mounted, so one left
// behind would answer the next test's extension replies as well -- and submit a
// second sync carrying its own store's value.
let mounted: ReturnType<typeof mount> | undefined;

const mountModal = async () => {
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

  extensionReplies("identify", { handle: "ACaptain" });
  await flushPromises();

  return { wrapper, hangarStore };
};

// A page the parser finds no pledge list in ends the fetch loop, which is the
// shortest route from "start" to the request this spec is about.
const startSync = async (
  wrapper: Awaited<ReturnType<typeof mountModal>>["wrapper"],
) => {
  await wrapper.find("[data-test='start-sync']").trigger("click");
  await flushPromises();

  extensionReplies("sync", emptyPage);
  await flushPromises();
};

const submitEmptyHangar = async (
  wrapper: Awaited<ReturnType<typeof mountModal>>["wrapper"],
) => {
  await startSync(wrapper);

  extensionReplies("syncBuyback", emptyPage);
  await flushPromises();
};

describe("HangarSyncModal", () => {
  beforeEach(() => {
    mutateAsync.mockClear();
    buybackMutateAsync.mockClear();
    vi.mocked(window.postMessage).mockClear();
  });

  afterEach(() => {
    mounted?.unmount();
    mounted = undefined;
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

  describe("buy-back pledges", () => {
    it("reads every buy-back page before submitting the list", async () => {
      const { wrapper } = await mountModal();

      await startSync(wrapper);

      expect(askedFor("syncBuyback")).toBe(true);
      expect(mutateAsync).not.toHaveBeenCalled();

      extensionReplies("syncBuyback", buybackPage("1"));
      await flushPromises();
      extensionReplies("syncBuyback", buybackPage("2"));
      await flushPromises();

      expect(buybackMutateAsync).not.toHaveBeenCalled();

      extensionReplies("syncBuyback", emptyPage);
      await flushPromises();

      expect(buybackMutateAsync).toHaveBeenCalledWith({
        data: {
          items: [
            expect.objectContaining({ id: "1", kind: "ship" }),
            expect.objectContaining({ id: "2", kind: "ship" }),
          ],
        },
      });
      expect(mutateAsync).toHaveBeenCalled();
    });

    // The same guard the hangar loop has: a page repeating ids already read
    // would otherwise keep the loop asking forever.
    it("stops at a page with nothing new on it", async () => {
      const { wrapper } = await mountModal();

      await startSync(wrapper);

      extensionReplies("syncBuyback", buybackPage("1"));
      await flushPromises();
      extensionReplies("syncBuyback", buybackPage("1"));
      await flushPromises();

      expect(buybackMutateAsync).toHaveBeenCalledWith({
        data: { items: [expect.objectContaining({ id: "1" })] },
      });
    });

    it("still syncs the hangar with an extension that predates buy-backs", async () => {
      const { wrapper } = await mountModal();

      await startSync(wrapper);

      extensionReplies("syncBuyback", undefined, {
        code: 500,
        error: "Unknown Action",
      });
      await flushPromises();

      expect(buybackMutateAsync).not.toHaveBeenCalled();
      expect(mutateAsync).toHaveBeenCalled();
    });

    // The endpoint replaces the whole list, so half of one would drop every
    // buy-back on the pages that were never read.
    it("submits nothing when a page cannot be read", async () => {
      const { wrapper } = await mountModal();

      await startSync(wrapper);

      extensionReplies("syncBuyback", buybackPage("1"));
      await flushPromises();
      extensionReplies("syncBuyback", "", { code: 403 });
      await flushPromises();

      expect(buybackMutateAsync).not.toHaveBeenCalled();
      expect(mutateAsync).toHaveBeenCalled();
    });

    it("skips the buy-back list when the user opts out", async () => {
      const { wrapper, hangarStore } = await mountModal();

      expect(hangarStore.syncBuybacks).toBe(true);

      await wrapper.find("[data-test='toggle-syncBuybacks']").setValue(false);
      await flushPromises();

      expect(hangarStore.syncBuybacks).toBe(false);

      await startSync(wrapper);

      expect(askedFor("syncBuyback")).toBe(false);
      expect(mutateAsync).toHaveBeenCalled();
    });
  });
});
