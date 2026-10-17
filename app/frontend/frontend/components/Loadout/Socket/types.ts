import type { HardpointCategoryEnum } from "@/services/fyApi";

// What a socket holds, as the socket shows it: no slot type's own record, so
// modules, weapons and the rest all reach it through their caller.
export interface LoadoutSocketItem {
  id: string;
  name: string;
  image?: string;
  // One figure that says what the item brings, already formatted.
  figure?: string;
  // The glyph shown where there is no image; a module's when left out.
  category?: HardpointCategoryEnum;
}

export interface LoadoutSocketSlot {
  id: string;
  label: string;
  size?: string;
  item?: LoadoutSocketItem;
  // Shown, but nothing can be picked for it: the game locks it, or nothing
  // other than what it holds fits.
  locked?: boolean;
  // What sits inside the item, shown under it the way a ship page nests a
  // turret's guns.
  children?: LoadoutSocketSlot[];
}

export interface LoadoutSocketGroup {
  key: string;
  // Left out where every slot is its own mount, so a lone heading does not
  // repeat the socket's label.
  label?: string;
  slots: LoadoutSocketSlot[];
}
