import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

describe("DuotoneGlyph", () => {
  it("draws on the square grid by default", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { glyph: { secondary: "<rect/>", primary: "<rect/>" } },
    });

    expect(wrapper.attributes("viewBox")).toBe("0 0 512 512");
    expect(wrapper.attributes("style")).toContain("width: 1em");
  });

  it("widens to 1.25em on Font Awesome's wide grid", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        glyph: { width: 640, secondary: "<rect/>", primary: "<rect/>" },
      },
    });

    expect(wrapper.attributes("viewBox")).toBe("0 0 640 512");
    expect(wrapper.attributes("style")).toContain("width: 1.25em");
  });
});
