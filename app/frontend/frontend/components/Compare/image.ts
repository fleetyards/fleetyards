import type { Component, Equipment, MediaFile } from "@/services/fyApi";

const usable = (file?: MediaFile | null) =>
  file?.mediumUrl || file?.smallUrl ? file : undefined;

// What a compared component or piece of equipment is pictured by, in the table
// and in the picker alike: the angled render, which draws every item from the
// same angle, and the store image where there is none. Equipment carries its
// store image beside `media` rather than in it.
export const compareItemImage = (
  item: Component | Equipment,
): MediaFile | undefined =>
  usable(item.media?.angledView) ??
  usable("storeImage" in item ? item.storeImage : undefined) ??
  usable(item.media?.storeImage);
