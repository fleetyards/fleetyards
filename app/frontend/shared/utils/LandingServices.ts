import type { LandingServiceEnum } from "@/services/fyApi";
import type { i18nHelpers } from "@/shared/utils/I18nHelpers";

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

type ServicingAreaSource = {
  name?: string | null;
  width: number;
  length: number;
  height: number;
};

type ServicingAreaHelpers = Pick<ReturnType<typeof i18nHelpers>, "toNumber"> & {
  t: (scope: string, options?: Record<string, unknown>) => string;
};

// What an area is called, with its 1-based number on the ship's page when no
// admin named it, and its size as length, width and height.
export const servicingAreaLabel = (
  area: ServicingAreaSource,
  index: number,
  { t }: Pick<ServicingAreaHelpers, "t">,
) => area.name || t("model.servicingArea", { index });

export const servicingAreaSize = (
  area: ServicingAreaSource,
  { toNumber }: Pick<ServicingAreaHelpers, "toNumber">,
) =>
  `${toNumber(area.length)} × ${toNumber(area.width)} × ${toNumber(area.height)} m`;
