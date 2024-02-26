import { useRoute } from "vue-router";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useApiClient } from "@/frontend/composables/useApiClient";

const { hangar: hangarService } = useApiClient();

export const useHangarItems = () => {
  const sessionStore = useSessionStore();
  const hangarStore = useHangarStore();

  const fetchHangarItems = async () => {
    if (!sessionStore.isAuthenticated) {
      return;
    }

    try {
      hangarStore.save(await hangarService.hangarItems());
    } catch (error) {
      console.error(error);
    }
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
