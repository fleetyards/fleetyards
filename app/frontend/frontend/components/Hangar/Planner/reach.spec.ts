import { describe, expect, it } from "vitest";
import {
  HangarPlanCcuIntoEnum,
  HangarPlanCcuOutOfEnum,
  type HangarPlanModel,
} from "@/services/fyApi";
import { reaches, upgradeCost } from "./reach";

const model = (
  name: string,
  pledgePrice: number,
  ccuIntoFrom?: string[],
): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: false,
  pledgePrice,
  ccuInto: HangarPlanCcuIntoEnum.SALES_ONLY,
  ccuOutOf: HangarPlanCcuOutOfEnum.KNOWN,
  ccuIntoFrom,
});

describe("Hangar/Planner/reach", () => {
  it("reaches a ship only its variants upgrade into from those alone", () => {
    const kraken = model("Kraken", 1650);
    const hull = model("Hull C", 500);
    const privateer = model("Kraken Privateer", 2000, ["Kraken"]);

    expect(reaches(kraken, privateer)).toBe(true);
    expect(reaches(hull, privateer)).toBe(false);
    expect(reaches(hull, model("Polaris", 975))).toBe(true);
  });

  it("costs an upgrade the difference in store price, and the same ship nothing", () => {
    const cutlass = model("Cutlass Black", 110);
    const taurus = model("Constellation Taurus", 175);
    const unpriced = { ...model("Unpriced", 0), pledgePrice: null };

    expect(upgradeCost(cutlass, taurus)).toBe(65);
    expect(upgradeCost(taurus, cutlass)).toBe(0);
    expect(upgradeCost(taurus, taurus)).toBe(0);
    expect(upgradeCost(cutlass, unpriced)).toBeUndefined();
  });
});
