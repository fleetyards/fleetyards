import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import type { Component } from "@/services/fyApi";
import { useComponentStats } from "./useComponentStats";

const gun = (typeData: Record<string, unknown>): Component =>
  ({
    id: "1",
    name: "Test Gun",
    slug: "test-gun",
    category: "weapons",
    typeData,
  }) as unknown as Component;

const valueOf = (
  stats: { label: string; value: string }[],
  label: string,
): string | undefined => stats.find((stat) => stat.label === label)?.value;

// The thousands delimiter is the locale's, so a large total is compared on
// its digits alone.
const digitsOf = (value?: string) => value?.replace(/\D/g, "");

describe("useHardpointStats for guns", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("totals what one magazine delivers and how long it lasts", () => {
    const stats = useComponentStats(
      gun({
        fireRate: 50,
        maxAmmo: 270,
        ammoCost: 1,
        damagePerShot: { physical: 975 },
      }),
    ).value;

    expect(digitsOf(valueOf(stats, "Magazine Damage"))).toBe("263250");
    expect(valueOf(stats, "Time to Empty")).toBe("324 s");
  });

  it("counts every pellet and what each shot costs", () => {
    const stats = useComponentStats(
      gun({
        fireRate: 60,
        maxAmmo: 40,
        ammoCost: 2,
        pelletsPerShot: 8,
        damagePerShot: { physical: 10 },
      }),
    ).value;

    expect(digitsOf(valueOf(stats, "Magazine Damage"))).toBe("1600");
    expect(valueOf(stats, "Time to Empty")).toBe("20 s");
  });

  it("gives an energy weapon no magazine totals", () => {
    const stats = useComponentStats(
      gun({
        fireRate: 750,
        maxAmmo: 0,
        damagePerShot: { energy: 43.65 },
        regen: { maxAmmoLoad: 60 },
      }),
    ).value;

    expect(valueOf(stats, "Magazine Damage")).toBeUndefined();
    expect(valueOf(stats, "Time to Empty")).toBeUndefined();
  });

  it("shows a fixed spread as one figure, without its growth", () => {
    const stats = useComponentStats(
      gun({
        fireRate: 750,
        damagePerShot: { energy: 43.65 },
        spread: { min: 0.6, max: 0.6, attack: 0.022, decay: 2 },
      }),
    ).value;

    expect(valueOf(stats, "Spread")).toBe("0.6°");
    expect(valueOf(stats, "Spread/Shot")).toBeUndefined();
  });

  it("shows a spread that grows with each shot, to the hundredth", () => {
    const stats = useComponentStats(
      gun({
        fireRate: 1200,
        damagePerShot: { physical: 63.3 },
        spread: { min: 0.2, max: 1.5, attack: 0.025, decay: 0.05 },
      }),
    ).value;

    expect(valueOf(stats, "Spread")).toBe("0.2° / 1.5°");
    expect(valueOf(stats, "Spread/Shot")).toBe("0.025°");
    expect(valueOf(stats, "Spread Recovery")).toBe("0.05°/s");
  });
});
