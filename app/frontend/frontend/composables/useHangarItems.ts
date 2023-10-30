import { watch } from "vue";
import { useRoute } from "vue-router/composables";
// import { useSessionStore } from "@/frontend/stores/Session";
// import { useHangarStore } from "@/frontend/stores/Hangar";
import Store from "@/frontend/lib/Store";
import HangarItemsCollection from "@/frontend/api/collections/HangarItems";

export const useHangarItems = () => {
  // const sessionStore = useSessionStore();
  // const hangarStore = useHangarStore();

  const isAuthenticated = computed(
    () => Store.getters["session/isAuthenticated"],
  );

  const fetchHangarItems = async () => {
    // if (!sessionStore.isAuthenticated) {
    if (!isAuthenticated.value) {
      return;
    }

    // hangarStore.save(await HangarItemsCollection.findAll());
    await Store.dispatch(
      "hangar/saveHangar",
      await HangarItemsCollection.findAll(),
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
