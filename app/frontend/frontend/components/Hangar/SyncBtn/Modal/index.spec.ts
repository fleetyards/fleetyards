import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useHangarStore } from "@/frontend/stores/hangar";
import Component from "./index.vue";

const mutateAsync = vi.fn(() => Promise.resolve());

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useSyncRsiHangar: () => ({ mutateAsync }),
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

const mountModal = async () => {
  const wrapper = mount(Component, {
    global: {
      plugins: [createTestingPinia({ stubActions: false })],
      stubs: {
        Modal: { template: "<div><slot /><slot name='footer' /></div>" },
        HangarGroupsSelect: true,
        SyncResultPanel: true,
        SmallLoader: true,
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
const submitEmptyHangar = async (
  wrapper: Awaited<ReturnType<typeof mountModal>>["wrapper"],
) => {
  await wrapper.find("[data-test='start-sync']").trigger("click");
  await flushPromises();

  extensionReplies("sync", "<html><body></body></html>");
  await flushPromises();
};

describe("HangarSyncModal", () => {
  beforeEach(() => {
    mutateAsync.mockClear();
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
