import { watch } from "vue";
import { useRoute } from "vue-router/composables";
import { useSessionStore } from "@/frontend/stores/Session";
import { useHangarStore } from "@/frontend/stores/Hangar";
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
