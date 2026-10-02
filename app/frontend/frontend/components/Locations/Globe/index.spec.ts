import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

describe("LocationGlobe", () => {
  it("draws a coloured body with a turning surface under a fixed light", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        location: { kind: "planet", color: "#a0522d", bodyType: "gas_giant" },
      },
    });

    expect(wrapper.classes()).toContain("location-globe--gas_giant");
    expect(wrapper.attributes("style")).toContain("--globe-color: #a0522d");
    expect(wrapper.find(".location-globe__surface").exists()).toBe(true);
    expect(wrapper.find(".location-globe__shade").exists()).toBe(true);
  });

  it("lights the night side of a city planet", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        location: { kind: "planet", color: "#756961", bodyType: "city" },
      },
    });

    expect(wrapper.find(".location-globe__lights").exists()).toBe(true);
  });

  it("leaves a body without a colour to the caller's plain fill", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { location: { kind: "moon", color: null } },
    });

    expect(wrapper.classes()).toContain("location-globe--rocky");
    expect(wrapper.find(".location-globe__surface").exists()).toBe(false);
  });
});
