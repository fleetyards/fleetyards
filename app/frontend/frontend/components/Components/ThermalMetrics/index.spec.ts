import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Component as FyComponent } from "@/services/fyApi";
import Component from "./index.vue";

const component = (attrs: Partial<FyComponent> = {}) =>
  ({
    id: "id",
    name: "A Part",
    slug: "a-part",
    hidden: false,
    retired: false,
    catalogued: true,
    availability: { boughtAt: [], soldAt: [] },
    media: {},
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as FyComponent;

const mount = (attrs: Partial<FyComponent>) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { component: component(attrs) },
  });

describe("ComponentThermalMetrics", () => {
  it("shows a temperature card and a misfire card when both are known", async () => {
    const wrapper = await mount({
      temperature: { overheatTemperature: 383 },
      misfire: { heat: 0.8 },
    });

    expect(
      wrapper.find('[data-test="component-temperature"]').text(),
    ).toContain("383 K");
    expect(wrapper.find('[data-test="component-misfire"]').text()).toContain(
      "80%",
    );
  });

  it("renders nothing for a component with neither", async () => {
    const wrapper = await mount({});

    expect(wrapper.find('[data-test="component-temperature"]').exists()).toBe(
      false,
    );
    expect(wrapper.find('[data-test="component-misfire"]').exists()).toBe(
      false,
    );
  });
});
