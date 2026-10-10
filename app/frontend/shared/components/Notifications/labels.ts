import type { NotificationScope } from "@/shared/components/Notifications/types";

// Spelled out per scope rather than built from it, so a search for a key finds
// the code that reads it and a locale clean-up cannot take it for unused.
export const NOTIFICATION_LABELS = {
  notifications: {
    select: "actions.notifications.select",
    unread: "actions.notifications.unread",
    archive: "actions.notifications.archive",
    unarchive: "actions.notifications.unarchive",
    noBody: "labels.notifications.noBody",
    selectPrompt: "labels.notifications.selectPrompt",
  },
  adminNotifications: {
    select: "actions.adminNotifications.select",
    unread: "actions.adminNotifications.unread",
    archive: "actions.adminNotifications.archive",
    unarchive: "actions.adminNotifications.unarchive",
    noBody: "labels.adminNotifications.noBody",
    selectPrompt: "labels.adminNotifications.selectPrompt",
  },
} as const satisfies Record<NotificationScope, Record<string, string>>;
