import { useIsFetching } from "@tanstack/vue-query";
import nprogress from "nprogress";
import { debounce } from "ts-debounce";

export const useNProgress = () => {
  const isFetching = useIsFetching();

  const updateStatus = () => {
    if (unref(isFetching)) {
      nprogress.start();
    } else {
      nprogress.done();
    }
  };

  const debouncedUpdateStatus = debounce(updateStatus, 300);

  watch(
    () => unref(isFetching),
    () => {
      if (nprogress.isStarted()) {
        debouncedUpdateStatus();
      } else {
        updateStatus();
      }
    }
  );
};
