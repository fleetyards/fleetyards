import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import type { ComponentDurability } from "@/services/fyApi";
import { useComponentDurability } from "./useComponentDurability";

const torrent: ComponentDurability = {
  health: 410,
  mass: 630,
  resistances: {
    physical: 0.85,
    energy: 0.85,
    distortion: 1,
    thermal: 0.1,
    biochemical: 1,
    stun: 1,
  },
  selfRepair: { time: 56, healthRatio: 0.2, maxRepairs: 1 },
  distortion: {
    maximum: 3500,
    warningRatio: 0.75,
    recoveryRatio: 0,
    decayRate: 233.3333,
    decayDelay: 3,
  },
};

const rows = (durability: ComponentDurability | null) =>
  Object.fromEntries(
    useComponentDurability(durability).value.map((group) => [
      group.key,
      // The formatter groups thousands with a non-breaking space.
      group.stats.map((stat) =>
        `${stat.label}: ${stat.value}`.replace(/\s/g, " "),
      ),
    ]),
  );

describe("useComponentDurability", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("groups a quantum drive's figures the way the game files describe them", () => {
    expect(rows(torrent)).toEqual({
      physical: ["Health: 410 HP", "Mass: 630 kg"],
      damageTaken: ["Physical: 85%", "Energy: 85%", "Thermal: 10%"],
      selfRepair: ["Repair time: 56 s", "Repairs to: 20%", "Max repairs: 1"],
      distortion: [
        "Disabled at: 3 500",
        "Warning at: 2 625",
        "Decay rate: 233/s",
        "Decay delay: 3 s",
      ],
    });
  });

  it("names the recovery threshold only when there is one", () => {
    const groups = rows({
      distortion: { maximum: 1000, recoveryRatio: 0.5 },
    });

    expect(groups.distortion).toContain("Recovers below: 500");
  });

  it("leaves out every block a component does not have", () => {
    expect(rows({ health: 100 })).toEqual({ physical: ["Health: 100 HP"] });
    expect(rows({ resistances: { physical: 1, energy: 1 } })).toEqual({});
    expect(rows(null)).toEqual({});
  });
});
