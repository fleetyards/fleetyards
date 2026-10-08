import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { useSessionStore } from "@/frontend/stores/session";
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

const displaySuccess = vi.fn();
const displayWarning = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess, displayWarning }),
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

describe("HangarBuybackDetailsSyncProgress", () => {
  beforeEach(() => {
    pass.status = ref("idle");
    pass.total = ref(0);
    pass.done = ref(0);
    pass.cancelling = ref(false);
    pass.cancel.mockClear();
    pass.discard.mockClear();
    displaySuccess.mockClear();
    displayWarning.mockClear();
  });

  it("shows nothing without a pass running", () => {
    const wrapper = mountProgress();

    expect(
      wrapper.find("[data-test='buyback-details-sync-progress']").exists(),
    ).toBe(false);
  });

  it("shows how far a running pass has got", () => {
    pass.status.value = "running";
    pass.total.value = 980;
    pass.done.value = 120;

    const wrapper = mountProgress();

    expect(
      wrapper.find("[data-test='buyback-details-sync-count']").text(),
    ).toBe("120 / 980");
  });

  it("cancels the pass", async () => {
    pass.status.value = "running";

    const wrapper = mountProgress();
    await wrapper
      .find("[data-test='cancel-buyback-details-sync']")
      .trigger("click");

    expect(pass.cancel).toHaveBeenCalled();
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

    expect(
      wrapper.find("[data-test='buyback-details-sync-progress']").exists(),
    ).toBe(false);
  });

  it("drops the pass on sign-out", async () => {
    pass.status.value = "running";
    mountProgress();

    useSessionStore().authenticated = false;
    await flushPromises();

    expect(pass.discard).toHaveBeenCalled();
  });
});
