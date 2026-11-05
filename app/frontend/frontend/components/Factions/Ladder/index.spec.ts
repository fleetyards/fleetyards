import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type FactionLadder } from "@/services/fyApi";
import Component from "./index.vue";

const ladder = (attrs: Partial<FactionLadder> = {}): FactionLadder => ({
  key: "reputationscope_hauling",
  name: "Hauling",
  ranks: [
    { name: "Not Eligible", minReputation: -1000 },
    { name: "Trainee", minReputation: 0 },
    { name: "Rookie", minReputation: 50 },
    { name: "Member", minReputation: 5000 },
  ],
  missionCount: 3,
  minAward: 50,
  maxAward: 4000,
  ...attrs,
});

const mount = (attrs: Partial<FactionLadder> = {}) =>
  mountWithDefaults(Component, { props: { ladder: ladder(attrs) } });

describe("Factions/Ladder", () => {
  it("lists each rank with the points it starts at, zero included", async () => {
    const wrapper = await mount();

    const rows = wrapper
      .findAll(".faction-ladder__rank")
      .map((row) => row.text());

    expect(rows).toHaveLength(4);
    expect(rows[0]).toContain("Not Eligible");
    expect(rows[1]).toMatch(/Trainee\s*0$/);
  });

  it("sizes each bar by its real share of the top rank", async () => {
    const wrapper = await mount();

    const widths = wrapper
      .findAll(".faction-ladder__bar")
      .map((bar) => (bar.element as HTMLElement).style.width);

    expect(widths[0]).toMatch(/^0(px)?$/);
    expect(widths[1]).toMatch(/^0(px)?$/);
    expect(widths[2]).toBe("1%");
    expect(widths[3]).toBe("100%");
  });

  it("keeps a sliver for a rank far below the top, and none for a rank at zero", async () => {
    const wrapper = await mount({
      ranks: [
        { name: "Trainee", minReputation: 0 },
        { name: "Rookie", minReputation: 50 },
        { name: "Master", minReputation: 237750 },
      ],
    });

    const floors = wrapper
      .findAll(".faction-ladder__bar")
      .map((bar) => (bar.element as HTMLElement).style.minWidth);

    expect(floors).toEqual(["", "2px", "2px"]);
  });

  it("states one award where the range is one figure", async () => {
    const wrapper = await mount({ minAward: 50, maxAward: 50 });

    expect(wrapper.find("[data-test='faction-ladder-award']").text()).toBe(
      "+50",
    );
  });

  it("says when no mission pays in, rather than showing empty figures", async () => {
    const wrapper = await mount({
      missionCount: 0,
      minAward: undefined,
      maxAward: undefined,
    });

    expect(wrapper.find(".faction-ladder__stats").exists()).toBe(false);
    expect(wrapper.find(".faction-ladder__note").exists()).toBe(true);
  });
});
