import { v4 as uuidv4 } from "uuid";
import { MessageTypesEnum } from "@/shared/components/AppNotifications/types";
import { useNotificationsStore } from "@/shared/stores/notifications";
import type { AppVersionAnnouncement } from "@/shared/stores/types";

const NOTICE_TAG = "app-update";

const RELEASES_URL = "https://github.com/fleetyards/fleetyards/releases/tag";

// Taken when the bundle is evaluated, which is when this tab's version was
// loaded: an announcement published after it is news to this tab.
const loadedAt = Date.now();

type AppUpdateSource = {
  version: string;
  codename: string;
  announcement?: AppVersionAnnouncement;
  isUpdateAvailable: boolean;
};

export const releaseUrl = (version: string) =>
  `${RELEASES_URL}/${version.startsWith("v") ? version : `v${version}`}`;

export const whatsNewUrl = (
  version: string,
  announcement?: AppVersionAnnouncement,
  since = loadedAt,
) => {
  if (!announcement || Date.parse(announcement.publishedAt) <= since) {
    return releaseUrl(version);
  }

  return announcement.link;
};

export const useAppUpdateNotice = (store: AppUpdateSource) => {
  const notificationsStore = useNotificationsStore();

  watch(
    () =>
      store.isUpdateAvailable
        ? {
            version: store.version,
            codename: store.codename,
            link: whatsNewUrl(store.version, store.announcement),
          }
        : undefined,
    (notice, previous) => {
      if (
        notice?.version === previous?.version &&
        notice?.link === previous?.link
      ) {
        return;
      }

      notificationsStore.hideTagged((tag) => tag === NOTICE_TAG);

      if (!notice) {
        return;
      }

      const notificationId = uuidv4();

      notificationsStore.addMessage({
        id: notificationId,
        type: MessageTypesEnum.INFO,
        visible: true,
        persist: true,
        timeout: false,
        tag: NOTICE_TAG,
        component: () => import("@/shared/components/AppUpdateHint/index.vue"),
        componentProps: {
          version: notice.version,
          codename: notice.codename,
          whatsNewUrl: notice.link,
        },
      });
    },
    { immediate: true },
  );
};
