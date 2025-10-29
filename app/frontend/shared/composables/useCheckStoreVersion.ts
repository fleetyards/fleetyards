import { type FltYrdsStore } from "@/shared/stores/types";
import { useVersion as useVersionQuery } from "@/services/fyApi";

const CHECK_VERSION_INTERVAL = 1800 * 1000; // 30 mins

export const useCheckStoreVersion = (store: FltYrdsStore) => {
  const { data: version, refetch } = useVersionQuery();

  onBeforeMount(() => {
    check();
  });

  onMounted(() => {
    setInterval(() => {
      refetch();
    }, CHECK_VERSION_INTERVAL);
  });

  const check = () => {
    if (store.storeVersion !== window.STORE_VERSION) {
      console.info("Updating Store Version and resetting Store");

      store.$reset();
      store.storeVersion = window.STORE_VERSION;
    }
  };

  watch(
    () => version.value,
    () => {
      if (version.value) {
        store.updateVersion(version.value);
      }
    },
  );
};
