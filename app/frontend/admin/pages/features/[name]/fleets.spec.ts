import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { QueryClient, VueQueryPlugin } from "@tanstack/vue-query";
import type { Feature } from "@/services/fyAdminApi";

const api = vi.hoisted(() => ({
  enableAdminFeatureActor: vi.fn(),
  disableAdminFeatureActor: vi.fn(),
}));

vi.mock("@/services/fyAdminApi", () => ({
  ...api,
  getAdminFeaturesQueryKey: () => ["features"],
}));

const notifications = vi.hoisted(() => ({
  displaySuccess: vi.fn(),
  displayAlert: vi.fn(),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => notifications,
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

import FleetsTab from "./fleets.vue";

const feature: Feature = {
  name: "fleet_tours",
  state: "conditional",
  permanent: false,
  selfServiceUser: false,
  selfServiceFleet: true,
  percentageOfActors: 0,
  percentageOfTime: 0,
  groups: [],
  actors: [{ type: "Fleet", id: "id-1", name: "Test", fid: "Test100" }],
  fullyOnSince: null,
  lastChangedAt: null,
  lastChangedBy: null,
  lastChangedSource: null,
};

const mountTab = () => {
  const queryClient = new QueryClient();
  const invalidate = vi.spyOn(queryClient, "invalidateQueries");

  const wrapper = mount(FleetsTab, {
    props: { feature },
    global: {
      plugins: [[VueQueryPlugin, { queryClient }]],
      stubs: {
        FleetSelect: {
          name: "FleetSelect",
          props: ["modelValue"],
          emits: ["update:modelValue"],
          template: "<div />",
        },
        Btn: {
          props: ["disabled"],
          emits: ["click"],
          template:
            "<button :disabled='disabled' @click=\"$emit('click')\"><slot /></button>",
        },
      },
    },
  });

  const pick = async (fid: string) => {
    wrapper
      .findComponent({ name: "FleetSelect" })
      .vm.$emit("update:modelValue", fid);
    await flushPromises();
  };

  const addButton = () => wrapper.find('[data-test="feature-add-fleet"]');

  return { wrapper, pick, addButton, invalidate };
};

describe("the feature's Fleets tab", () => {
  beforeEach(() => {
    api.enableAdminFeatureActor.mockReset().mockResolvedValue({});
    notifications.displaySuccess.mockReset();
    notifications.displayAlert.mockReset();
  });

  it("adds the picked fleet by its SID, refreshes and clears the picker", async () => {
    const { wrapper, pick, addButton, invalidate } = mountTab();

    await pick("NEWFLEET");
    await addButton().trigger("click");
    await flushPromises();

    expect(api.enableAdminFeatureActor).toHaveBeenCalledWith("fleet_tours", {
      actor_type: "Fleet",
      actor_id: "NEWFLEET",
    });
    expect(invalidate).toHaveBeenCalledWith({ queryKey: ["features"] });
    expect(notifications.displaySuccess).toHaveBeenCalled();
    expect(
      wrapper.findComponent({ name: "FleetSelect" }).props("modelValue"),
    ).toBeUndefined();
  });

  it("will not add a fleet that already has the feature", async () => {
    const { wrapper, pick, addButton } = mountTab();

    await pick("Test100");

    expect(addButton().attributes("disabled")).toBeDefined();
    expect(
      wrapper.find('[data-test="feature-fleet-already-enabled"]').exists(),
    ).toBe(true);
  });

  it("keeps the pick and says so when the add fails", async () => {
    api.enableAdminFeatureActor.mockRejectedValue(new Error("nope"));
    const { wrapper, pick, addButton } = mountTab();

    await pick("NEWFLEET");
    await addButton().trigger("click");
    await flushPromises();

    expect(notifications.displayAlert).toHaveBeenCalledWith({
      text: "messages.features.error",
    });
    expect(
      wrapper.findComponent({ name: "FleetSelect" }).props("modelValue"),
    ).toBe("NEWFLEET");
  });
});
