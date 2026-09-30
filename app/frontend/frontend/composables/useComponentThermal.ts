import type { Component } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import type { HardpointStat } from "@/frontend/composables/useHardpointStats";

export interface ComponentThermal {
  temperature: HardpointStat[];
  misfire: HardpointStat[];
}

// The temperature model and the misfire trigger levels, each as its own list
// of rows. Both are absent on most components -- the game switches the
// temperature model off on guns and coolers, and only powered systems carry
// misfire levels -- so an empty list means "nothing to show", not "zero".
export const useComponentThermal = (
  component: MaybeRefOrGetter<Component | undefined>,
) => {
  const { t, toNumber } = useI18n();

  const kelvin = (value: number) =>
    `${String(toNumber(Math.round(value), "integer"))} K`;
  const percent = (value: number) => `${Math.round(value * 100)}%`;
  const seconds = (value: number) =>
    `${String(toNumber(Math.round(value), "integer"))} s`;

  return computed<ComponentThermal>(() => {
    const value = toValue(component);
    const temperature = value?.temperature;
    const misfire = value?.misfire;

    const temperatureRows: HardpointStat[] = [];
    const pushTemperature = (key: string, figure?: number) => {
      if (typeof figure !== "number") return;

      temperatureRows.push({
        label: t(`labels.component.temperature.${key}`),
        value: kelvin(figure),
      });
    };

    if (temperature) {
      pushTemperature("minCooling", temperature.minCoolingTemperature);
      pushTemperature("warning", temperature.overheatWarningTemperature);
      pushTemperature("overheat", temperature.overheatTemperature);
      pushTemperature("recovery", temperature.overheatRecoveryTemperature);

      const { misfireMinTemperature: low, misfireMaxTemperature: high } =
        temperature;
      if (typeof low === "number" && typeof high === "number") {
        temperatureRows.push({
          label: t("labels.component.temperature.misfireRange"),
          value:
            Math.round(low) === Math.round(high)
              ? kelvin(low)
              : `${Math.round(low)}–${kelvin(high)}`,
        });
      }

      pushTemperature("irStart", temperature.irStartTemperature);
      if (typeof temperature.irPerKelvin === "number") {
        temperatureRows.push({
          label: t("labels.component.temperature.irPerKelvin"),
          value: String(toNumber(temperature.irPerKelvin, "number")),
        });
      }
    }

    const misfireRows: HardpointStat[] = [];
    if (misfire) {
      (["heat", "distortion", "damage", "wear"] as const).forEach((key) => {
        const figure = misfire[key];
        if (typeof figure !== "number") return;

        misfireRows.push({
          label: t(`labels.component.misfire.${key}`),
          value: percent(figure),
        });
      });

      const { minWindow: low, maxWindow: high } = misfire;
      if (typeof low === "number" && typeof high === "number") {
        misfireRows.push({
          label: t("labels.component.misfire.window"),
          value:
            Math.round(low) === Math.round(high)
              ? seconds(low)
              : `${Math.round(low)}–${seconds(high)}`,
        });
      }
    }

    return { temperature: temperatureRows, misfire: misfireRows };
  });
};
