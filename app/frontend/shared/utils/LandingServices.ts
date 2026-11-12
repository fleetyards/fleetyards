import type { LandingServiceEnum } from "@/services/fyApi";

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
