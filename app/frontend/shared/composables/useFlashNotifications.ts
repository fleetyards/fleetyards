import { usePrefetch } from "@/shared/composables/usePrefetch";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type AppNotification,
  MessageTypesEnum,
} from "@/shared/components/AppNotifications/types";

const FLASH_TIMEOUTS: Partial<Record<MessageTypesEnum, number>> = {
  [MessageTypesEnum.ALERT]: 10000,
  [MessageTypesEnum.WARNING]: 10000,
};

export const useFlashNotifications = () => {
  const { fetchData } = usePrefetch();
  const { displayMessage } = useAppNotifications();

  onMounted(() => {
    const prefetchNotifications = fetchData<AppNotification[]>("notifications");

    if (prefetchNotifications) {
      prefetchNotifications.forEach((notification) => {
        const timeout = FLASH_TIMEOUTS[notification.type];
        displayMessage({ ...notification, ...(timeout ? { timeout } : {}) });
      });
    }
  });
};
