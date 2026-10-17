import { describe, expect, it, vi } from "vitest";
import type { ModelModule } from "@/services/fyApi";
import { useLoadoutDiff, useModuleDiff } from "./useLoadoutDiff";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key.split(".").pop(),
    toNumber: (value: number) => `${value} SCU`,
  }),
}));

const cargo = {
  id: "cargo",
  metrics: { cargo: 32 },
  hardpoints: [],
} as unknown as ModelModule;

const torpedoes = {
  id: "torpedoes",
  hardpoints: [
    { category: "torpedoes" },
    { category: "torpedoes" },
    { category: "controller" },
  ],
} as unknown as ModelModule;

const medical = (tier: number, name: string, beds: number) =>
  ({
    id: `tier-${tier}`,
    metrics: {
      cargo: 0,
      medicalBeds: { tiers: [{ tier, name, beds }], respawnBeds: beds },
    },
    hardpoints: [],
  }) as unknown as ModelModule;

describe("useLoadoutDiff", () => {
  it("tells medical modules apart by their beds, tier by tier", () => {
    const { metrics, rows } = useModuleDiff();

    const byKey = Object.fromEntries(
      rows(
        metrics(0, [medical(1, "Hospital", 1)]),
        metrics(0, [medical(3, "Ambulance", 3)]),
      ).map((row) => [row.key, row]),
    );

    expect(byKey.medical_beds_tier_1).toMatchObject({
      before: 1,
      after: 0,
      delta: { tone: "even" },
    });
    expect(byKey.medical_beds_tier_3).toMatchObject({ before: 0, after: 3 });
    // More beds to respawn at is better.
    expect(byKey.respawn_beds).toMatchObject({
      before: 1,
      after: 3,
      delta: { tone: "better" },
    });
  });

  it("adds the fitted modules to the hull's figures", () => {
    const { metrics } = useLoadoutDiff();

    expect(Object.fromEntries(metrics(100, [cargo, torpedoes]))).toEqual({
      cargo: 132,
      torpedoes: 2,
    });
  });

  it("reads a swap as the compare tool reads two ships", () => {
    const { metrics, rows } = useModuleDiff();

    const [cargoRow, torpedoRow] = rows(
      metrics(100, [torpedoes]),
      metrics(100, [cargo]),
    );

    expect(cargoRow).toMatchObject({
      key: "cargo",
      before: 100,
      after: 132,
      value: "132 SCU",
      deltaLabel: "+32 SCU",
      delta: { tone: "better" },
    });
    // How many hardpoints of a kind is neither better nor worse.
    expect(torpedoRow).toMatchObject({
      key: "torpedoes",
      before: 2,
      after: 0,
      deltaLabel: "\u22122",
      delta: { tone: "even" },
    });
  });

  it("marks nothing for a swap that changes nothing", () => {
    const { metrics, rows } = useModuleDiff();

    expect(rows(metrics(100, [cargo]), metrics(100, [cargo]))).toEqual([
      expect.objectContaining({ key: "cargo", deltaLabel: undefined }),
    ]);
  });

  describe("a whole fitting", () => {
    const fittingWith = (modules: ModelModule[]) => ({
      hullCargo: 100,
      modules,
      hardpoints: [],
      tree: [],
    });

    it("sums up what moved, modules included, in one list", () => {
      const { measure, diff } = useLoadoutDiff();

      const figures = diff(
        measure(fittingWith([])),
        measure(fittingWith([cargo, torpedoes])),
        [],
      );

      expect(figures.modules.map((figure) => figure.key)).toEqual([
        "cargo",
        "torpedoes",
      ]);
      expect(figures.changed).toEqual([
        expect.objectContaining({ key: "cargo", deltaLabel: "+32 SCU" }),
        expect.objectContaining({ key: "torpedoes", deltaLabel: "+2" }),
      ]);
    });

    it("leaves the ship's cards empty until its hardpoints are known", () => {
      const { measure, diff } = useLoadoutDiff();

      const figures = diff(measure(fittingWith([])), measure(fittingWith([])), [
        { id: "shields", categories: [] },
      ]);

      expect(figures.cards.defense).toEqual([]);
      expect(figures.tabs.shields).toEqual([]);
      expect(figures.changed).toEqual([]);
    });
  });
});
