import { useQueryClient } from "@tanstack/vue-query";
import { type Cart, getCartQueryKey } from "@/services/fyApi";

// Every cart edit answers with the whole cart, totals and stops included, so
// the answer replaces the cached cart rather than triggering a refetch.
export const useCartCache = () => {
  const queryClient = useQueryClient();

  const updateCart = (cart: Cart) => {
    queryClient.setQueryData(getCartQueryKey(), cart);
  };

  return { updateCart };
};
