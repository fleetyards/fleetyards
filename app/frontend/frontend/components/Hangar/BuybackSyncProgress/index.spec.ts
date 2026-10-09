import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref, type Ref } from "vue";
import Component from "./index.vue";

const pass = vi.hoisted(() => ({
  status: undefined as unknown as Ref<string>,
  total: undefined as unknown as Ref<number>,
  done: undefined as unknown as Ref<number>,
  cancelling: undefined as unknown as Ref<boolean>,
  cancel: vi.fn(),
  discard: vi.fn(),
}));

vi.mock("@/frontend/composables/useBuybackDetailsSync", async () => {
  const { computed } = await import("vue");

  return {
    useBuybackDetailsSync: () => ({
      ...pass,
      running: computed(() => pass.status.value === "running"),
    }),
  };
});

const list = vi.hoisted(() => ({
  status: undefined as unknown as Ref<string>,
  currentPage: undefined as unknown as Ref<number>,
  cancel: vi.fn(),
  reset: vi.fn(),
}));

vi.mock("@/frontend/composables/useBuybackSync", () => ({
  useBuybackSync: () => list,
}));

const displaySuccess = vi.fn();
const displayWarning = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess, displayWarning }),
}));

const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const mountProgress = () =>
  mount(Component, {
    global: {
      plugins: [
        createTestingPinia({
          initialState: { session: { authenticated: true } },
        }),
      ],
    },
  });

const find = (wrapper: ReturnType<typeof mountProgress>, testId: string) =>
  wrapper.find(`[data-test='${testId}']`);

describe("HangarBuybackSyncProgress", () => {
  beforeEach(() => {
    pass.status = ref("idle");
    pass.total = ref(0);
    pass.done = ref(0);
    pass.cancelling = ref(false);
    pass.cancel.mockClear();
    pass.discard.mockClear();
    list.status = ref("idle");
    list.currentPage = ref(1);
    list.cancel.mockClear();
    list.reset.mockClear();
    emit.mockClear();
    displaySuccess.mockClear();
    displayWarning.mockClear();
  });

  it("shows nothing without a run", () => {
    const wrapper = mountProgress();

    expect(find(wrapper, "buyback-sync-progress-card").exists()).toBe(false);
  });

  it("shows the page of the list being read, and cancels the read", async () => {
    list.status.value = "fetching";
    list.currentPage.value = 3;

    const wrapper = mountProgress();

    expect(find(wrapper, "buyback-sync-stage").text()).toBe(
      "labels.buybackSync.status.fetching",
    );
    expect(find(wrapper, "buyback-sync-count").text()).toContain("3");

    await find(wrapper, "cancel-buyback-sync-progress").trigger("click");
    expect(list.cancel).toHaveBeenCalled();
    expect(pass.cancel).not.toHaveBeenCalled();
  });

  // Once submitted, the list is stored whatever this tab does.
  it("offers no cancel while the list is saved", () => {
    list.status.value = "submitting";

    const wrapper = mountProgress();

    expect(find(wrapper, "buyback-sync-stage").text()).toBe(
      "labels.buybackSync.status.submitting",
    );
    expect(find(wrapper, "cancel-buyback-sync-progress").exists()).toBe(false);
  });

  it("shows how far a running price pass has got, and cancels it", async () => {
    pass.status.value = "running";
    pass.total.value = 980;
    pass.done.value = 120;

    const wrapper = mountProgress();

    expect(find(wrapper, "buyback-sync-count").text()).toBe("120 / 980");

    await find(wrapper, "cancel-buyback-sync-progress").trigger("click");
    expect(pass.cancel).toHaveBeenCalled();
    expect(list.cancel).not.toHaveBeenCalled();
  });

  it("stays out of the way while the modal shows the run", async () => {
    list.status.value = "fetching";

    const wrapper = mountProgress();
    useHangarStore().buybackSyncModalOpen = true;
    await flushPromises();

    expect(find(wrapper, "buyback-sync-progress-card").exists()).toBe(false);
  });

  it("opens the modal on the run", async () => {
    list.status.value = "fetching";

    const wrapper = mountProgress();
    await find(wrapper, "open-buyback-sync-progress").trigger("click");

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ component: expect.any(Function) }),
    );
  });

  it("says when a pass has read every price", async () => {
    pass.status.value = "running";
    mountProgress();

    pass.status.value = "finished";
    await flushPromises();

    expect(displaySuccess).toHaveBeenCalledWith({
      text: "messages.buybackSync.detailsSuccess",
    });
  });

  it("warns when a pass stopped before reading every price", async () => {
    pass.status.value = "running";
    mountProgress();

    pass.status.value = "incomplete";
    await flushPromises();

    expect(displayWarning).toHaveBeenCalledWith({
      text: "texts.buybackSync.detailsIncomplete",
    });
  });

  // A cancelled pass goes back to idle; the user asked for it to stop.
  it("says nothing about a cancelled pass", async () => {
    pass.status.value = "running";
    mountProgress();

    pass.status.value = "idle";
    await flushPromises();

    expect(displaySuccess).not.toHaveBeenCalled();
    expect(displayWarning).not.toHaveBeenCalled();
  });

  it("goes away as soon as the pass is cancelled", async () => {
    pass.status.value = "running";

    const wrapper = mountProgress();
    pass.cancelling.value = true;
    await flushPromises();

    expect(find(wrapper, "buyback-sync-progress-card").exists()).toBe(false);
  });

  it("drops the list and the pass on sign-out", async () => {
    pass.status.value = "running";
    mountProgress();

    useSessionStore().authenticated = false;
    await flushPromises();

    expect(list.reset).toHaveBeenCalledWith(true);
    expect(pass.discard).toHaveBeenCalled();
  });
});
