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
  it("lists what a swap gains and loses, cargo first", () => {
    const { diff } = useFittingDiff();

    expect(diff([torpedoes], [cargo])).toEqual([
      { key: "cargo", delta: 32, label: "+32 SCU" },
      { key: "torpedoes", delta: -2, label: "−2 × torpedoes" },
    ]);
  });

  it("says what removing a module takes away", () => {
    const { diff } = useFittingDiff();

    expect(diff([cargo], []).map((change) => change.label)).toEqual([
      "−32 SCU",
    ]);
  });

  it("reports nothing for a swap that changes nothing", () => {
    const { diff } = useFittingDiff();

    expect(diff([cargo], [cargo])).toEqual([]);
  });
});
