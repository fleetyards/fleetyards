import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import type { FleetSquadron } from "@/services/fyApi";

import Component from "./index.vue";

const file = (url: string) => ({ url, smallUrl: url }) as never;

const squadron = (attributes: Partial<FleetSquadron> = {}): FleetSquadron =>
  ({
    id: "1",
    name: "Combat Wing",
    slug: "combat-wing",
    ...attributes,
  }) as FleetSquadron;

const mountWith = (record: FleetSquadron, size?: number) =>
  mount(Component, { props: { squadron: record, ...(size ? { size } : {}) } });

describe("SquadronEmblem", () => {
  it("draws the icon when there is one", () => {
    const wrapper = mountWith(squadron({ icon: file("/icon.png") }));

    expect(wrapper.find("img").attributes("src")).toBe("/icon.png");
  });

  // At emblem size a wide lockup letterboxes down to almost nothing, so the
  // square mark wins wherever both exist.
  it("prefers the icon over the logo", () => {
    const wrapper = mountWith(
      squadron({ icon: file("/icon.png"), logo: file("/logo.png") }),
    );

    expect(wrapper.find("img").attributes("src")).toBe("/icon.png");
  });

  it("falls back to the logo when there is no icon", () => {
    const wrapper = mountWith(squadron({ logo: file("/logo.png") }));

    expect(wrapper.find("img").attributes("src")).toBe("/logo.png");
  });

  it("falls back to initials from up to two words", () => {
    expect(mountWith(squadron()).text()).toBe("CW");
    expect(mountWith(squadron({ name: "Reserves" })).text()).toBe("R");
    expect(
      mountWith(squadron({ name: "Search and Rescue Detachment" })).text(),
    ).toBe("SA");
  });

  /*
   * A squadron colour comes off the full wheel, so a fixed foreground is
   * unreadable on about half of it. Black on gold, white on navy.
   */
  it("picks a foreground the colour can carry", () => {
    const light = mountWith(squadron({ color: "#d4af37" }));
    const dark = mountWith(squadron({ color: "#1b2838" }));

    expect(light.attributes("style")).toContain("rgb(0, 0, 0)");
    expect(dark.attributes("style")).toContain("rgb(255, 255, 255)");
  });

  it("outlines rather than fills when nobody chose a colour", () => {
    const wrapper = mountWith(squadron());

    expect(wrapper.classes()).toContain("squadron-emblem--plain");
    expect(wrapper.attributes("style")).not.toContain("background-color");
  });

  // A logo never gets a coloured tile behind it: most emblems are transparent
  // PNGs and a tile turns one into a sticker on a square.
  it("never paints a tile behind a mark", () => {
    const wrapper = mountWith(
      squadron({ icon: file("/icon.png"), color: "#dc3545" }),
    );

    expect(wrapper.attributes("style")).not.toContain("background-color");
  });
});
