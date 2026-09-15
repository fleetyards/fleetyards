import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

const mount = (
  props: {
    hero?: boolean;
    figures?: number;
    panels?: number;
    panelRows?: number;
  } = {},
) => mountWithDefaults<typeof Component>(Component, { props });

describe("DetailSkeleton", () => {
  it("opens on a cover with a title over it", async () => {
    const wrapper = await mount();

    expect(wrapper.find(".detail-skeleton__hero").exists()).toBe(true);
    expect(wrapper.find(".skeleton-bar--title").exists()).toBe(true);
  });

  // A tour and a payout ledger have no cover; a placeholder that reserves 260px
  // for one hands the page down by a hero it never draws.
  it("leaves the cover out for a page that has none", async () => {
    const wrapper = await mount({ hero: false });

    expect(wrapper.find(".detail-skeleton__hero").exists()).toBe(false);
  });

  it("reserves one tile per figure the page opens on", async () => {
    const wrapper = await mount({ figures: 3 });

    expect(wrapper.findAll(".metrics-card__tile")).toHaveLength(3);
  });

  // Zero is the default, and a strip with no tiles in it is still a bordered
  // box with a bottom margin.
  it("draws no figure strip when the page has no figures", async () => {
    const wrapper = await mount();

    expect(wrapper.find(".detail-skeleton__figures").exists()).toBe(false);
  });

  it("reserves a panel per section and a line per row", async () => {
    const wrapper = await mount({ panels: 2, panelRows: 4 });

    const bodies = wrapper.findAll(".detail-skeleton__panel-body");

    expect(bodies).toHaveLength(2);
    expect(bodies[0].findAll(".skeleton-bar")).toHaveLength(4);
  });

  it("keeps the placeholders out of the reading order", async () => {
    const wrapper = await mount();

    expect(
      wrapper.get('[data-test="detail-skeleton"]').attributes("aria-hidden"),
    ).toBe("true");
  });
});
