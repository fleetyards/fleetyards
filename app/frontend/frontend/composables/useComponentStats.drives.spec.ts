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
    name: "Test Drive",
    slug: "test-drive",
    category,
    typeData,
  }) as unknown as Component;

// Thousands are grouped with a narrow no-break space.
const valueOf = (stats: { label: string; value: string }[], label: string) =>
  stats.find((stat) => stat.label === label)?.value;

// The ARCC Torrent, a size 2 grade C drive, as the game files describe it.
const torrent = {
  driveSpeed: 263_400_000,
  engageSpeed: 84_000_000,
  calibrationRate: 1000,
  disconnectRange: 34_693,
  interdictionEffectTime: 2.6,
  spoolUpTime: 7.3,
  cooldownTime: 14.3,
  stageOneAccelRate: 6_005_714,
  stageTwoAccelRate: 8_631_428,
  splineJumpParams: {
    driveSpeed: 400_000,
    stageOneAccelRate: 250,
    stageTwoAccelRate: 50_000,
    spoolUpTime: 6,
    cooldownTime: 21.6,
    interdictionEffectTime: 5,
  },
};

describe("useComponentStats for drives", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("shows a quantum drive's engage speed, calibration, disconnect range and interdiction", () => {
    const stats = useComponentStats(component("quantumdrive", torrent)).value;

    expect(valueOf(stats, "Engage Speed")).toBe("84\u202f000 km/s");
    expect(valueOf(stats, "Calibration Rate")).toBe("1\u202f000/s");
    expect(valueOf(stats, "Disconnect Range")).toBe("34,7 km");
    expect(valueOf(stats, "Interdiction Time")).toBe("2,6 s");
  });

  it("keeps the tenths of spool and cooldown", () => {
    const stats = useComponentStats(component("quantumdrive", torrent)).value;

    expect(valueOf(stats, "Spool Up")).toBe("7,3 s");
    expect(valueOf(stats, "Cooldown")).toBe("14,3 s");
  });

  // A 250 m/s² first stage is 0.25 km/s², and one decimal would call it 0.3.
  it("groups the spline jump figures as one mode", () => {
    const stats = useComponentStats(component("quantumdrive", torrent)).value;
    const spline = stats.filter((stat) => stat.group === "splineJump");

    expect(spline.map((stat) => [stat.label, stat.value])).toEqual([
      ["Orbit", "400 km/s"],
      ["Orbit Accel", "0,25 / 50 km/s²"],
      ["Orbit Spool Up", "6 s"],
      ["Orbit Cooldown", "21,6 s"],
      ["Orbit Interdiction", "5 s"],
    ]);
    expect(
      stats.filter((stat) => !stat.group).map((s) => s.label),
    ).not.toContain("Orbit");
  });

  it("shows a jump drive's tunnel flight", () => {
    const stats = useComponentStats(
      component("jumpdrive", {
        exitSpeed: 200,
        maxTunnelSpeed: 1300,
        respoolTime: 3,
      }),
    ).value;

    expect(valueOf(stats, "Exit Speed")).toBe("200 m/s");
    expect(valueOf(stats, "Max Tunnel Speed")).toBe("1\u202f300 m/s");
    expect(valueOf(stats, "Respool")).toBe("3 s");
  });
});
