import { type WishlistParams } from "@/services/fyApi";

export const WISHLIST_SHOWN = 10;

// Shared by the wishlist panel and the on-sale tile, so both read one request.
export const onSaleWishlistParams: WishlistParams = {
  perPage: String(WISHLIST_SHOWN),
  q: { onSaleEq: true },
};
