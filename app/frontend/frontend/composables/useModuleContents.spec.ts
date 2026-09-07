import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useModuleContents } from "./useModuleContents";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ModelModule,
} from "@/services/fyApi";

const hardpoint = (category: HardpointCategoryEnum): Hardpoint =>
  ({ category }) as Hardpoint;

const modul = (hardpoints?: Hardpoint[]): ModelModule =>
  ({ id: "m", name: "Bay", slug: "bay", hardpoints }) as ModelModule;

describe("useModuleContents", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  const contents = (mod: ModelModule) => useModuleContents().contents(mod);

  it("names each category a module fits", () => {
    const summary = contents(
      modul([
        hardpoint(HardpointCategoryEnum.WEAPONS),
        hardpoint(HardpointCategoryEnum.SHIELDGENERATOR),
      ]),
    );

    expect(summary).toContain("·");
    expect(summary?.split(" · ")).toHaveLength(2);
  });

  it("counts a category it fits more than once, and only then", () => {
    const twice = contents(
      modul([
        hardpoint(HardpointCategoryEnum.WEAPONS),
        hardpoint(HardpointCategoryEnum.WEAPONS),
      ]),
    );
    const once = contents(modul([hardpoint(HardpointCategoryEnum.WEAPONS)]));

    expect(twice).toMatch(/^2 × /);
    expect(once).not.toMatch(/^\d/);
  });

  it("drops the ports that say nothing about what the module is for", () => {
    expect(
      contents(
        modul([
          hardpoint(HardpointCategoryEnum.CONTROLLER),
          hardpoint(HardpointCategoryEnum.UNKNOWN),
        ]),
      ),
    ).toBeUndefined();
  });

  // Undefined rather than a label, so each picker can pick its own fallback.
  it("is undefined for a module with no hardpoints at all", () => {
    expect(contents(modul([]))).toBeUndefined();
    expect(contents(modul(undefined))).toBeUndefined();
  });
});
