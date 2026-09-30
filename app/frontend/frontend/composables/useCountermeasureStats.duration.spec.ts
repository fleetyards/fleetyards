import { describe, expect, it } from "vitest";
import {
  ComponentCountermeasureKindEnum,
  HardpointCategoryEnum,
  type ComponentCountermeasure,
  type Hardpoint,
} from "@/services/fyApi";
import { computeCountermeasureStats } from "./useCountermeasureStats";

function launcher(
  scKey: string,
  maxAmmo: number,
  countermeasure?: ComponentCountermeasure,
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "launcher",
    category: HardpointCategoryEnum.COUNTERMEASURES,
    component: {
      name: "Launcher",
      scKey,
      typeData: { maxAmmo, countermeasure },
    } as unknown as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

describe("computeCountermeasureStats durations", () => {
  it("spans the lifetimes of every launcher of a kind", () => {
    const stats = computeCountermeasureStats([
      launcher("cml_chaff_a", 20, {
        kind: ComponentCountermeasureKindEnum.NOISE,
        lifetime: 8,
      }),
      launcher("cml_chaff_b", 20, {
        kind: ComponentCountermeasureKindEnum.NOISE,
        lifetime: 12,
      }),
      launcher("cml_flare", 96, {
        kind: ComponentCountermeasureKindEnum.DECOY,
        lifetime: 8,
      }),
    ]);

    expect(stats.durations).toEqual([
      {
        key: "decoy",
        label: "labels.defense.countermeasure.decoy",
        min: 8,
        max: 8,
      },
      {
        key: "noise",
        label: "labels.defense.countermeasure.noise",
        min: 8,
        max: 12,
      },
    ]);
  });

  it("trusts the parsed ammo over the item key", () => {
    const stats = computeCountermeasureStats([
      launcher("orig_cml_noise_launcher", 40, {
        kind: ComponentCountermeasureKindEnum.DECOY,
        lifetime: 12,
      }),
    ]);

    expect(stats.counts.map((entry) => entry.key)).toEqual(["decoy"]);
  });

  it("has no durations for launchers loaded without their ammo", () => {
    expect(
      computeCountermeasureStats([launcher("cml_flare", 20)]).durations,
    ).toEqual([]);
  });
});
