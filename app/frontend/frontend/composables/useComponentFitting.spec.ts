import { describe, expect, it } from "vitest";
import { lowerIsBetter } from "./useComponentFitting";

describe("lowerIsBetter", () => {
  it("reads signatures, times, cooldowns, draws and fuel burn as better smaller", () => {
    [
      "signatureEm",
      "signatureIr",
      "powerConsumption",
      "quantumDrives.spoolUpTime",
      "quantumDrives.fuelConsumption",
      "controllers.reconfigurationCooldown",
      "thrusters.fuelBurn",
      "missiles.lockTime",
      "weapons.heatPerShot",
    ].forEach((key) => expect(lowerIsBetter(key), key).toBe(true));
  });

  it("reads output, damage and speed as better larger", () => {
    [
      "shields.hp",
      "powerPlants.output",
      "weapons.burstDps",
      "quantumDrives.speed",
      "missiles.lockRange",
    ].forEach((key) => expect(lowerIsBetter(key), key).toBe(false));
  });
});
