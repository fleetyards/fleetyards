import { v4 as uuidv4 } from "uuid";
import AppLoadFailedHint from "@/shared/components/AppLoadFailedHint/index.vue";
import { MessageTypesEnum } from "@/shared/components/AppNotifications/types";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { chunkLoadFailed } from "@/shared/utils/ChunkReload";

export const useChunkFailureNotice = () => {
  const notificationsStore = useNotificationsStore();

  watch(
    chunkLoadFailed,
    (failed) => {
      if (!failed) {
        return;
      }

      notificationsStore.addMessage({
        id: uuidv4(),
        type: MessageTypesEnum.ALERT,
        visible: true,
        persist: true,
        timeout: false,
        tag: "chunk-load-failed",
        // Not a lazy import: it is shown because loading chunks has failed.
        component: () => Promise.resolve(AppLoadFailedHint),
      });
    },
    { immediate: true },
  );
};
