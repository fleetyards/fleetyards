import type { HardpointStat } from "@/frontend/composables/useHardpointStats";
import {
  type CargoHold,
  type FuelTank,
  type Hardpoint,
  HardpointCategoryEnum,
} from "@/services/fyApi";
import { humanizeHoldName } from "@/shared/utils/CargoHolds";

type Translate = (key: string, options?: Record<string, unknown>) => string;

type Format = (value: number, units: string) => string | number;

type Headline = { value: string; unit: string };

/**
 * What a kind of hardpoint shows differently from a part's row: one row draws
 * every kind -- the stack, the fold, the name over its maker -- and these only
 * say what goes in it. A kind not listed reads as a part does.
 */
export interface RowPresentation {
  // In place of the part's name and catalogue link, on a game-files row.
  label?: (hardpoint: Hardpoint, t: Translate) => string;
  // In place of the figure the stats lead with; none where it returns nothing.
  headline?: (
    hardpoint: Hardpoint,
    t: Translate,
    toNumber: Format,
  ) => Headline | undefined;
  // In place of the figures beside the headline.
  stats?: (
    hardpoint: Hardpoint,
    t: Translate,
    toNumber: Format,
  ) => HardpointStat[];
  // A kind of hardpoint without a size worth a badge.
  sizeless?: boolean;
}

const humanize = (name: string) =>
  name
    .split("_")
    .join(" ")
    .replace("hardpoint", "")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());

// A thruster has no name of its own; how it moves says what it is.
const thruster: RowPresentation = {
  label: (hardpoint, t) => {
    if (!hardpoint.component) return "TBD";

    const subType = hardpoint.component.subType || "FixedThruster";

    return t(`labels.hardpoint.thrusters.subTypes.${subType}`, {
      defaultValue: subType,
    });
  },
};

const capacity = (
  value: number | undefined,
  t: Translate,
  toNumber: Format,
): Headline | undefined =>
  value
    ? {
        value: String(toNumber(value, "cargo")),
        unit: t("labels.cargoGridViewer.capacity"),
      }
    : undefined;

const cargoGrid: RowPresentation = {
  label: (hardpoint) =>
    humanizeHoldName(
      hardpoint.component?.name || hardpoint.component?.scKey || "",
    ),
  headline: (hardpoint, t, toNumber) =>
    capacity(
      (hardpoint.component?.typeData as CargoHold | undefined)?.capacity,
      t,
      toNumber,
    ),
  // The largest container reads as a figure, like every other one on a row.
  stats: (hardpoint, t, toNumber) => {
    const size = (hardpoint.component?.typeData as CargoHold | undefined)
      ?.maxContainerSize?.size;

    return size
      ? [
          {
            label: t("labels.hardpoint.maxContainerSize"),
            value: String(toNumber(size, "cargo")),
          },
        ]
      : [];
  },
  sizeless: true,
};

const tank: RowPresentation = {
  label: (hardpoint, t) => {
    const component = hardpoint.component;

    if (component?.subType === "Fuel") {
      return t("labels.hardpoint.fuelTanks.hydrogen");
    }
    if (component?.subType === "QuantumFuel") {
      return t("labels.hardpoint.fuelTanks.quantum");
    }
    if (
      component?.type === "ExternalFuelTank" ||
      hardpoint.category === HardpointCategoryEnum.ORE_PODS
    ) {
      return component?.name || t("labels.notAvailable");
    }
    if (hardpoint.category === HardpointCategoryEnum.SALVAGE_STORAGE) {
      return t("labels.model.salvageStorage");
    }

    return "TBD";
  },
  // A ground vehicle's ore pod names its volume `storage`.
  headline: (hardpoint, t, toNumber) => {
    const data = hardpoint.component?.typeData as
      (FuelTank & { storage?: number }) | undefined;

    return capacity(data?.capacity || data?.storage, t, toNumber);
  },
  stats: () => [],
};

const seat: RowPresentation = {
  label: (hardpoint) => humanize(hardpoint.name),
  headline: () => undefined,
  stats: () => [],
  sizeless: true,
};

// A loadout's module slot, shown rather than picked: the module's name, or
// that the slot is empty.
const moduleSlot: RowPresentation = {
  label: (hardpoint, t) =>
    hardpoint.component?.name || t("labels.vehicleLoadout.nothingFitted"),
  headline: () => undefined,
  stats: () => [],
};

const PRESENTATIONS: Partial<Record<HardpointCategoryEnum, RowPresentation>> = {
  [HardpointCategoryEnum.MAIN_THRUSTERS]: thruster,
  [HardpointCategoryEnum.MANEUVERING_THRUSTERS]: thruster,
  [HardpointCategoryEnum.RETRO_THRUSTERS]: thruster,
  [HardpointCategoryEnum.VTOL_THRUSTERS]: thruster,
  [HardpointCategoryEnum.CARGOGRID]: cargoGrid,
  [HardpointCategoryEnum.FUELTANKS]: tank,
  [HardpointCategoryEnum.EXTERNAL_FUEL_TANKS]: tank,
  [HardpointCategoryEnum.ORE_PODS]: tank,
  [HardpointCategoryEnum.SALVAGE_STORAGE]: tank,
  [HardpointCategoryEnum.SEAT]: seat,
  [HardpointCategoryEnum.MODULE]: moduleSlot,
};

export const rowPresentation = (
  category?: HardpointCategoryEnum | null,
): RowPresentation => (category && PRESENTATIONS[category]) || {};
