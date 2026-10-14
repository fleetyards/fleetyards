import type { VehicleUpdateInput } from "@/services/fyApi";

export enum VehicleEditTabsEnum {
  GENERAL = "general",
  VISIBILITY = "visibility",
  NAMES = "names",
  GROUPS = "groups",
  IMAGE = "image",
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
> & {
  image?: string | null;
};

export type VehicleImageChanges = Pick<
  VehicleUpdateInput,
  "image" | "modelImageId"
>;
