import { useQueryClient } from "@tanstack/vue-query";
import {
  type Cart,
  CartStrategyEnum,
  getCartListQueryKey,
  getCartListsQueryKey,
  getCartQueryKey,
} from "@/services/fyApi";

// Every cart edit answers with the whole list, totals and stops included, so
// the answer replaces the cached list rather than triggering a refetch: under
// its own key, and as the active cart when it is the active one. The lists
// carry line counts, so those are refetched.
export const useCartCache = () => {
  const queryClient = useQueryClient();

  const updateCart = (cart: Cart) => {
    // Edits answer with the cheapest plan, which is also what the badge and
    // the widget read under the bare key.
    const cheapest = { strategy: CartStrategyEnum.CHEAPEST };

    if (cart.active) {
      queryClient.setQueryData(getCartQueryKey(), cart);
      queryClient.setQueryData(getCartQueryKey(cheapest), cart);
    }

    if (cart.id) {
      queryClient.setQueryData(getCartListQueryKey(cart.id), cart);
      queryClient.setQueryData(getCartListQueryKey(cart.id, cheapest), cart);
    }

    // A view planned another way asks again.
    const plannedOtherwise = (params: unknown) =>
      !!params &&
      (params as { strategy?: string }).strategy !== CartStrategyEnum.CHEAPEST;

    void queryClient.invalidateQueries({
      predicate: ({ queryKey }) =>
        (queryKey[0] === "cart" && plannedOtherwise(queryKey[1])) ||
        (queryKey[0] === "carts" &&
          queryKey[1] === cart.id &&
          plannedOtherwise(queryKey[2])),
    });

    void queryClient.invalidateQueries({
      queryKey: getCartListsQueryKey(),
      exact: true,
    });
  };

  // Switching, creating or deleting a list changes which one is active, so
  // every list's `active` flag is refetched with it.
  const refreshCarts = () => {
    void queryClient.invalidateQueries({ queryKey: getCartQueryKey() });
    void queryClient.invalidateQueries({ queryKey: getCartListsQueryKey() });
  };

  return { updateCart, refreshCarts };
};
