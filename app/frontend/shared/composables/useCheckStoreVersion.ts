import type { Store } from "pinia";

export const useCheckStoreVersion = (store: Store) => {
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
