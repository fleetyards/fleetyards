import { type Model, type Vehicle } from "@/services/fyApi";

// What a plaque is drawn from: a hangar ship, a public one, or a ship picked
// from the catalogue that nobody owns.
export type PlaqueContent = Pick<
  Vehicle,
  | "id"
  | "name"
  | "serial"
  | "dedication"
  | "dedicationVerse"
  | "launchedOn"
  | "launchPort"
  | "affiliation"
  | "plaqueCaptain"
  | "operationsGroup"
  | "manufacturerShortName"
  | "manufacturerCode"
  | "plaqueStyle"
  | "plaqueLocale"
  | "shipyard"
> & { model: Pick<Model, "name" | "manufacturer"> };

export const PLAQUE_DEFAULT_LOCALE = "en";
