import { useRoute } from "vue-router";
import { useSessionStore } from "@/frontend/stores/session";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { wishlistItems } from "@/services/fyApi";

export const useWishlistItems = () => {
  const sessionStore = useSessionStore();
  const wishlistStore = useWishlistStore();

  const fetchWishlistItems = async () => {
    if (!sessionStore.isAuthenticated) {
      return;
    }

    await wishlistItems()
      .then((response) => {
        wishlistStore.save(response);
      })
      .catch((error) => {
        console.error(error);
      });
  };

  fetchWishlistItems();

  const route = useRoute();

  watch(
    () => route.path,
    () => {
      fetchWishlistItems();
    },
  );

  watch(
    () => sessionStore.isAuthenticated,
    () => {
      fetchWishlistItems();
    },
  );
};
