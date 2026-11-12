import type { LandingServiceEnum } from "@/services/fyApi";

// Both fuels, rearm and repair, in the order the services read: fuel first.
export const LANDING_SERVICE_ORDER: LandingServiceEnum[] = [
  "hydrogen_refuel",
  "quantum_refuel",
  "rearm",
  "repair",
];

const LABEL_KEYS: Record<LandingServiceEnum, string> = {
  hydrogen_refuel: "model.landingService.hydrogenRefuel",
  quantum_refuel: "model.landingService.quantumRefuel",
  rearm: "model.landingService.rearm",
  repair: "model.landingService.repair",
};

export const landingServiceLabel = (
  service: LandingServiceEnum,
  t: (key: string) => string,
) => t(LABEL_KEYS[service]);

// A service as an icon shows it: what it is called, and the game's icon for it
// when there is one.
export interface LandingServiceIcon {
  key: LandingServiceEnum;
  label: string;
  url?: string;
}

type LandingServicesSource = {
  landingServices?: LandingServiceEnum[] | null;
};

// What a ship does for a ship landed on it, as one line: both fuels read as a
// plain refuel, and a ship offering only one names which.
export const landingServicesText = (
  model: LandingServicesSource,
  t: (key: string) => string,
): string | undefined => {
  const services = new Set(model.landingServices ?? []);
  const parts: string[] = [];

  if (services.has("quantum_refuel") && services.has("hydrogen_refuel")) {
    parts.push(t("model.landingService.refuel"));
  } else if (services.has("hydrogen_refuel")) {
    parts.push(t("model.landingService.hydrogenRefuel"));
  } else if (services.has("quantum_refuel")) {
    parts.push(t("model.landingService.quantumRefuel"));
  }

  if (services.has("rearm")) parts.push(t("model.landingService.rearm"));
  if (services.has("repair")) parts.push(t("model.landingService.repair"));

  return parts.length ? parts.join(", ") : undefined;
};
