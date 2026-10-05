import { describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { VueQueryPlugin } from "@tanstack/vue-query";
import type { Feature } from "@/services/fyAdminApi";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key, l: (value: string) => value }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

import Overview from "./overview.vue";
import Users from "./users.vue";
import Fleets from "./fleets.vue";
import History from "./history.vue";

const feature: Feature = {
  name: "fleet_tours",
  state: "conditional",
  permanent: false,
  selfServiceUser: false,
  selfServiceFleet: true,
  percentageOfActors: 0,
  percentageOfTime: 0,
  groups: [],
  actors: [],
  fullyOnSince: null,
  lastChangedAt: null,
  lastChangedBy: null,
  lastChangedSource: null,
};

// The panel frame has no padding of its own; PanelBody carries it. Content
// placed straight in a Panel sat flush against its edges.
describe.each([
  ["overview", Overview],
  ["users", Users],
  ["fleets", Fleets],
  ["history", History],
])("the %s tab", (_name, page) => {
  it("puts every panel's content inside a padded body", () => {
    const wrapper = mount(page, {
      props: { feature },
      global: {
        plugins: [VueQueryPlugin],
        stubs: {
          UserSelect: true,
          FleetActorSearch: true,
          FeatureHistory: true,
        },
      },
    });

    const panels = wrapper.findAll(".panel");
    expect(panels.length).toBeGreaterThan(0);

    for (const panel of panels) {
      const content = panel.element.querySelectorAll(
        ":scope > :not(.panel-heading):not(.panel-body)",
      );
      expect(content).toHaveLength(0);
      expect(panel.find(".panel-body").exists()).toBe(true);
    }
  });
});
