import { describe, expect, it, vi } from "vitest";
import type { ModelModule } from "@/services/fyApi";
import { useFittingDiff } from "./useFittingDiff";

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

describe("useFittingDiff", () => {
  it("adds the fitted modules to the hull's figures", () => {
    const { metrics } = useFittingDiff();

    expect(Object.fromEntries(metrics(100, [cargo, torpedoes]))).toEqual({
      cargo: 132,
      torpedoes: 2,
    });
  });

  it("reads a swap as the compare tool reads two ships", () => {
    const { metrics, rows } = useFittingDiff();

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
    const { metrics, rows } = useFittingDiff();

    expect(rows(metrics(100, [cargo]), metrics(100, [cargo]))).toEqual([
      expect.objectContaining({ key: "cargo", deltaLabel: undefined }),
    ]);
  });
});
