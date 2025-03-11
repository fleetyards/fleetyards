import { type FltYrdsStore } from "@/shared/stores/types";

export const useCheckStoreVersion = (store: FltYrdsStore) => {
  const check = () => {
    if (store.storeVersion !== window.STORE_VERSION) {
      console.info("Updating Store Version and resetting Store");

      store.$reset();
      store.storeVersion = window.STORE_VERSION;
    }
  };

  onBeforeMount(() => {
    check();
  });
};
