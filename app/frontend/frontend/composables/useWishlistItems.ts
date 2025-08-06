import { useRoute } from "vue-router";
import { useSessionStore } from "@/frontend/stores/session";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { useWishlistItems as useWishlistItemsQuery } from "@/services/fyApi";

export const useWishlistItems = () => {
  const sessionStore = useSessionStore();
  const wishlistStore = useWishlistStore();

  const { data: wishlistItems, refetch } = useWishlistItemsQuery({
    query: {
      enabled: sessionStore.isAuthenticated,
    },
  });

  watch(
    () => wishlistItems.value,
    (items) => {
      if (items) {
        wishlistStore.save(items);
      }
    },
  );

  const route = useRoute();

  watch(
    () => route.path,
    async () => {
      await refetch();
    },
  );
};
