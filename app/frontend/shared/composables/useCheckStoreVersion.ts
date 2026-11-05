import { type FltYrdsStore } from "@/shared/stores/types";
import { useVersion as useVersionQuery } from "@/services/fyApi";

const CHECK_VERSION_INTERVAL = 1800 * 1000; // 30 mins
const RESUME_CHECK_THROTTLE = 60 * 1000;

export const useCheckStoreVersion = (
  store: FltYrdsStore,
  { checkOnResume = false } = {},
) => {
  const { data: version, refetch } = useVersionQuery();

  onBeforeMount(() => {
    check();
  });

  let lastResumeCheck = Date.now();

  // Timers stand still while a phone keeps the app in the background, so coming
  // back to it is the moment a release can have gone by unnoticed.
  const checkVersionOnResume = () => {
    if (
      document.visibilityState !== "visible" ||
      Date.now() - lastResumeCheck < RESUME_CHECK_THROTTLE
    ) {
      return;
    }

    lastResumeCheck = Date.now();
    void refetch().then(({ isError }) => {
      // The radio is often not back yet; the next return to the app tries again.
      if (isError) lastResumeCheck = 0;
    });
  };

  onMounted(() => {
    setInterval(() => {
      void refetch();
    }, CHECK_VERSION_INTERVAL);

    if (checkOnResume) {
      document.addEventListener("visibilitychange", checkVersionOnResume);
    }
  });

  onBeforeUnmount(() => {
    document.removeEventListener("visibilitychange", checkVersionOnResume);
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
