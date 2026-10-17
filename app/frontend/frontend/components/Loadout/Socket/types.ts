import type { HardpointStat } from "@/frontend/composables/useHardpointStats";
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
  // The one figure the part is fitted for, set in gold at the socket's end the
  // way a ship page's hardpoint row sets its headline.
  headline?: { value: string; label: string };
  // The figures a ship page's hardpoint row shows beside its headline.
  stats?: HardpointStat[];
}

export interface LoadoutSocketSlot {
  id: string;
  label: string;
  size?: string;
  // The size badge a ship page's hardpoint row leads with.
  maxSize?: number;
  // What the slot takes, which identical-looking slots stack only if they share.
  kind?: string;
  item?: LoadoutSocketItem;
  // Shown, but nothing can be picked for it: the game locks it, or nothing
  // other than what it holds fits.
  locked?: boolean;
  // Which of the two, said on the socket so a press that does nothing is not
  // left unexplained.
  lockedBy?: "ship" | "noAlternatives";
  // Holds something other than the saved loadout has there.
  changed?: boolean;
  // Why the build in force refuses what the saved loadout has here.
  refused?: string;
  // What sits inside the item, shown under it the way a ship page nests a
  // turret's guns.
  children?: LoadoutSocketSlot[];
  // Every slot this socket stands for: identical siblings are shown once with
  // a count, as a ship page stacks identical mounts, and a pick fills them all.
  members?: string[];
  // The same slots one by one, for when a group is split out to fit each alone.
  stack?: LoadoutSocketSlot[];
}

export interface LoadoutSocketGroup {
  key: string;
  // Left out where every slot is its own mount, so a lone heading does not
  // repeat the socket's label.
  label?: string;
  slots: LoadoutSocketSlot[];
}
