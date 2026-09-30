import { describe, expect, it, vi } from "vitest";
import type { Component } from "@/services/fyApi";
import { useComponentThermal } from "./useComponentThermal";

// The real helper's two traps: 0 reads as "not available", and a unit is a
// translation key.
vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number, units?: string) => {
      if (!value) return "labels.notAvailable";
      if (units && units !== "integer") return `number.${units}`;
      return String(value);
    },
  }),
}));

const thermalOf = (component: Partial<Component>) =>
  useComponentThermal(component as Component).value;

describe("useComponentThermal", () => {
  it("lists the temperature model in kelvin, the misfire range as one row", () => {
    const { temperature } = thermalOf({
      temperature: {
        minCoolingTemperature: 303,
        overheatWarningTemperature: 373,
        overheatTemperature: 383,
        overheatRecoveryTemperature: 378,
        misfireMinTemperature: 380,
        misfireMaxTemperature: 383,
        irStartTemperature: 318,
        irPerKelvin: 10,
      },
    });

    expect(temperature).toEqual([
      { label: "labels.component.temperature.minCooling", value: "303 K" },
      { label: "labels.component.temperature.warning", value: "373 K" },
      { label: "labels.component.temperature.overheat", value: "383 K" },
      { label: "labels.component.temperature.recovery", value: "378 K" },
      {
        label: "labels.component.temperature.misfireRange",
        value: "380–383 K",
      },
      { label: "labels.component.temperature.irStart", value: "318 K" },
      { label: "labels.component.temperature.irPerKelvin", value: "10" },
    ]);
  });

  it("lists misfire trigger levels as percentages and the window in seconds", () => {
    const { misfire } = thermalOf({
      misfire: {
        heat: 0.8,
        distortion: 0.6,
        damage: 0.9,
        wear: 1,
        minWindow: 45,
        maxWindow: 600,
      },
    });

    expect(misfire.map((row) => row.value)).toEqual([
      "80%",
      "60%",
      "90%",
      "100%",
      "45–600 s",
    ]);
  });

  it("shows a real zero as zero", () => {
    const { temperature, misfire } = thermalOf({
      temperature: { minCoolingTemperature: 0, irPerKelvin: 0 },
      misfire: { heat: 0, minWindow: 0, maxWindow: 0 },
    });

    expect(temperature.map((row) => row.value)).toEqual(["0 K", "0"]);
    expect(misfire.map((row) => row.value)).toEqual(["0%", "0 s"]);
  });

  it("gives nothing for a component with neither", () => {
    expect(thermalOf({})).toEqual({ temperature: [], misfire: [] });
  });
});
