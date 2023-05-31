import HangarItemsCollection from "@/frontend/api/collections/HangarItems";
import { useHangarStore } from "@/frontend/stores/Hangar";
import { useSessionStore } from "@/frontend/stores/Session";
import { watch } from "vue";
import { useRoute } from "vue-router";

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
