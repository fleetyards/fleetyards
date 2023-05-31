import WishlistItemsCollection from "@/frontend/api/collections/WishlistItems";
import { useSessionStore } from "@/frontend/stores/Session";
import { useWishlistStore } from "@/frontend/stores/Wishlist";
import { watch } from "vue";
import { useRoute } from "vue-router";

export const useWishlistItems = () => {
  const sessionStore = useSessionStore();
  const wishlistStore = useWishlistStore();

  const fetchHangarItems = async () => {
    if (!sessionStore.isAuthenticated) {
      return;
    }

    wishlistStore.save(await WishlistItemsCollection.findAll());
  };

  fetchHangarItems();

  const route = useRoute();

  watch(
    () => route,
    () => {
      fetchHangarItems();
    }
  );

  watch(
    () => sessionStore.isAuthenticated,
    () => {
      fetchHangarItems();
    }
  );
};
