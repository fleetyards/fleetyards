import { v4 as uuidv4 } from "uuid";
import AppLoadFailedHint from "@/shared/components/AppLoadFailedHint/index.vue";
import { MessageTypesEnum } from "@/shared/components/AppNotifications/types";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { chunkLoadFailures } from "@/shared/utils/ChunkReload";

const NOTICE_TAG = "chunk-load-failed";

export const useChunkFailureNotice = () => {
  const notificationsStore = useNotificationsStore();

  // Once per failure rather than once per document: the notice can be dismissed
  // with a tap, and a later failure on the same page still needs explaining.
  watch(
    chunkLoadFailures,
    (failures) => {
      if (!failures) {
        return;
      }

      notificationsStore.hideTagged((tag) => tag === NOTICE_TAG);

      notificationsStore.addMessage({
        id: uuidv4(),
        type: MessageTypesEnum.ALERT,
        visible: true,
        persist: true,
        timeout: false,
        tag: NOTICE_TAG,
        // Not a lazy import: it is shown because loading chunks has failed.
        component: () => Promise.resolve(AppLoadFailedHint),
      });
    },
    { immediate: true },
  );
};
