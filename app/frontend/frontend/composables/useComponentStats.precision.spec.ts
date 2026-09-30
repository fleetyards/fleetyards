import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import type { Component } from "@/services/fyApi";
import { useComponentStats } from "./useComponentStats";

const component = (
  category: string,
  typeData: Record<string, unknown>,
): Component =>
  ({
    id: "1",
    name: "Test Component",
    slug: "test-component",
    category,
    typeData,
  }) as unknown as Component;

const valueOf = (stats: { label: string; value: string }[], label: string) =>
  stats.find((stat) => stat.label === label)?.value;

// Through the real formatter, which rounds to one decimal: these figures sit
// below it.
describe("useComponentStats precision", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("shows a life-support unit's output to the hundredth", () => {
    const stats = useComponentStats(
      component("lifesupport", { lifeSupportGeneration: 0.05 }),
    ).value;

    expect(valueOf(stats, "Output")).toBe("0,05/s");
  });

  it("starts a power range at zero when the item can be cut off entirely", () => {
    const stats = useComponentStats(
      component("cooler", {
        coolingRate: 50,
        powerConsumption: 5,
        powerMinimumFraction: 0,
      }),
    ).value;

    expect(valueOf(stats, "Power Draw")).toBe("0 – 5 seg");
  });
});
