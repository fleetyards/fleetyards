import { describe, it, expect, vi, beforeEach } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { ref } from "vue";
import type { Location } from "@/services/fyApi";
import Component from "./index.vue";

const {
  mutateAsync,
  emit,
  invalidateHangarQueries,
  invalidateVehiclePage,
  displayAlert,
} = vi.hoisted(() => ({
  mutateAsync: vi.fn(),
  emit: vi.fn(),
  invalidateHangarQueries: vi.fn(),
  invalidateVehiclePage: vi.fn(),
  displayAlert: vi.fn(),
}));
vi.mock("@/services/fyApi", async (original) => ({
  ...(await original<Record<string, unknown>>()),
  useUpdateVehicle: () => ({ mutateAsync, isPending: ref(false) }),
}));
vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    invalidateHangarQueries,
    invalidateVehiclePage,
  }),
}));
vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));
vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert, displaySuccess: vi.fn() }),
}));
vi.mock("@/shared/components/base/Select/index.vue", () => ({
  default: {
    name: "ShipSelect",
    props: ["modelValue"],
    emits: ["update:modelValue"],
    template: "<div />",
  },
}));
const mount = () =>
  mountWithDefaults(Component, {
    props: { location: { id: "lorville", name: "Lorville" } as Location },
  });
beforeEach(() => vi.clearAllMocks());

describe("Set ship location", () => {
  it("requires a ship before saving", async () => {
    const wrapper = await mount();
    expect(
      wrapper.get('[data-test="save-ship-location"]').attributes("disabled"),
    ).toBeDefined();
  });
  it("updates the selected ship and refreshes both ship and hangar", async () => {
    const saved = { id: "ship" };
    mutateAsync.mockResolvedValueOnce(saved);
    const wrapper = await mount();
    wrapper
      .findComponent({ name: "ShipSelect" })
      .vm.$emit("update:modelValue", "ship");
    await flushPromises();
    await wrapper.get('[data-test="save-ship-location"]').trigger("click");
    await flushPromises();
    expect(mutateAsync).toHaveBeenCalledWith({
      id: "ship",
      data: { locationId: "lorville", location: "Lorville" },
    });
    expect(invalidateVehiclePage).toHaveBeenCalledWith(saved);
    expect(invalidateHangarQueries).toHaveBeenCalled();
    expect(emit).toHaveBeenCalledWith("close-modal");
  });
});
