import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { HangarShare } from "@/services/fyApi";
import Component from "./index.vue";

const share = ref<HangarShare | undefined>();

const createShare = vi.fn();
const rotateShare = vi.fn();
const destroyShare = vi.fn();
const refetch = vi.fn();
const loading = ref(false);

const mutation = (mutateAsync: ReturnType<typeof vi.fn>) => ({
  mutateAsync,
  isPending: ref(false),
});

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useMyHangarShare: () => ({ data: share, refetch, isPending: loading }),
    useCreateMyHangarShare: () => mutation(createShare),
    useRotateMyHangarShare: () => mutation(rotateShare),
    useDestroyMyHangarShare: () => mutation(destroyShare),
  };
});

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
    displayConfirm: ({ onConfirm }: { onConfirm: () => void }) => onConfirm(),
  }),
}));

const shareUrl = "https://fltyrd.net/h/data?share=secret";

describe("HangarShareLink", () => {
  beforeEach(() => {
    createShare.mockReset().mockResolvedValue(undefined);
    rotateShare.mockReset().mockResolvedValue(undefined);
    destroyShare.mockReset().mockResolvedValue(undefined);
    refetch.mockReset();
  });

  it("offers to create a link while there is none", async () => {
    share.value = { enabled: false, shareUrl: null };
    const wrapper = await mountWithDefaults(Component);

    expect(wrapper.find('[data-test="hangar-share-url"]').exists()).toBe(false);

    await wrapper.find('[data-test="hangar-share-enable"]').trigger("click");
    await flushPromises();

    expect(createShare).toHaveBeenCalled();
    expect(refetch).toHaveBeenCalled();
  });

  it("shows the link once there is one", async () => {
    share.value = { enabled: true, shareUrl };
    const wrapper = await mountWithDefaults(Component);

    expect(
      (
        wrapper.find('[data-test="hangar-share-url"] input')
          .element as HTMLInputElement
      ).value,
    ).toBe(shareUrl);
    expect(wrapper.find('[data-test="hangar-share-enable"]').exists()).toBe(
      false,
    );
  });

  it("offers nothing to create while it is still loading", async () => {
    share.value = undefined;
    loading.value = true;
    const wrapper = await mountWithDefaults(Component);

    expect(wrapper.find('[data-test="hangar-share-enable"]').exists()).toBe(
      false,
    );

    loading.value = false;
  });

  it("rotates and deletes the link after confirmation", async () => {
    share.value = { enabled: true, shareUrl };
    const wrapper = await mountWithDefaults(Component);

    await wrapper.find('[data-test="hangar-share-rotate"]').trigger("click");
    await flushPromises();
    expect(rotateShare).toHaveBeenCalled();

    await wrapper.find('[data-test="hangar-share-disable"]').trigger("click");
    await flushPromises();
    expect(destroyShare).toHaveBeenCalled();
  });
});
