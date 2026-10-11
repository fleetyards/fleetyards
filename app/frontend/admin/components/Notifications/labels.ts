import type { NotificationLabels } from "@/shared/components/Notifications/types";

// Spelled out rather than built from the scope, so a search for a key finds the
// code that reads it and a locale clean-up cannot take it for unused.
export const NOTIFICATION_LABELS: NotificationLabels = {
  select: "actions.adminNotifications.select",
  unread: "actions.adminNotifications.unread",
  archive: "actions.adminNotifications.archive",
  unarchive: "actions.adminNotifications.unarchive",
  noBody: "labels.adminNotifications.noBody",
  selectPrompt: "labels.adminNotifications.selectPrompt",
};
