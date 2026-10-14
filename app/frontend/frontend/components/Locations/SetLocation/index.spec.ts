import { describe, it, expect, vi, beforeEach } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { ref } from "vue";
import type { Location } from "@/services/fyApi";
import Component from "./index.vue";

const { mutateAsync, emit, displayAlert, displaySuccess } = vi.hoisted(() => ({
  mutateAsync: vi.fn(),
  emit: vi.fn(),
  displayAlert: vi.fn(),
  displaySuccess: vi.fn(),
}));
vi.mock("@/services/fyApi", async (original) => ({
  ...(await original<Record<string, unknown>>()),
  useUpdateProfile: () => ({ mutateAsync, isPending: ref(false) }),
}));
vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));
vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert, displaySuccess }),
}));
vi.mock("@/shared/components/base/BtnDropdown/index.vue", () => ({
  default: { template: "<div><slot name='label'/><slot/></div>" },
}));
const location = {
  id: "lorville",
  name: "Lorville",
  slug: "lorville",
} as Location;
const mount = (authenticated = true) =>
  mountWithDefaults(Component, {
    props: { location },
    initialState: { session: { authenticated } },
  });
beforeEach(() => vi.clearAllMocks());

describe("Set location", () => {
  it("is unavailable to signed-out visitors", async () => {
    expect(
      (await mount(false)).find('[data-test="set-location"]').exists(),
    ).toBe(false);
  });
  it("updates only the user's in-game location", async () => {
    const wrapper = await mount();
    await wrapper.get('[data-test="set-my-location"]').trigger("click");
    await flushPromises();
    expect(mutateAsync).toHaveBeenCalledWith({
      data: { currentLocationId: "lorville", currentSystem: "Lorville" },
    });
    expect(emit).toHaveBeenCalledWith("user-update");
    expect(displaySuccess).toHaveBeenCalled();
  });
  it("opens the ship picker at the current location", async () => {
    const wrapper = await mount();
    await wrapper.get('[data-test="set-ship-location"]').trigger("click");
    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        props: { location },
      }),
    );
  });
  it("reports a failed update without confirming it", async () => {
    mutateAsync.mockRejectedValueOnce(new Error("failed"));
    const wrapper = await mount();
    await wrapper.get('[data-test="set-my-location"]').trigger("click");
    await flushPromises();
    expect(displayAlert).toHaveBeenCalled();
    expect(displaySuccess).not.toHaveBeenCalled();
    expect(emit).not.toHaveBeenCalled();
  });
});
