import { type CraftedSelection } from "@/frontend/components/Logistics/types";

// The grades as the API takes them. The form validates every graded slot, so
// a blank one never reaches here; it is dropped rather than sent as null.
export const craftedQualities = (crafted: CraftedSelection) =>
  Object.fromEntries(
    Object.entries(crafted.qualities).filter(
      (entry): entry is [string, number] => entry[1] !== undefined,
    ),
  );
