import { describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import {
  ComponentCountermeasureKindEnum,
  HardpointCategoryEnum,
  type ComponentWeapon,
  type Hardpoint,
} from "@/services/fyApi";
import { useHardpointStats } from "./useHardpointStats";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
}));

function launcherHardpoint(typeData: ComponentWeapon): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "launcher",
    category: HardpointCategoryEnum.COUNTERMEASURES,
    component: { name: "Launcher", typeData } as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

function statsFor(hardpoint: Hardpoint) {
  let result: ReturnType<typeof useHardpointStats> | undefined;
  createApp({ render: () => null }).runWithContext(() => {
    result = useHardpointStats(hardpoint);
  });

  return result!.value;
}

const valueOf = (stats: { label: string; value: string }[], label: string) =>
  stats.find((stat) => stat.label === label)?.value;

describe("useHardpointStats for a countermeasure's ammo", () => {
  it("shows a decoy's duration and a signature that fades", () => {
    const stats = statsFor(
      launcherHardpoint({
        maxAmmo: 20,
        countermeasure: {
          kind: ComponentCountermeasureKindEnum.DECOY,
          lifetime: 12,
          infrared: { start: 50000, end: 20000 },
          electromagnetic: { start: 60000, end: 60000 },
        },
      }),
    );

    expect(
      valueOf(stats, "labels.hardpoint.countermeasureStats.duration"),
    ).toBe("12 s");
    expect(
      valueOf(stats, "labels.hardpoint.countermeasureStats.infrared"),
    ).toBe("50000 → 20000");
    expect(
      valueOf(stats, "labels.hardpoint.countermeasureStats.electromagnetic"),
    ).toBe("60000");
    expect(
      valueOf(stats, "labels.hardpoint.countermeasureStats.spawnDelay"),
    ).toBeUndefined();
  });

  it("shows when a noise cloud deploys", () => {
    const stats = statsFor(
      launcherHardpoint({
        countermeasure: {
          kind: ComponentCountermeasureKindEnum.NOISE,
          lifetime: 8,
          spawnDelay: 1,
        },
      }),
    );

    expect(
      valueOf(stats, "labels.hardpoint.countermeasureStats.spawnDelay"),
    ).toBe("1 s");
  });
});
