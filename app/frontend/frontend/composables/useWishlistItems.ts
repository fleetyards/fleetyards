import { useRoute } from "vue-router";
import { useSessionStore } from "@/frontend/stores/session";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { useFyApiClient } from "@/shared/composables/useFyApiClient";
import { useI18n } from "@/frontend/composables/useI18n";

export const useWishlistItems = () => {
  const sessionStore = useSessionStore();
  const wishlistStore = useWishlistStore();

  const { currentLocale } = useI18n();
  const { wishlist: wishlistService } = useFyApiClient(currentLocale);

  const fetchWishlistItems = async () => {
    if (!sessionStore.isAuthenticated) {
      return;
    }

    try {
      wishlistStore.ships = await wishlistService.wishlistItems();
    } catch (error) {
      console.error(error);
    }
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
