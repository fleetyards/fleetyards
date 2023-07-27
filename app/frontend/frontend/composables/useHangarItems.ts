import { useRoute } from "vue-router";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import HangarItemsCollection from "@/frontend/api/collections/HangarItems";

export const useHangarItems = () => {
  const sessionStore = useSessionStore();
  const hangarStore = useHangarStore();

  const fetchHangarItems = async () => {
    if (!sessionStore.isAuthenticated) {
      return;
    }

    hangarStore.save(await HangarItemsCollection.findAll());
  };

  fetchHangarItems();

  const route = useRoute();

  watch(
    () => route.path,
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
