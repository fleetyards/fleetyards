import { useRoute } from "vue-router";
import { useSessionStore } from "@/frontend/stores/session";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useHangarItems as useHangarItemsQuery } from "@/services/fyApi";

export const useHangarItems = () => {
  const sessionStore = useSessionStore();
  const hangarStore = useHangarStore();

  const { data: hangarItems, refetch } = useHangarItemsQuery({
    query: {
      enabled: sessionStore.isAuthenticated,
    },
  });

  watch(
    () => hangarItems.value,
    (items) => {
      if (items) {
        hangarStore.save(items);
      }
    },
  );

  const route = useRoute();

  watch(
    () => route.path,
    async () => {
      await refetch();
    },
  );
};
