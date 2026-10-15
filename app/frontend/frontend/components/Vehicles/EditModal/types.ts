import type { VehicleUpdateInput } from "@/services/fyApi";

export enum VehicleEditTabsEnum {
  GENERAL = "general",
  VISIBILITY = "visibility",
  NAMES = "names",
  GROUPS = "groups",
  IMAGE = "image",
  MODULES = "modules",
  UPGRADES = "upgrades",
  PAINT = "paint",
}

export type VehicleEditValues = Pick<
  VehicleUpdateInput,
  | "flagship"
  | "boughtVia"
  | "public"
  | "nameVisible"
  | "saleNotify"
  | "logEntriesPublicByDefault"
  | "name"
  | "serial"
  | "alternativeNames"
  | "hangarGroupIds"
  | "modelModuleIds"
  | "modelUpgradeIds"
  | "modelPaintIds"
> & {
  image?: string | null;
};

export type VehicleImageChanges = Pick<
  VehicleUpdateInput,
  "image" | "modelImageId" | "modelPaintPictureId"
>;
