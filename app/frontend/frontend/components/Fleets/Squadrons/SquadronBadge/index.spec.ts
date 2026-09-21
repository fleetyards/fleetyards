import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import type { FleetSquadronRef } from "@/services/fyApi";

import Component from "./index.vue";

const RouterLinkStub = {
  props: ["to"],
  template: '<a class="router-link-stub"><slot /></a>',
};

const squadron = (
  attributes: Partial<FleetSquadronRef> = {},
): FleetSquadronRef => ({
  id: "1",
  name: "Combat Wing",
  slug: "combat-wing",
  color: null,
  ...attributes,
});

const mountWith = (props: {
  squadron: FleetSquadronRef;
  to?: Record<string, unknown>;
}) =>
  mount(Component, {
    props,
    global: { stubs: { "router-link": RouterLinkStub } },
  });

describe("SquadronBadge", () => {
  it("names the squadron", () => {
    expect(mountWith({ squadron: squadron() }).text()).toContain("Combat Wing");
  });

  it("paints the dot in the squadron's colour", () => {
    const wrapper = mountWith({ squadron: squadron({ color: "#ff8800" }) });

    expect(wrapper.find(".squadron-badge-dot").attributes("style")).toContain(
      "rgb(255, 136, 0)",
    );
  });

  // A squadron nobody chose a colour for gets the quiet grey a glyph takes,
  // not a coloured swatch that would claim somebody did.
  it("falls back to the muted token when there is no colour", () => {
    const wrapper = mountWith({ squadron: squadron() });

    expect(wrapper.find(".squadron-badge-dot").attributes("style")).toContain(
      "var(--color-muted)",
    );
  });

  it("renders a plain span when it links nowhere", () => {
    const wrapper = mountWith({ squadron: squadron() });

    expect(wrapper.find(".router-link-stub").exists()).toBe(false);
    expect(wrapper.element.tagName).toBe("SPAN");
  });

  it("renders a link when given a destination", () => {
    const wrapper = mountWith({
      squadron: squadron(),
      to: { name: "fleet-squadron" },
    });

    expect(wrapper.find(".router-link-stub").exists()).toBe(true);
  });
});
