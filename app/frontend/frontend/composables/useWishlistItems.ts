import { watch } from "vue";
import { useRoute } from "vue-router/composables";
// import { useSessionStore } from "@/frontend/stores/Session";
// import { useWishlistStore } from "@/frontend/stores/Wishlist";
import Store from "@/frontend/lib/Store";
import WishlistItemsCollection from "@/frontend/api/collections/WishlistItems";

export const useWishlistItems = () => {
  // const sessionStore = useSessionStore();
  // const wishlistStore = useWishlistStore();

  const isAuthenticated = computed(
    () => Store.getters["session/isAuthenticated"],
  );

  const fetchHangarItems = async () => {
    // if (!sessionStore.isAuthenticated) {
    if (!isAuthenticated.value) {
      return;
    }

    // wishlistStore.save(await WishlistItemsCollection.findAll());
    await Store.dispatch(
      "wishlist/saveHangar",
      await WishlistItemsCollection.findAll(),
    );
  };

  fetchHangarItems();

  const route = useRoute();

  watch(
    () => route.path,
    () => {
      fetchHangarItems();
    },
  );

  watch(
    // () => sessionStore.isAuthenticated,
    () => isAuthenticated.value,
    () => {
      fetchHangarItems();
    },
  );
};
