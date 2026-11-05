import { type FltYrdsStore } from "@/shared/stores/types";
import { useVersion as useVersionQuery } from "@/services/fyApi";

const CHECK_VERSION_INTERVAL = 1800 * 1000; // 30 mins
const RESUME_CHECK_THROTTLE = 60 * 1000;

export const useCheckStoreVersion = (store: FltYrdsStore) => {
  const { data: version, refetch } = useVersionQuery();

  onBeforeMount(() => {
    check();
  });

  let lastResumeCheck = Date.now();

  // Timers stand still while a phone keeps the app in the background, so coming
  // back to it is the moment a release can have gone by unnoticed.
  const checkOnResume = () => {
    if (
      document.visibilityState !== "visible" ||
      Date.now() - lastResumeCheck < RESUME_CHECK_THROTTLE
    ) {
      return;
    }

    lastResumeCheck = Date.now();
    void refetch();
  };

  onMounted(() => {
    setInterval(() => {
      void refetch();
    }, CHECK_VERSION_INTERVAL);

    document.addEventListener("visibilitychange", checkOnResume);
  });

  onBeforeUnmount(() => {
    document.removeEventListener("visibilitychange", checkOnResume);
  });

  const check = () => {
    if (store.storeVersion !== window.STORE_VERSION) {
      console.info("Updating Store Version and resetting Store");

      if (typeof store.resetAll === "function") {
        store.resetAll(true);
      } else {
        store.$reset();
      }
      store.$patch({ storeVersion: window.STORE_VERSION });
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
