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

  // The low end is the block the power allocator keeps powered, sized its
  // way: whole segments, and one segment when the item names no share.
  it("starts a power range at the allocator's own critical block", () => {
    const power = (powerMinimumFraction: number) =>
      valueOf(
        useComponentStats(
          component("cooler", {
            coolingRate: 50,
            powerConsumption: 5,
            powerMinimumFraction,
          }),
        ).value,
        "Power Draw",
      );

    expect(power(0.33)).toBe("2 – 5 seg");
    expect(power(0)).toBe("1 – 5 seg");
  });

  it("shows a shield's regen delays to the hundredth", () => {
    const stats = useComponentStats(
      component("shieldgenerator", {
        maxHealth: 5000,
        maxRegen: 500,
        damagedRegenDelay: 4.55,
        downedRegenDelay: 9.09,
      }),
    ).value;

    expect(valueOf(stats, "Damaged Delay")).toBe("4,55 s");
  });
});
