import { usePrefetch } from "@/shared/composables/usePrefetch";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { type AppNotification } from "@/shared/components/AppNotifications/types";

export const useFlashNotifications = () => {
  const { fetchData } = usePrefetch();
  const { displayMessage } = useAppNotifications();

  onMounted(() => {
    const prefetchNotifications = fetchData<AppNotification[]>("notifications");

    if (prefetchNotifications) {
      prefetchNotifications.forEach((notification) => {
        displayMessage(notification);
      });
    }
  });
};
