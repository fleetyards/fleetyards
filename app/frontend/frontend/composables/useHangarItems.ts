import { useRoute } from "vue-router";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import { hangarItems } from "@/services/fyApi";

export const useHangarItems = () => {
  const sessionStore = useSessionStore();
  const hangarStore = useHangarStore();

  const fetchHangarItems = async () => {
    if (!sessionStore.isAuthenticated) {
      return;
    }

    await hangarItems()
      .then((response) => {
        hangarStore.save(response);
      })
      .catch((error) => {
        console.error(error);
      });
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
    () => sessionStore.isAuthenticated,
    () => {
      fetchHangarItems();
    },
  );
};
