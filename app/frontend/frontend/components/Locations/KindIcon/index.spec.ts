import { describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { LocationKindEnum } from "@/services/fyApi";
import { GLYPHS } from "./glyphs";
import Component from "./index.vue";

describe("LocationKindIcon", () => {
  it("draws a glyph for every kind", () => {
    expect(Object.keys(GLYPHS).sort()).toEqual(
      Object.values(LocationKindEnum).sort(),
    );
  });

  it("draws the secondary layer under the primary one", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { kind: LocationKindEnum.STAR },
    });

    const layers = wrapper.findAll("g").map((layer) => layer.classes()[0]);

    expect(layers).toEqual([
      "location-kind-icon__secondary",
      "location-kind-icon__primary",
    ]);
    expect(wrapper.attributes("aria-hidden")).toBe("true");
  });

  // Two planets on one page must not share a mask, or the second draws the
  // first one's ring.
  it("scopes its masks to the rendered icon", async () => {
    const TwoPlanets = defineComponent({
      render: () =>
        h("div", [
          h(Component, { kind: LocationKindEnum.PLANET }),
          h(Component, { kind: LocationKindEnum.PLANET }),
        ]),
    });

    const wrapper = await mountWithDefaults(TwoPlanets);

    const ids = wrapper.findAll("mask").map((mask) => mask.attributes("id"));

    expect(ids).toHaveLength(4);
    expect(new Set(ids).size).toBe(4);
    expect(wrapper.html()).not.toContain("{id}");
  });
});
