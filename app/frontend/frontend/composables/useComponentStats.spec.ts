import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { HardpointCategoryEnum, type Component } from "@/services/fyApi";
import { hardpointCategoryFor, useComponentStats } from "./useComponentStats";

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

const labels = (stats: { label: string; value: string }[]) =>
  stats.map((stat) => stat.label);

describe("hardpointCategoryFor", () => {
  // A component only ever says `thrusters`; the slot vocabulary splits them
  // four ways by where they sit on the hull. Unmapped, a thruster matches no
  // branch and renders nothing at all.
  it("maps thrusters onto one of the four slot categories", () => {
    expect(hardpointCategoryFor("thrusters")).toBe(
      HardpointCategoryEnum.MAIN_THRUSTERS,
    );
  });

  it("passes through a category both vocabularies share", () => {
    expect(hardpointCategoryFor("shieldgenerator")).toBe(
      HardpointCategoryEnum.SHIELDGENERATOR,
    );
  });

  it("returns nothing for a category the slot list does not know", () => {
    expect(hardpointCategoryFor("not_a_category")).toBeUndefined();
    expect(hardpointCategoryFor(undefined)).toBeUndefined();
  });
});

describe("useComponentStats", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("renders a category's own figures without a ship anywhere", () => {
    const stats = useComponentStats(
      component("cooler", { coolingRate: 50 }),
    ).value;

    expect(labels(stats)).toContain("Cooling Rate");
  });

  // The three ship-level values `useHardpointStats` injects are optional, so
  // the figures that need them drop out rather than throwing.
  it("still renders a quantum drive with no ship fuel tank to read", () => {
    const stats = useComponentStats(
      component("quantumdrive", { driveSpeed: 1000 }),
    ).value;

    expect(stats.length).toBeGreaterThan(0);
  });

  it("renders a thruster, which needs the category mapping", () => {
    const stats = useComponentStats(
      component("thrusters", { thrustCapacity: 1000, thrusterClass: "main" }),
    ).value;

    expect(stats.length).toBeGreaterThan(0);
  });

  // Carried by every powered item and rendered by no category branch, so a
  // page without this block would drop it entirely.
  it("appends the power and signature block", () => {
    const stats = useComponentStats(
      component("cooler", {
        coolingRate: 50,
        powerConsumption: 120,
        signatureEm: 250,
        signatureIr: 2330,
        powerMinimumFraction: 0.4,
      }),
    ).value;

    expect(labels(stats)).toEqual(
      expect.arrayContaining([
        "Power Draw",
        "EM Signature",
        "IR Signature",
        "Idle Draw",
      ]),
    );
    expect(stats.find((stat) => stat.label === "Idle Draw")?.value).toBe("40%");
  });

  it("renders a utility component's capacity", () => {
    const stats = useComponentStats(
      component("utility", { capacity: 32 }),
    ).value;

    expect(labels(stats)).toContain("Capacity");
  });

  // The export stores these as strings, so a type check alone would skip them.
  it("renders a self destruct unit, whose figures arrive as strings", () => {
    const stats = useComponentStats(
      component("selfdestruct", { damage: "15000", radius: "80", time: "45" }),
    ).value;

    expect(labels(stats)).toEqual(
      expect.arrayContaining(["Damage", "Blast Radius", "Fuse Time"]),
    );
  });

  it("renders a quantum enforcement device from its nested settings", () => {
    const stats = useComponentStats(
      component("quantumenforcementdevice", {
        jammerSettings: { jammerRange: 8000 },
        quantumInterdictionPulseSettings: {
          radiusMeters: 20000,
          chargeTimeSecs: 10,
          cooldownTimeSecs: 60,
        },
      }),
    ).value;

    expect(labels(stats)).toEqual(
      expect.arrayContaining([
        "Jammer Range",
        "Pulse Radius",
        "Charge Time",
        "Cooldown",
      ]),
    );
  });

  it("is empty for a component carrying no metrics at all", () => {
    expect(useComponentStats(component("turret", {})).value).toEqual([]);
    expect(useComponentStats(undefined).value).toEqual([]);
  });
});
