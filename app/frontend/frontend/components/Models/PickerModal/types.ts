import type { ModelOption } from "@/services/fyApi";

// The two flags a picked ship can already carry, and the one the list you opened
// the picker from is about to duplicate.
export enum ModelPickerBadge {
  IN_HANGAR = "inHangar",
  ON_WISHLIST = "onWishlist",
}

// Quantity travels with every pick even where the picker hides the stepper, so a
// caller that only wants slugs reads the same shape as one adding three copies.
export type ModelPickerSelection = {
  option: ModelOption;
  quantity: number;
};
