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
  ],
  missionCount: 3,
  minAward: 50,
  maxAward: 4000,
  ...attrs,
});

describe("Factions/Ladder", () => {
  it("lists each rank with the points it starts at", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { ladder: ladder() },
    });

    const rows = wrapper.findAll("tbody tr").map((row) => row.text());

    expect(rows).toHaveLength(3);
    expect(rows[0]).toContain("Not Eligible");
    expect(rows[0]).toMatch(/-1[,.\s]?000/);
    expect(rows[1]).toMatch(/Trainee\s*0$/);
    expect(rows[2]).toContain("Rookie");
  });

  it("says when no mission pays into the ladder rather than showing a blank", async () => {
    const paying = await mountWithDefaults(Component, {
      props: { ladder: ladder() },
    });
    const idle = await mountWithDefaults(Component, {
      props: {
        ladder: ladder({ missionCount: 0, minAward: null, maxAward: null }),
      },
    });

    const paid = paying.find(".faction-ladder__award").text();
    const none = idle.find(".faction-ladder__award").text();

    expect(paid).toContain("+50");
    expect(none).not.toContain("+");
    expect(none).not.toEqual(paid);
  });
});
