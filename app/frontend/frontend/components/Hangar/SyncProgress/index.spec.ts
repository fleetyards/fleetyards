import { mount } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref, type Ref } from "vue";
import { useHangarStore } from "@/frontend/stores/hangar";
import Component from "./index.vue";

const run = vi.hoisted(() => ({
  running: undefined as unknown as Ref<boolean>,
  fetching: undefined as unknown as Ref<boolean>,
  currentPage: undefined as unknown as Ref<number>,
  cancel: vi.fn(),
}));

vi.mock("@/frontend/composables/useHangarSync", () => ({
  useHangarSync: () => run,
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
    global: { plugins: [createTestingPinia()] },
  });

describe("HangarSyncProgress", () => {
  beforeEach(() => {
    run.running = ref(false);
    run.fetching = ref(false);
    run.currentPage = ref(1);
    run.cancel.mockClear();
    emit.mockClear();
  });

  it("shows nothing without a run", () => {
    const wrapper = mountProgress();

    expect(wrapper.find("[data-test='hangar-sync-progress']").exists()).toBe(
      false,
    );
  });

  it("stays out of the way while the modal shows the run", async () => {
    run.running.value = true;

    const wrapper = mountProgress();
    expect(wrapper.find("[data-test='hangar-sync-progress']").exists()).toBe(
      true,
    );

    useHangarStore().syncModalOpen = true;
    await wrapper.vm.$nextTick();

    expect(wrapper.find("[data-test='hangar-sync-progress']").exists()).toBe(
      false,
    );
  });

  it("shows the page being read, and can cancel the read", async () => {
    run.running.value = true;
    run.fetching.value = true;
    run.currentPage.value = 4;

    const wrapper = mountProgress();

    expect(wrapper.find("[data-test='hangar-sync-page']").text()).toContain(
      "4",
    );

    await wrapper.find("[data-test='cancel-hangar-sync']").trigger("click");
    expect(run.cancel).toHaveBeenCalled();
  });

  // Once submitted, the backend run goes on whatever this tab does.
  it("offers no cancel once the hangar is submitted", () => {
    run.running.value = true;

    const wrapper = mountProgress();

    expect(wrapper.find("[data-test='hangar-sync-page']").exists()).toBe(false);
    expect(wrapper.find("[data-test='cancel-hangar-sync']").exists()).toBe(
      false,
    );
  });

  it("opens the modal on the run", async () => {
    run.running.value = true;

    const wrapper = mountProgress();

    await wrapper.find("[data-test='open-hangar-sync']").trigger("click");
    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ component: expect.any(Function) }),
    );
  });
});
