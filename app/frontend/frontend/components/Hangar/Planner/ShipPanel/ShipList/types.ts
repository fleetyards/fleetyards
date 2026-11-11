import type { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import type { HangarPlanModel } from "@/services/fyApi";

export type ShipListSection = {
  key: string;
  label: string;
  // What the section's ships have in common, beside its label.
  hint?: string;
};

export type ShipListTag = {
  label: string;
  variant?: `${PillVariantsEnum}`;
};

export type ShipListItem = {
  id: string;
  section: string;
  title: string;
  // The ship the row stands for, whose stats open from its title and whose
  // manufacturer's icon leads the row.
  ship?: HangarPlanModel;
  // Leads the row where it stands for no one ship, such as a store purchase.
  icon?: string;
  meta?: string;
  tags?: ShipListTag[];
  badge?: string;
  // Text the search matches beyond the title, such as the ships a pledge holds.
  keywords?: string;
  price?: string;
  // Under the price: what it is the price of, such as the ship's store price
  // beside the cost of upgrading into it.
  priceNote?: string;
  // What the price sort orders by; an unknown price sorts last.
  sortPrice?: number | null;
  // Held above the rest of its section whatever the sort.
  pinned?: boolean;
  // Listed but not pickable, with why, so a ship that cannot take part does
  // not simply go missing.
  reason?: string;
};
