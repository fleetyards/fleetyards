import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import ExampleShip from "./index.vue";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

describe("HangarTourExampleShip", () => {
  it("provides title and menu targets without working ship actions", () => {
    const wrapper = mount(ExampleShip);

    expect(wrapper.get('[data-tour="vehicle-overview"]').text()).toBe(
      "texts.hangarTour.exampleShip.title",
    );
    expect(
      wrapper.get('[data-tour="vehicle-menu"] button').attributes(),
    ).toHaveProperty("disabled");
    expect(wrapper.find("a").exists()).toBe(false);
    expect(wrapper.text()).toContain("texts.hangarTour.exampleShip.text");
    wrapper.unmount();
  });
});
